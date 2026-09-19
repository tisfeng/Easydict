#!/usr/bin/env python3
"""Collect, plan, and apply Easydict release issue follow-up operations."""

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
from typing import Any, Callable, Iterable


SCHEMA_VERSION = 2
ASSOCIATIONS = {"fixes", "related", "rejected"}
RESOLUTIONS = {"resolved", "not_resolved", "not_applicable"}
OUTCOMES = {"fixed", "implemented", "not_applicable"}
LANGUAGES = {"en", "zh-Hans"}
CLOSE_AND_NOTIFY = "close_and_notify"
NOTIFY_ONLY = "notify_only"
UNRESOLVED_RELATED = "unresolved_related"
VISIBLE_CATEGORIES = (
    CLOSE_AND_NOTIFY,
    NOTIFY_ONLY,
    UNRESOLVED_RELATED,
)
SUMMARY_HEADINGS = {
    CLOSE_AND_NOTIFY: "关闭 issue 并已通知",
    NOTIFY_ONLY: "仅发通知",
    UNRESOLVED_RELATED: "未关闭的相关 issue",
}
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
LINKED_ISSUES_HEADING_PATTERN = re.compile(
    r"^##(?!#)[ \t]+"
    r"(?:关联[ \t]*Issues?|Linked[ \t]+Issues?)"
    r"(?:[ \t]*/[ \t]*(?:关联[ \t]*Issues?|Linked[ \t]+Issues?))?"
    r"[ \t]*$",
    re.IGNORECASE | re.MULTILINE,
)
SECOND_LEVEL_HEADING_PATTERN = re.compile(
    r"^##(?!#)[ \t]+.*$",
    re.MULTILINE,
)


class ReleaseIssueError(RuntimeError):
    """Raised when issue follow-up data is incomplete or unsafe."""


IssueLoader = Callable[[str, int], dict[str, Any] | None]


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
    for key in ("source_sha256", "decision_sha256", "plan_sha256"):
        source.pop(key, None)
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


def linked_issue_ranges(text: str) -> list[tuple[int, int]]:
    ranges: list[tuple[int, int]] = []
    for heading in LINKED_ISSUES_HEADING_PATTERN.finditer(text):
        next_heading = SECOND_LEVEL_HEADING_PATTERN.search(text, heading.end())
        ranges.append(
            (
                heading.end(),
                next_heading.start() if next_heading is not None else len(text),
            )
        )
    return ranges


def extract_text_references(
    text: str,
    repository: str,
    source: str,
) -> list[dict[str, Any]]:
    references: list[dict[str, Any]] = []
    occupied: list[tuple[int, int]] = []
    explicit_ranges = linked_issue_ranges(text) if source == "pr_body" else []

    def append_reference(
        repo: str,
        number: int,
        match: re.Match[str],
        kind: str,
    ) -> None:
        occupied.append(match.span())
        if not repository_matches(repo, repository):
            return
        if any(start <= match.start() < end for start, end in explicit_ranges):
            kind = "linked_issue"
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
    }


def release_pr_numbers(content: dict[str, Any]) -> list[int]:
    entries = content.get("entries")
    if not isinstance(entries, list):
        raise ReleaseIssueError("release content has no entries")
    numbers: list[int] = []
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
    issue_loader: IssueLoader = fetch_issue,
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


def validate_evidence(
    evidence: Any,
    context: str,
    *,
    required: bool,
) -> list[dict[str, str]]:
    if not isinstance(evidence, list):
        raise ReleaseIssueError(f"{context} evidence must be an array")
    if required and not evidence:
        raise ReleaseIssueError(f"{context} needs explicit evidence")
    normalized: list[dict[str, str]] = []
    for item in evidence:
        if not isinstance(item, dict):
            raise ReleaseIssueError(f"{context} evidence must be objects")
        url = item.get("url")
        summary = item.get("summary")
        if (
            not isinstance(url, str)
            or not url.startswith("https://github.com/")
            or not isinstance(summary, str)
            or not summary.strip()
        ):
            raise ReleaseIssueError(
                f"{context} evidence needs a GitHub URL and summary"
            )
        normalized.append({"url": url, "summary": summary.strip()})
    return normalized


def validate_decisions(
    candidates: dict[str, Any],
    decisions: dict[str, Any],
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

        allowed_prs = set(candidate_map[issue_number].get("source_prs") or [])
        source_prs = decision.get("source_prs")
        if not isinstance(source_prs, list) or set(source_prs) != allowed_prs:
            raise ReleaseIssueError(f"invalid source_prs for issue #{issue_number}")

        associations = decision.get("associations")
        if not isinstance(associations, list):
            raise ReleaseIssueError(f"issue #{issue_number} needs associations")
        association_map: dict[int, dict[str, Any]] = {}
        for association in associations:
            if not isinstance(association, dict):
                raise ReleaseIssueError(
                    f"issue #{issue_number} association must be an object"
                )
            pr_number = association.get("pr_number")
            relationship = association.get("relationship")
            if not isinstance(pr_number, int) or pr_number not in allowed_prs:
                raise ReleaseIssueError(
                    f"issue #{issue_number} association contains an unknown PR"
                )
            if pr_number in association_map:
                raise ReleaseIssueError(
                    f"issue #{issue_number} has duplicate PR association #{pr_number}"
                )
            if relationship not in ASSOCIATIONS:
                raise ReleaseIssueError(
                    f"issue #{issue_number} has an invalid PR relationship"
                )
            validate_evidence(
                association.get("evidence"),
                f"issue #{issue_number} PR #{pr_number}",
                required=True,
            )
            association_map[pr_number] = association
        if set(association_map) != allowed_prs:
            raise ReleaseIssueError(
                f"issue #{issue_number} associations must cover every source PR"
            )

        fixing_prs = [
            number
            for number, association in association_map.items()
            if association.get("relationship") == "fixes"
        ]
        resolution = decision.get("resolution")
        outcome = decision.get("outcome")
        language = decision.get("language")
        if resolution not in RESOLUTIONS or outcome not in OUTCOMES:
            raise ReleaseIssueError(
                f"issue #{issue_number} has an invalid resolution/outcome"
            )
        if language not in LANGUAGES:
            raise ReleaseIssueError(f"issue #{issue_number} has an invalid language")

        negative_evidence = validate_evidence(
            decision.get("negative_evidence"),
            f"issue #{issue_number} negative",
            required=resolution == "not_resolved",
        )
        if fixing_prs:
            if resolution not in {"resolved", "not_resolved"}:
                raise ReleaseIssueError(
                    f"issue #{issue_number} fixing PRs require a resolution"
                )
            if outcome not in {"fixed", "implemented"}:
                raise ReleaseIssueError(
                    f"issue #{issue_number} fixing PRs require an outcome"
                )
            if resolution == "resolved" and negative_evidence:
                raise ReleaseIssueError(
                    f"issue #{issue_number} cannot be resolved with negative evidence"
                )
        else:
            if resolution != "not_applicable" or outcome != "not_applicable":
                raise ReleaseIssueError(
                    f"issue #{issue_number} without fixing PRs must be not_applicable"
                )
            if negative_evidence:
                raise ReleaseIssueError(
                    f"issue #{issue_number} without fixing PRs cannot use negative evidence"
                )

        reason = decision.get("reason")
        if not isinstance(reason, str) or not reason.strip():
            raise ReleaseIssueError(f"issue #{issue_number} needs a reason")
        decision_map[issue_number] = decision

    if set(decision_map) != set(candidate_map):
        missing = sorted(set(candidate_map) - set(decision_map))
        extra = sorted(set(decision_map) - set(candidate_map))
        raise ReleaseIssueError(
            f"decisions must cover every candidate; missing={missing}, extra={extra}"
        )
    return decision_map


def validate_command(args: argparse.Namespace) -> None:
    candidates = read_json(args.candidates)
    decisions = read_json(args.decisions)
    decision_map = validate_decisions(candidates, decisions)
    counts = {relationship: 0 for relationship in ASSOCIATIONS}
    for decision in decision_map.values():
        for association in decision["associations"]:
            counts[association["relationship"]] += 1
    print(json.dumps({"valid": True, "issues": len(decision_map), **counts}))


def load_published_release(
    repository: str,
    version: str,
    input_json: Path | None = None,
) -> dict[str, Any]:
    release = (
        read_json(input_json)
        if input_json is not None
        else run_json(
            [
                "gh",
                "release",
                "view",
                version,
                "--repo",
                repository,
                "--json",
                "isDraft,isPrerelease,tagName,url,name",
            ]
        )
    )
    if release.get("tagName") != version or release.get("isDraft") is not False:
        raise ReleaseIssueError("release is not published for the requested version")
    if not isinstance(release.get("isPrerelease"), bool):
        raise ReleaseIssueError("release prerelease state is missing")
    if not isinstance(release.get("url"), str):
        raise ReleaseIssueError("published release URL is missing")
    return {
        "tag_name": version,
        "url": release["url"],
        "name": release.get("name"),
        "channel": "beta" if release["isPrerelease"] else "stable",
    }


def marker_for(version: str) -> str:
    return f"<!-- easydict-release-notification:{version} -->"


def find_marker_comment(
    comments: list[dict[str, Any]],
    marker: str,
) -> dict[str, Any] | None:
    for comment in comments:
        if marker in (comment.get("body") or ""):
            return comment
    return None


def release_comment(
    version: str,
    channel: str,
    release_url: str,
    language: str,
    outcome: str,
) -> str:
    marker = marker_for(version)
    if language == "zh-Hans":
        opening = (
            f"该问题已在 Easydict {version} 中修复。"
            if outcome == "fixed"
            else f"该功能已在 Easydict {version} 中实现。"
        )
        if channel == "beta":
            opening = opening.replace(f"{version}", f"{version} Beta 版本")
            instruction = (
                "请更新至最新版本。若要接收 Beta 更新，请前往 Easydict 设置 → 通用，"
                "开启“包括 Beta 版本”。"
            )
        else:
            instruction = "请更新至最新版本。"
    else:
        verb = "fixed" if outcome == "fixed" else "implemented"
        suffix = " beta" if channel == "beta" else ""
        opening = f"This issue has been {verb} in Easydict {version}{suffix}."
        if channel == "beta":
            instruction = (
                "Please update to the latest version. To receive beta updates, open "
                "Easydict Settings → General and enable “Include Beta versions”."
            )
        else:
            instruction = "Please update to the latest version."
    return f"{opening}\n\n{instruction}\n\n{release_url}\n\n{marker}"


def pr_links(
    decision: dict[str, Any],
    pr_map: dict[int, dict[str, Any]],
) -> list[dict[str, Any]]:
    links: list[dict[str, Any]] = []
    for association in decision["associations"]:
        if association["relationship"] == "rejected":
            continue
        number = association["pr_number"]
        pr = pr_map[number]
        links.append(
            {
                "number": number,
                "url": pr.get("url"),
                "title": pr.get("title"),
                "relationship": association["relationship"],
            }
        )
    return links


def build_plan(
    candidates: dict[str, Any],
    decisions: dict[str, Any],
    release: dict[str, Any],
    issue_loader: IssueLoader | None = None,
) -> dict[str, Any]:
    if issue_loader is None:
        issue_loader = fetch_issue
    decision_map = validate_decisions(candidates, decisions)
    repository = candidates.get("repository")
    version = candidates.get("version")
    if not isinstance(repository, str) or not isinstance(version, str):
        raise ReleaseIssueError("candidate repository/version is missing")
    pr_map = {
        pr.get("number"): pr
        for pr in candidates.get("prs") or []
        if isinstance(pr, dict) and isinstance(pr.get("number"), int)
    }
    items: list[dict[str, Any]] = []
    audit: list[dict[str, Any]] = []
    marker = marker_for(version)

    for issue_number in sorted(decision_map):
        decision = decision_map[issue_number]
        issue = issue_loader(repository, issue_number)
        if issue is None:
            raise ReleaseIssueError(f"issue #{issue_number} resolved to a pull request")
        associations = decision["associations"]
        fixing = [item for item in associations if item["relationship"] == "fixes"]
        related = [item for item in associations if item["relationship"] == "related"]
        rejected = [item for item in associations if item["relationship"] == "rejected"]
        for association in rejected:
            pr_number = association["pr_number"]
            audit.append(
                {
                    "issue_number": issue_number,
                    "issue_url": issue.get("url"),
                    "pr_number": pr_number,
                    "pr_url": pr_map[pr_number].get("url"),
                    "relationship": "rejected",
                    "evidence": association["evidence"],
                }
            )

        if not fixing and not related:
            continue
        resolved = bool(fixing) and decision["resolution"] == "resolved"
        state = str(issue.get("state") or "").lower()
        if state not in {"open", "closed"}:
            raise ReleaseIssueError(f"issue #{issue_number} has an invalid state")
        if resolved:
            category = CLOSE_AND_NOTIFY if state == "open" else NOTIFY_ONLY
        else:
            category = UNRESOLVED_RELATED
        item = {
            "issue_number": issue_number,
            "issue_title": issue.get("title"),
            "issue_url": issue.get("url"),
            "initial_state": state,
            "category": category,
            "resolution": decision["resolution"],
            "outcome": decision["outcome"],
            "language": decision["language"],
            "reason": decision["reason"].strip(),
            "prs": pr_links(decision, pr_map),
            "comment_needed": resolved
            and find_marker_comment(issue.get("comments") or [], marker) is None,
            "close_needed": resolved and state == "open",
        }
        items.append(item)

    plan: dict[str, Any] = {
        "schema_version": SCHEMA_VERSION,
        "repository": repository,
        "version": version,
        "channel": release["channel"],
        "release": release,
        "generated_at": now_iso8601(),
        "source_sha256": candidates["source_sha256"],
        "decision_sha256": stable_hash(decisions),
        "executed": False,
        "items": items,
        "audit": audit,
    }
    plan["plan_sha256"] = stable_hash(plan)
    return plan


def markdown_prs(prs: list[dict[str, Any]]) -> str:
    return "、".join(
        f"[PR #{pr['number']}]({pr['url']})"
        for pr in prs
        if isinstance(pr.get("url"), str)
    )


def render_summary(plan: dict[str, Any]) -> str:
    grouped = {
        category: [
            item
            for item in plan.get("items") or []
            if item.get("category") == category
        ]
        for category in VISIBLE_CATEGORIES
    }
    lines: list[str] = []
    executed = plan.get("executed") is True
    version = plan.get("version")
    for category in VISIBLE_CATEGORIES:
        lines.append(f"## {SUMMARY_HEADINGS[category]}")
        lines.append("")
        items = grouped[category]
        if not items:
            lines.append("- 无")
        for item in items:
            issue = f"[#{item['issue_number']}]({item['issue_url']})"
            prs = markdown_prs(item["prs"])
            if category == CLOSE_AND_NOTIFY:
                action = (
                    "已关闭并完成版本通知"
                    if executed
                    else f"计划关闭并发布 {version} 版本通知"
                )
            elif category == NOTIFY_ONLY:
                result = item.get("result") or {}
                if executed and result.get("comment") == "already_present":
                    action = "已有版本通知，无需重复评论"
                else:
                    action = (
                        "已发布版本通知"
                        if executed
                        else f"计划发布 {version} 版本通知"
                    )
            else:
                action = "未执行关闭"
            lines.append(f"- {issue} ← {prs}：{action}。{item['reason']}")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def write_plan_outputs(plan_path: Path, summary_path: Path, plan: dict[str, Any]) -> None:
    atomic_write_json(plan_path, plan)
    atomic_write_text(summary_path, render_summary(plan))


def plan_counts(plan: dict[str, Any]) -> dict[str, int]:
    return {
        category: sum(
            item.get("category") == category for item in plan.get("items") or []
        )
        for category in VISIBLE_CATEGORIES
    }


def prepare_plan(args: argparse.Namespace) -> tuple[dict[str, Any], dict[str, Any]]:
    candidates = read_json(args.candidates)
    decisions = read_json(args.decisions)
    if candidates.get("repository") != args.repo or candidates.get("version") != args.version:
        raise ReleaseIssueError("candidate source does not match repository/version")
    release = load_published_release(args.repo, args.version, args.release_json)
    if args.channel is not None and args.channel != release["channel"]:
        raise ReleaseIssueError("requested channel does not match the published Release")
    plan = build_plan(candidates, decisions, release)
    return plan, decisions


def plan_command(args: argparse.Namespace) -> None:
    plan, _ = prepare_plan(args)
    write_plan_outputs(args.plan, args.summary, plan)
    print(
        json.dumps(
            {
                "plan": str(args.plan),
                "summary": str(args.summary),
                "channel": plan["channel"],
                "counts": plan_counts(plan),
                "execute": False,
            },
            ensure_ascii=False,
            indent=2,
        )
    )


def load_action_state(path: Path, repository: str, version: str) -> dict[str, Any]:
    if not path.exists():
        return {
            "schema_version": SCHEMA_VERSION,
            "repository": repository,
            "version": version,
            "issues": {},
        }
    state = read_json(path)
    if state.get("schema_version") != SCHEMA_VERSION:
        raise ReleaseIssueError("unsupported action state schema version")
    if state.get("repository") != repository or state.get("version") != version:
        raise ReleaseIssueError("action state belongs to another release")
    if not isinstance(state.get("issues"), dict):
        raise ReleaseIssueError("action state has invalid issue data")
    return state


def apply_command(args: argparse.Namespace) -> None:
    plan, decisions = prepare_plan(args)
    write_plan_outputs(args.plan, args.summary, plan)
    if not args.execute:
        print(
            json.dumps(
                {
                    "plan": str(args.plan),
                    "summary": str(args.summary),
                    "channel": plan["channel"],
                    "counts": plan_counts(plan),
                    "execute": False,
                },
                ensure_ascii=False,
                indent=2,
            )
        )
        return

    decision_map = validate_decisions(read_json(args.candidates), decisions)
    action_state = load_action_state(args.state, args.repo, args.version)
    marker = marker_for(args.version)
    for item in plan["items"]:
        issue_number = item["issue_number"]
        if item["resolution"] != "resolved":
            item["result"] = {"comment": "not_applicable", "close": "not_applicable"}
            continue
        issue = fetch_issue(args.repo, issue_number)
        if issue is None:
            raise ReleaseIssueError(f"issue #{issue_number} resolved to a pull request")
        issue_state = str(issue.get("state") or "").lower()
        if issue_state not in {"open", "closed"}:
            raise ReleaseIssueError(f"issue #{issue_number} has an invalid state")
        marker_comment = find_marker_comment(issue.get("comments") or [], marker)
        comment_needed = marker_comment is None
        close_needed = issue_state == "open"
        status = action_state["issues"].setdefault(str(issue_number), {})
        result = {
            "comment": "created" if comment_needed else "already_present",
            "close": "closed" if close_needed else "already_closed",
        }
        item["category"] = CLOSE_AND_NOTIFY if close_needed else NOTIFY_ONLY
        item["comment_needed"] = comment_needed
        item["close_needed"] = close_needed

        if comment_needed:
            decision = decision_map[issue_number]
            comment = release_comment(
                args.version,
                plan["channel"],
                plan["release"]["url"],
                decision["language"],
                decision["outcome"],
            )
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
            status["comment_already_present"] = True

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
        item["result"] = result

    plan["executed"] = True
    plan["executed_at"] = now_iso8601()
    plan["plan_sha256"] = stable_hash(plan)
    write_plan_outputs(args.plan, args.summary, plan)
    print(
        json.dumps(
            {
                "plan": str(args.plan),
                "summary": str(args.summary),
                "state": str(args.state),
                "channel": plan["channel"],
                "counts": plan_counts(plan),
                "execute": True,
            },
            ensure_ascii=False,
            indent=2,
        )
    )


def add_plan_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--repo", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--channel", choices=("beta", "stable"))
    parser.add_argument("--candidates", type=Path, required=True)
    parser.add_argument("--decisions", type=Path, required=True)
    parser.add_argument("--plan", type=Path, required=True)
    parser.add_argument("--summary", type=Path, required=True)
    parser.add_argument("--release-json", type=Path)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    collect = subparsers.add_parser("collect", help="collect issue candidates")
    collect.add_argument("--repo", required=True)
    collect.add_argument("--version", required=True)
    collect.add_argument("--content", type=Path, required=True)
    collect.add_argument("--output", type=Path, required=True)
    collect.set_defaults(handler=collect_command)

    validate = subparsers.add_parser("validate", help="validate issue decisions")
    validate.add_argument("--candidates", type=Path, required=True)
    validate.add_argument("--decisions", type=Path, required=True)
    validate.set_defaults(handler=validate_command)

    plan = subparsers.add_parser("plan", help="render a read-only action plan")
    add_plan_arguments(plan)
    plan.set_defaults(handler=plan_command)

    apply = subparsers.add_parser("apply", help="refresh and execute issue actions")
    add_plan_arguments(apply)
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
