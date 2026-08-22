#!/usr/bin/env python3
"""Collect weak issue references and apply validated release follow-ups."""

from __future__ import annotations

import argparse
from copy import deepcopy
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from typing import Any, Iterable


SCHEMA_VERSION = 1
RELATIONSHIPS = {"target", "related", "uncertain"}
COMPLETIONS = {"resolved", "implemented", "partial", "unverified"}
DECISIONS = {"notify_on_release", "skip"}
LANGUAGES = {"en", "zh-Hans"}
ISSUE_URL_PATTERN = re.compile(
    r"https://github\.com/(?P<repo>[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)"
    r"/issues/(?P<number>\d+)(?:#issuecomment-\d+)?",
    re.IGNORECASE,
)
REPO_REFERENCE_PATTERN = re.compile(
    r"(?<![A-Za-z0-9_.-])"
    r"(?P<repo>[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)#(?P<number>\d+)\b"
)
LOCAL_REFERENCE_PATTERN = re.compile(r"(?<![A-Za-z0-9_./-])#(?P<number>\d+)\b")


class ReleaseIssueError(RuntimeError):
    """Raised when release issue data is incomplete or unsafe."""


def now_iso8601() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def run_command(command: list[str]) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        command,
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise ReleaseIssueError(f"command failed: {' '.join(command)}\n{detail}")
    return result


def run_json(command: list[str]) -> dict[str, Any]:
    result = run_command(command)
    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise ReleaseIssueError("command did not return valid JSON") from error
    if not isinstance(payload, dict):
        raise ReleaseIssueError("expected a JSON object")
    return payload


def run_json_items(command: list[str]) -> list[dict[str, Any]]:
    result = run_command(command)
    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise ReleaseIssueError("command did not return valid JSON") from error
    if not isinstance(payload, list):
        raise ReleaseIssueError("expected a JSON array")
    if payload and all(isinstance(item, list) for item in payload):
        flattened: list[Any] = []
        for page in payload:
            flattened.extend(page)
        payload = flattened
    if not all(isinstance(item, dict) for item in payload):
        raise ReleaseIssueError("expected an array of JSON objects")
    return payload


def read_json(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ReleaseIssueError(f"cannot read JSON file: {path}") from error
    if not isinstance(payload, dict):
        raise ReleaseIssueError(f"expected a JSON object: {path}")
    return payload


def atomic_write_text(path: Path, contents: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.",
        dir=path.parent,
        text=True,
    )
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.write(contents)
        os.replace(temporary_name, path)
    except Exception:
        try:
            os.unlink(temporary_name)
        except FileNotFoundError:
            pass
        raise


def atomic_write_json(path: Path, payload: dict[str, Any]) -> None:
    atomic_write_text(
        path,
        json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
    )


def stable_hash(payload: dict[str, Any]) -> str:
    source = deepcopy(payload)
    source.pop("source_sha256", None)
    encoded = json.dumps(
        source,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def repository_matches(left: str, right: str) -> bool:
    return left.casefold() == right.casefold()


def line_context(text: str, offset: int) -> str:
    line_start = text.rfind("\n", 0, offset) + 1
    line_end = text.find("\n", offset)
    if line_end == -1:
        line_end = len(text)
    return text[line_start:line_end].strip()[:500]


def extract_text_references(
    text: str,
    repository: str,
    source: str,
) -> list[dict[str, Any]]:
    references: list[dict[str, Any]] = []
    occupied: list[tuple[int, int]] = []

    def append_reference(
        repo: str,
        number: int,
        match: re.Match[str],
        kind: str,
    ) -> None:
        occupied.append(match.span())
        if not repository_matches(repo, repository):
            return
        references.append(
            {
                "issue_number": number,
                "source": source,
                "kind": kind,
                "reference": match.group(0),
                "context": line_context(text, match.start()),
            }
        )

    for match in ISSUE_URL_PATTERN.finditer(text):
        append_reference(
            match.group("repo"),
            int(match.group("number")),
            match,
            "issue_url",
        )
    for match in REPO_REFERENCE_PATTERN.finditer(text):
        if any(start <= match.start() < end for start, end in occupied):
            continue
        append_reference(
            match.group("repo"),
            int(match.group("number")),
            match,
            "repository_number",
        )
    for match in LOCAL_REFERENCE_PATTERN.finditer(text):
        if any(start <= match.start() < end for start, end in occupied):
            continue
        append_reference(
            repository,
            int(match.group("number")),
            match,
            "local_number",
        )
    return references


def deduplicate_references(
    references: Iterable[dict[str, Any]],
) -> list[dict[str, Any]]:
    result: list[dict[str, Any]] = []
    seen: set[tuple[Any, ...]] = set()
    for reference in references:
        key = (
            reference.get("pr_number"),
            reference.get("issue_number"),
            reference.get("source"),
            reference.get("kind"),
            reference.get("reference"),
            reference.get("context"),
        )
        if key in seen:
            continue
        seen.add(key)
        result.append(reference)
    return result


def fetch_pr(repository: str, number: int) -> dict[str, Any]:
    return run_json(
        [
            "gh",
            "pr",
            "view",
            str(number),
            "--repo",
            repository,
            "--json",
            "number,title,body,mergedAt,url,closingIssuesReferences,commits,files",
        ]
    )


def pr_references(repository: str, pr: dict[str, Any]) -> list[dict[str, Any]]:
    references: list[dict[str, Any]] = []
    for closing in pr.get("closingIssuesReferences") or []:
        if not isinstance(closing, dict):
            continue
        closing_repository = closing.get("repository") or {}
        owner = closing_repository.get("owner") or {}
        full_name = f"{owner.get('login')}/{closing_repository.get('name')}"
        if not repository_matches(full_name, repository):
            continue
        number = closing.get("number")
        if isinstance(number, int):
            references.append(
                {
                    "issue_number": number,
                    "source": "github_closing_reference",
                    "kind": "closing_reference",
                    "reference": closing.get("url"),
                    "context": "GitHub closingIssuesReferences",
                }
            )
    body = pr.get("body") or ""
    if isinstance(body, str):
        references.extend(extract_text_references(body, repository, "pr_body"))
    for commit in pr.get("commits") or []:
        if not isinstance(commit, dict):
            continue
        message = "\n".join(
            part
            for part in (commit.get("messageHeadline"), commit.get("messageBody"))
            if isinstance(part, str) and part
        )
        references.extend(
            extract_text_references(message, repository, "commit_message")
        )
    return deduplicate_references(references)


def fetch_issue(repository: str, number: int) -> dict[str, Any] | None:
    issue = run_json(["gh", "api", f"repos/{repository}/issues/{number}"])
    if "pull_request" in issue:
        return None
    comments = run_json_items(
        [
            "gh",
            "api",
            "--paginate",
            "--slurp",
            f"repos/{repository}/issues/{number}/comments?per_page=100",
        ]
    )
    timeline = run_json_items(
        [
            "gh",
            "api",
            "--paginate",
            "--slurp",
            "-H",
            "Accept: application/vnd.github+json",
            f"repos/{repository}/issues/{number}/timeline?per_page=100",
        ]
    )
    return {
        "number": number,
        "title": issue.get("title"),
        "body": issue.get("body") or "",
        "state": issue.get("state"),
        "state_reason": issue.get("state_reason"),
        "url": issue.get("html_url"),
        "created_at": issue.get("created_at"),
        "updated_at": issue.get("updated_at"),
        "closed_at": issue.get("closed_at"),
        "labels": [
            label.get("name")
            for label in issue.get("labels") or []
            if isinstance(label, dict) and isinstance(label.get("name"), str)
        ],
        "comments": [
            {
                "author": (comment.get("user") or {}).get("login"),
                "body": comment.get("body") or "",
                "created_at": comment.get("created_at"),
                "updated_at": comment.get("updated_at"),
                "url": comment.get("html_url"),
            }
            for comment in comments
        ],
        "reopened_events": [
            {
                "created_at": event.get("created_at"),
                "actor": (event.get("actor") or {}).get("login"),
            }
            for event in timeline
            if event.get("event") == "reopened"
        ],
    }


def release_pr_numbers(content: dict[str, Any]) -> list[int]:
    entries = content.get("entries")
    if not isinstance(entries, list):
        raise ReleaseIssueError("release content has no entries")
    numbers = []
    for entry in entries:
        number = entry.get("pr_number") if isinstance(entry, dict) else None
        if not isinstance(number, int):
            raise ReleaseIssueError("release content contains an invalid PR number")
        numbers.append(number)
    if len(numbers) != len(set(numbers)):
        raise ReleaseIssueError("release content contains duplicate PR numbers")
    return numbers


def build_candidates(
    repository: str,
    version: str,
    prs: list[dict[str, Any]],
    issue_loader: Any = fetch_issue,
) -> dict[str, Any]:
    candidates: dict[int, dict[str, Any]] = {}
    normalized_prs: list[dict[str, Any]] = []
    for pr in prs:
        number = pr.get("number")
        if not isinstance(number, int):
            raise ReleaseIssueError("PR payload is missing its number")
        if not isinstance(pr.get("mergedAt"), str):
            raise ReleaseIssueError(f"release PR #{number} is not merged")
        references = pr_references(repository, pr)
        normalized_prs.append(
            {
                "number": number,
                "title": pr.get("title"),
                "body": pr.get("body") or "",
                "merged_at": pr.get("mergedAt"),
                "url": pr.get("url"),
                "commits": pr.get("commits") or [],
                "files": pr.get("files") or [],
                "references": references,
            }
        )
        for reference in references:
            issue_number = reference["issue_number"]
            candidate = candidates.setdefault(
                issue_number,
                {
                    "issue_number": issue_number,
                    "source_prs": [],
                    "references": [],
                },
            )
            if number not in candidate["source_prs"]:
                candidate["source_prs"].append(number)
            candidate["references"].append({**reference, "pr_number": number})

    resolved_candidates: list[dict[str, Any]] = []
    for issue_number in sorted(candidates):
        issue = issue_loader(repository, issue_number)
        if issue is None:
            continue
        candidate = candidates[issue_number]
        candidate["references"] = deduplicate_references(candidate["references"])
        candidate["issue"] = issue
        resolved_candidates.append(candidate)

    payload: dict[str, Any] = {
        "schema_version": SCHEMA_VERSION,
        "repository": repository,
        "version": version,
        "generated_at": now_iso8601(),
        "prs": normalized_prs,
        "candidates": resolved_candidates,
    }
    payload["source_sha256"] = stable_hash(payload)
    return payload


def collect_command(args: argparse.Namespace) -> None:
    content = read_json(args.content)
    if content.get("repository") != args.repo or content.get("version") != args.version:
        raise ReleaseIssueError("release content does not match repository/version")
    if content.get("source_sha256") != stable_hash(content):
        raise ReleaseIssueError("release content failed its integrity check")
    prs = [fetch_pr(args.repo, number) for number in release_pr_numbers(content)]
    payload = build_candidates(args.repo, args.version, prs)
    atomic_write_json(args.output, payload)
    print(
        json.dumps(
            {
                "output": str(args.output),
                "prs": len(prs),
                "candidates": len(payload["candidates"]),
            }
        )
    )


def refresh_command(args: argparse.Namespace) -> None:
    source = read_json(args.candidates)
    if source.get("repository") != args.repo or source.get("version") != args.version:
        raise ReleaseIssueError("candidate source does not match repository/version")
    if source.get("source_sha256") != stable_hash(source):
        raise ReleaseIssueError("candidate source failed its integrity check")
    frozen_numbers = {
        candidate.get("issue_number")
        for candidate in source.get("candidates") or []
        if isinstance(candidate, dict)
    }
    prs = [
        fetch_pr(args.repo, pr["number"])
        for pr in source.get("prs") or []
        if isinstance(pr, dict) and isinstance(pr.get("number"), int)
    ]
    refreshed = build_candidates(args.repo, args.version, prs)
    refreshed["candidates"] = [
        candidate
        for candidate in refreshed["candidates"]
        if candidate.get("issue_number") in frozen_numbers
    ]
    refreshed["previous_source_sha256"] = source["source_sha256"]
    refreshed["source_sha256"] = stable_hash(refreshed)
    if {
        candidate.get("issue_number") for candidate in refreshed["candidates"]
    } != frozen_numbers:
        raise ReleaseIssueError("a frozen issue candidate is no longer resolvable")
    atomic_write_json(args.output, refreshed)
    print(json.dumps({"output": str(args.output), "candidates": len(frozen_numbers)}))


def validate_decisions(
    candidates: dict[str, Any],
    decisions: dict[str, Any],
    previous: dict[str, Any] | None = None,
) -> dict[int, dict[str, Any]]:
    if candidates.get("schema_version") != SCHEMA_VERSION:
        raise ReleaseIssueError("unsupported candidate schema version")
    if candidates.get("source_sha256") != stable_hash(candidates):
        raise ReleaseIssueError("candidate source failed its integrity check")
    if decisions.get("schema_version") != SCHEMA_VERSION:
        raise ReleaseIssueError("unsupported decision schema version")
    if decisions.get("source_sha256") != candidates.get("source_sha256"):
        raise ReleaseIssueError("decisions do not match the candidate snapshot")
    candidate_map = {
        candidate.get("issue_number"): candidate
        for candidate in candidates.get("candidates") or []
        if isinstance(candidate, dict)
    }
    decision_map: dict[int, dict[str, Any]] = {}
    for decision in decisions.get("decisions") or []:
        if not isinstance(decision, dict):
            raise ReleaseIssueError("decision must be an object")
        issue_number = decision.get("issue_number")
        if not isinstance(issue_number, int) or issue_number not in candidate_map:
            raise ReleaseIssueError(f"decision contains unknown issue: {issue_number}")
        if issue_number in decision_map:
            raise ReleaseIssueError(f"duplicate issue decision: #{issue_number}")
        relationship = decision.get("relationship")
        completion = decision.get("completion")
        action = decision.get("decision")
        language = decision.get("language")
        if relationship not in RELATIONSHIPS:
            raise ReleaseIssueError(f"invalid relationship for issue #{issue_number}")
        if completion not in COMPLETIONS:
            raise ReleaseIssueError(f"invalid completion for issue #{issue_number}")
        if action not in DECISIONS or language not in LANGUAGES:
            raise ReleaseIssueError(
                f"invalid action/language for issue #{issue_number}"
            )
        should_notify = relationship == "target" and completion in {
            "resolved",
            "implemented",
        }
        if (action == "notify_on_release") != should_notify:
            raise ReleaseIssueError(
                f"issue #{issue_number} decision violates the two-gate policy"
            )
        source_prs = decision.get("source_prs")
        allowed_prs = set(candidate_map[issue_number].get("source_prs") or [])
        if not isinstance(source_prs, list) or set(source_prs) != allowed_prs:
            raise ReleaseIssueError(f"invalid source_prs for issue #{issue_number}")
        positive_evidence = decision.get("positive_evidence")
        counter_evidence = decision.get("counter_evidence")
        reason = decision.get("reason")
        if not isinstance(positive_evidence, list) or not isinstance(
            counter_evidence, list
        ):
            raise ReleaseIssueError(
                f"evidence must be arrays for issue #{issue_number}"
            )
        if action == "notify_on_release" and not positive_evidence:
            raise ReleaseIssueError(f"issue #{issue_number} needs positive evidence")
        if not isinstance(reason, str) or not reason.strip():
            raise ReleaseIssueError(f"issue #{issue_number} needs a reason")
        decision_map[issue_number] = decision
    if set(decision_map) != set(candidate_map):
        missing = sorted(set(candidate_map) - set(decision_map))
        extra = sorted(set(decision_map) - set(candidate_map))
        raise ReleaseIssueError(
            f"decisions must cover every candidate; missing={missing}, extra={extra}"
        )

    if previous is not None:
        if previous.get("schema_version") != SCHEMA_VERSION:
            raise ReleaseIssueError("unsupported previous decision schema version")
        if previous.get("source_sha256") != candidates.get(
            "previous_source_sha256"
        ):
            raise ReleaseIssueError(
                "previous decisions do not match the frozen candidate snapshot"
            )
        previous_map = {
            item.get("issue_number"): item
            for item in previous.get("decisions") or []
            if isinstance(item, dict)
        }
        if set(previous_map) != set(decision_map):
            raise ReleaseIssueError("refreshed decisions changed the frozen issue set")
        for number, decision in decision_map.items():
            if (
                previous_map[number].get("decision") == "skip"
                and decision.get("decision") == "notify_on_release"
            ):
                raise ReleaseIssueError(
                    f"refreshed decision illegally promoted issue #{number}"
                )
    return decision_map


def validate_command(args: argparse.Namespace) -> None:
    candidates = read_json(args.candidates)
    decisions = read_json(args.decisions)
    previous = read_json(args.previous_decisions) if args.previous_decisions else None
    decision_map = validate_decisions(candidates, decisions, previous)
    print(
        json.dumps(
            {
                "valid": True,
                "notify": sum(
                    item["decision"] == "notify_on_release"
                    for item in decision_map.values()
                ),
                "skip": sum(
                    item["decision"] == "skip" for item in decision_map.values()
                ),
            }
        )
    )


def release_comment(
    version: str,
    channel: str,
    release_url: str,
    language: str,
    completion: str,
) -> str:
    marker = f"<!-- easydict-release-notification:{version} -->"
    if language == "zh-Hans":
        opening = (
            f"该问题已在 Easydict {version} 中修复。"
            if completion == "resolved"
            else f"该功能已在 Easydict {version} 中实现。"
        )
        if channel == "beta":
            opening = opening.replace(f"{version}", f"{version} Beta 版本")
            instruction = (
                "请更新至最新版本。若要接收 Beta 更新，"
                "请前往 Easydict 设置 → 通用，"
                "开启“包括 Beta 版本”。"
            )
        else:
            instruction = "请更新至最新版本。"
    else:
        outcome = "fixed" if completion == "resolved" else "implemented"
        suffix = " beta" if channel == "beta" else ""
        opening = f"This issue has been {outcome} in Easydict {version}{suffix}."
        if channel == "beta":
            instruction = (
                "Please update to the latest version. To receive beta updates, open "
                "Easydict Settings → General and enable “Include Beta versions”."
            )
        else:
            instruction = "Please update to the latest version."
    return f"{opening}\n\n{instruction}\n\n{release_url}\n\n{marker}"


def marker_for(version: str) -> str:
    return f"<!-- easydict-release-notification:{version} -->"


def load_action_state(path: Path, repository: str, version: str) -> dict[str, Any]:
    if not path.exists():
        return {
            "schema_version": SCHEMA_VERSION,
            "repository": repository,
            "version": version,
            "issues": {},
        }
    state = read_json(path)
    if state.get("repository") != repository or state.get("version") != version:
        raise ReleaseIssueError("action state belongs to another release")
    if not isinstance(state.get("issues"), dict):
        raise ReleaseIssueError("action state has invalid issue data")
    return state


def find_marker_comment(
    comments: list[dict[str, Any]],
    marker: str,
) -> dict[str, Any] | None:
    for comment in comments:
        if marker in (comment.get("body") or ""):
            return comment
    return None


def parse_github_timestamp(value: Any) -> datetime:
    if not isinstance(value, str) or not value:
        raise ReleaseIssueError("GitHub timestamp is missing")
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as error:
        raise ReleaseIssueError(f"invalid GitHub timestamp: {value}") from error


def was_reopened_after_marker(
    issue: dict[str, Any],
    marker_comment: dict[str, Any] | None,
) -> bool:
    if marker_comment is None:
        return False
    marker_time = parse_github_timestamp(marker_comment.get("created_at"))
    for event in issue.get("reopened_events") or []:
        if not isinstance(event, dict):
            continue
        if parse_github_timestamp(event.get("created_at")) > marker_time:
            return True
    return False


def apply_command(args: argparse.Namespace) -> None:
    candidates = read_json(args.candidates)
    decisions = read_json(args.decisions)
    previous = read_json(args.previous_decisions)
    if (
        candidates.get("repository") != args.repo
        or candidates.get("version") != args.version
    ):
        raise ReleaseIssueError("candidate source does not match repository/version")
    decision_map = validate_decisions(candidates, decisions, previous)
    release = run_json(
        [
            "gh",
            "release",
            "view",
            args.version,
            "--repo",
            args.repo,
            "--json",
            "isDraft,isPrerelease,tagName,url",
        ]
    )
    expected_prerelease = args.channel == "beta"
    if (
        release.get("tagName") != args.version
        or release.get("isDraft") is not False
        or release.get("isPrerelease") is not expected_prerelease
    ):
        raise ReleaseIssueError("release is not published in the expected channel")
    release_url = release.get("url")
    if not isinstance(release_url, str):
        raise ReleaseIssueError("published release URL is missing")

    action_state = load_action_state(args.state, args.repo, args.version)
    results: list[dict[str, Any]] = []
    for issue_number in sorted(decision_map):
        decision = decision_map[issue_number]
        if decision["decision"] == "skip":
            results.append(
                {
                    "issue": issue_number,
                    "action": "skip",
                    "reason": decision["reason"],
                }
            )
            continue
        issue = fetch_issue(args.repo, issue_number)
        if issue is None:
            raise ReleaseIssueError(f"issue #{issue_number} resolved to a pull request")
        issue_key = str(issue_number)
        status = action_state["issues"].setdefault(issue_key, {})
        marker = marker_for(args.version)
        marker_comment = find_marker_comment(issue["comments"], marker)
        issue_state = str(issue.get("state") or "").lower()

        reopened_after_notification = was_reopened_after_marker(
            issue,
            marker_comment,
        )
        if issue_state == "open" and (
            status.get("closed") is True or reopened_after_notification
        ):
            results.append(
                {
                    "issue": issue_number,
                    "action": "skip_reopened",
                    "reason": "issue reopened after a completed release notification",
                }
            )
            continue

        comment_needed = marker_comment is None
        close_needed = issue_state == "open"
        comment = release_comment(
            args.version,
            args.channel,
            release_url,
            decision["language"],
            decision["completion"],
        )
        result = {
            "issue": issue_number,
            "comment": "create" if comment_needed else "already_present",
            "close": "close" if close_needed else "already_closed",
            "execute": args.execute,
        }
        results.append(result)
        if not args.execute:
            continue

        if comment_needed:
            run_command(
                [
                    "gh",
                    "issue",
                    "comment",
                    str(issue_number),
                    "--repo",
                    args.repo,
                    "--body",
                    comment,
                ]
            )
            status["commented"] = True
            status["commented_at"] = now_iso8601()
            atomic_write_json(args.state, action_state)
        else:
            status["commented"] = True

        if close_needed:
            run_command(
                [
                    "gh",
                    "issue",
                    "close",
                    str(issue_number),
                    "--repo",
                    args.repo,
                    "--reason",
                    "completed",
                ]
            )
            status["closed"] = True
            status["closed_at"] = now_iso8601()
        else:
            status["already_closed"] = True
        atomic_write_json(args.state, action_state)

    print(json.dumps({"results": results}, ensure_ascii=False, indent=2))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    collect = subparsers.add_parser("collect", help="collect issue candidates")
    collect.add_argument("--repo", required=True)
    collect.add_argument("--version", required=True)
    collect.add_argument("--content", type=Path, required=True)
    collect.add_argument("--output", type=Path, required=True)
    collect.set_defaults(handler=collect_command)

    refresh = subparsers.add_parser("refresh", help="refresh frozen candidates")
    refresh.add_argument("--repo", required=True)
    refresh.add_argument("--version", required=True)
    refresh.add_argument("--candidates", type=Path, required=True)
    refresh.add_argument("--output", type=Path, required=True)
    refresh.set_defaults(handler=refresh_command)

    validate = subparsers.add_parser("validate", help="validate issue decisions")
    validate.add_argument("--candidates", type=Path, required=True)
    validate.add_argument("--decisions", type=Path, required=True)
    validate.add_argument("--previous-decisions", type=Path)
    validate.set_defaults(handler=validate_command)

    apply = subparsers.add_parser("apply", help="notify and close verified issues")
    apply.add_argument("--repo", required=True)
    apply.add_argument("--version", required=True)
    apply.add_argument("--channel", choices=("beta", "stable"), required=True)
    apply.add_argument("--candidates", type=Path, required=True)
    apply.add_argument("--decisions", type=Path, required=True)
    apply.add_argument("--previous-decisions", type=Path, required=True)
    apply.add_argument("--state", type=Path, required=True)
    apply.add_argument("--execute", action="store_true")
    apply.set_defaults(handler=apply_command)
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        args.handler(args)
    except (ReleaseIssueError, OSError, subprocess.SubprocessError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
