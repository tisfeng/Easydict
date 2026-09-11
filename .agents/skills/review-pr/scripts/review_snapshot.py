#!/usr/bin/env python3
"""Collect or refresh one compact, fingerprinted GitHub PR review snapshot."""

from __future__ import annotations

import argparse
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import time
from typing import Any, Callable


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import review_threads  # noqa: E402
import review_context  # noqa: E402
import snapshot_transport  # noqa: E402
from pr_identity import matches_pr_url, same_repository  # noqa: E402


PR_FIELDS = (
    "number,title,url,body,baseRefName,baseRefOid,headRefName,headRefOid,"
    "headRepository,headRepositoryOwner,isCrossRepository,isDraft,state,"
    "mergeable,mergeStateStatus,updatedAt,files,commits,"
    "closingIssuesReferences,comments,reviews"
)
CHECK_FIELDS = "bucket,link,name,state,workflow"
CHECK_EXIT_CODES = (0, 1, 8)
IDENTITY_FIELDS = ("number", "url", "headRefOid", "baseRefName", "baseRefOid")


class SnapshotError(RuntimeError):
    """A coherent review snapshot could not be collected."""


def canonical_fingerprint(value: Any) -> str:
    """Return a stable SHA-256 fingerprint for JSON-compatible content."""

    payload = json.dumps(
        value,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def section_fingerprints(pr, threads, checks):
    """Ignore transport order for sets, but retain chronological reply content."""
    thread_set = dict(threads, threads=sorted(threads["threads"], key=lambda item: item["id"]))
    check_set = dict(checks, items=sorted(checks["items"], key=canonical_fingerprint))
    return {"pr": canonical_fingerprint(review_context.fingerprint_content(pr)), "threads": canonical_fingerprint(thread_set),
            "checks": canonical_fingerprint(check_set)}


def run_json(
    arguments: list[str],
    *,
    allowed_exit_codes: tuple[int, ...] = (0,),
) -> tuple[Any, int]:
    """Run one bounded command and decode its JSON stdout."""

    try:
        result = subprocess.run(
            arguments,
            check=False,
            capture_output=True,
            text=True,
            timeout=60,
        )
    except (OSError, subprocess.SubprocessError) as error:
        raise SnapshotError(f"cannot run {arguments[0]}: {error}") from error
    if result.returncode not in allowed_exit_codes:
        detail = result.stderr.strip() or "no diagnostic"
        raise SnapshotError(
            f"{' '.join(arguments[:3])} failed with {result.returncode}: {detail}"
        )
    try:
        return json.loads(result.stdout), result.returncode
    except json.JSONDecodeError as error:
        detail = result.stderr.strip() or "stdout was not valid JSON"
        raise SnapshotError(
            f"{' '.join(arguments[:3])} did not return JSON: {detail}"
        ) from error


def collect_pr(repo: str, number: int) -> dict[str, Any]:
    """Collect the PR metadata needed for review and final reporting."""

    payload, _ = run_json(
        [
            "gh",
            "pr",
            "view",
            str(number),
            "--repo",
            repo,
            "--json",
            PR_FIELDS,
        ]
    )
    if not isinstance(payload, dict):
        raise SnapshotError("gh pr view returned a non-object payload")
    return payload


def collect_pr_head(repo: str, number: int) -> str:
    """Read the current PR head for a bounded cross-query consistency check."""

    payload, _ = run_json(
        [
            "gh",
            "pr",
            "view",
            str(number),
            "--repo",
            repo,
            "--json",
            "headRefOid",
        ]
    )
    if not isinstance(payload, dict) or not isinstance(
        payload.get("headRefOid"), str
    ):
        raise SnapshotError("gh pr view did not return headRefOid")
    return payload["headRefOid"]


def snapshot_identity(payload: Any, repo: str, number: int) -> dict[str, Any]:
    """Require a complete identity tied to the requested base repository and PR."""

    if not isinstance(payload, dict):
        raise SnapshotError("PR identity must be an object; collect again")
    if type(payload.get("number")) is not int or payload["number"] != number:
        raise SnapshotError("PR number does not match the request; collect again")
    for field in IDENTITY_FIELDS[1:]:
        if not isinstance(payload.get(field), str) or not payload[field].strip():
            raise SnapshotError(f"PR identity is missing {field}; collect again")
    if not matches_pr_url(payload["url"], repo, number):
        raise SnapshotError("PR URL does not match the requested repository and number; collect again")
    return {field: payload[field] for field in IDENTITY_FIELDS}


def collect_pr_identity(repo: str, number: int) -> dict[str, Any]:
    """Re-read the complete identity after every parallel collector has finished."""

    payload, _ = run_json([
        "gh", "pr", "view", str(number), "--repo", repo,
        "--json", ",".join(IDENTITY_FIELDS),
    ])
    return snapshot_identity(payload, repo, number)


def collect_checks(repo: str, number: int, expected_head: str) -> dict[str, Any]:
    """Collect check state and prove that the anchored PR head stayed stable."""

    payload, exit_code = run_json(
        [
            "gh",
            "pr",
            "checks",
            str(number),
            "--repo",
            repo,
            "--json",
            CHECK_FIELDS,
        ],
        allowed_exit_codes=CHECK_EXIT_CODES,
    )
    if not isinstance(payload, list):
        raise SnapshotError("gh pr checks returned a non-list payload")
    head_after = collect_pr_head(repo, number)
    if expected_head != head_after:
        raise SnapshotError("PR head changed while collecting checks; collect again")
    return {
        "headRefOid": head_after,
        "exit_code": exit_code,
        "items": payload,
    }


def collect_thread_snapshot(repo: str, number: int) -> dict[str, Any]:
    """Collect fully paginated threads and add per-thread fingerprints."""

    payload = review_threads.collect(repo, number)
    for thread in payload["threads"]:
        thread["fingerprint"] = review_threads.fingerprint(thread)
    return payload


def measured(function: Callable[[], Any]) -> tuple[Any, float]:
    """Run one collector and return its value and elapsed milliseconds."""

    started = time.monotonic()
    value = function()
    return value, round((time.monotonic() - started) * 1000, 3)


def summarize_threads(payload: dict[str, Any]) -> dict[str, int]:
    """Return compact thread counts without dropping the full initial evidence."""

    threads = payload["threads"]
    return {
        "total": len(threads),
        "open": sum(not item["isResolved"] for item in threads),
        "resolved": sum(item["isResolved"] for item in threads),
        "outdated": sum(item["isOutdated"] for item in threads),
    }


def summarize_checks(payload: dict[str, Any]) -> dict[str, Any]:
    """Return counts by GitHub check bucket and preserve the observed exit code."""

    buckets = Counter(str(item.get("bucket") or "unknown") for item in payload["items"])
    return {
        "total": len(payload["items"]),
        "exit_code": payload["exit_code"],
        "buckets": dict(sorted(buckets.items())),
    }


def collect_snapshot(repo: str, number: int, *, issue_refs=(), discussion_refs=()) -> dict[str, Any]:
    """Anchor the PR identity, then collect independent review facts in parallel."""

    started = time.monotonic()
    pr, pr_ms = measured(lambda: collect_pr(repo, number))
    identity_before = snapshot_identity(pr, repo, number)
    expected_head = identity_before["headRefOid"]
    with ThreadPoolExecutor(max_workers=3) as executor:
        futures = {
            "context": executor.submit(
                measured, lambda: review_context.collect(repo, pr, issue_refs, discussion_refs)
            ),
            "threads": executor.submit(
                measured, lambda: collect_thread_snapshot(repo, number)
            ),
            "checks": executor.submit(
                measured, lambda: collect_checks(repo, number, expected_head)
            ),
        }
        results = {name: future.result() for name, future in futures.items()}

    threads, threads_ms = results["threads"]
    checks, checks_ms = results["checks"]
    context, context_ms = results["context"]
    if pr.get("number") != number or threads.get("number") != number:
        raise SnapshotError("PR number changed during snapshot collection")
    if pr.get("headRefOid") != threads.get("headRefOid"):
        raise SnapshotError("PR head changed during snapshot collection; collect again")
    if pr.get("headRefOid") != checks.get("headRefOid"):
        raise SnapshotError("checks do not match the collected PR head; collect again")
    if not matches_pr_url(threads.get("url"), repo, number):
        raise SnapshotError("PR identity changed during snapshot collection; collect again")

    # A checks or thread guard can finish while another collector is still
    # reading. Close that gap before fingerprinting, returning or saving evidence.
    identity_after, identity_ms = measured(lambda: collect_pr_identity(repo, number))
    changed = [field for field in IDENTITY_FIELDS
               if (not matches_pr_url(identity_after[field], repo, number) if field == "url"
                   else identity_before[field] != identity_after[field])]
    if changed:
        raise SnapshotError(
            "PR identity changed after parallel collection (" + ", ".join(changed) + "); collect again"
        )

    pr = dict(pr, reviewContext=context)
    fingerprints = section_fingerprints(pr, threads, checks)
    return {
        "schema_version": 1,
        "mode": "collect",
        "repo": repo,
        "number": number,
        "headRefOid": pr["headRefOid"],
        "baseRefName": pr["baseRefName"],
        "baseRefOid": pr["baseRefOid"],
        "updatedAt": pr["updatedAt"],
        "state": pr["state"],
        "mergeStateStatus": pr["mergeStateStatus"],
        "fingerprints": fingerprints,
        "summary": {
            "context": {"coverage": review_context.coverage(pr), "issues": len(context["issues"])},
            "threads": summarize_threads(threads),
            "checks": summarize_checks(checks),
        },
        "timings_ms": {
            "context": context_ms,
            "pr": pr_ms,
            "threads": threads_ms,
            "checks": checks_ms,
            "identity": identity_ms,
            "wall": round((time.monotonic() - started) * 1000, 3),
        },
        "pr": pr,
        "threads": threads,
        "checks": checks,
    }


def reviewed_previous(snapshot, repo, number, head, expected):
    """Validate cached evidence before following any of its extra issue references."""
    try:
        return (snapshot["schema_version"] == 1 and same_repository(snapshot["repo"], repo)
                and snapshot["number"] == number and snapshot["headRefOid"] == head
                and section_fingerprints(snapshot["pr"], snapshot["threads"], snapshot["checks"]) == expected)
    except (KeyError, TypeError, ValueError):
        return False


def collect_selected(repo, number, issues=None, discussions=None, previous=None):
    """Carry forward explicit source selection only from a validated prior snapshot."""
    context = (previous or {}).get("pr", {}).get("reviewContext", {})
    issues = issues if issues is not None else context.get("requested_issues", [])
    discussions = discussions if discussions is not None else context.get("discussion_issues", [])
    if not issues and not discussions:
        return collect_snapshot(repo, number)
    return collect_snapshot(repo, number, issue_refs=issues, discussion_refs=discussions)


def refresh_snapshot(
    repo: str,
    number: int,
    *,
    expected_head: str,
    expected_pr_fingerprint: str,
    expected_threads_fingerprint: str,
    expected_checks_fingerprint: str,
    expected_base_name: str | None = None,
    expected_base_sha: str | None = None,
    previous_snapshot: dict[str, Any] | None = None,
    current_snapshot: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Fully refresh remote state, returning full sections only when they changed."""

    expected = {
        "pr": expected_pr_fingerprint,
        "threads": expected_threads_fingerprint,
        "checks": expected_checks_fingerprint,
    }
    valid_previous = reviewed_previous(previous_snapshot, repo, number, expected_head, expected)
    current = current_snapshot if current_snapshot is not None else collect_selected(
        repo, number, previous=previous_snapshot if valid_previous else None)
    changed_fields: list[str] = []
    if current["headRefOid"] != expected_head:
        changed_fields.append("head")
    if (expected_base_name is None) != (expected_base_sha is None):
        raise SnapshotError("expected base name and SHA must be provided together")
    if expected_base_name is not None and (
        current["pr"]["baseRefName"] != expected_base_name
        or current["pr"]["baseRefOid"] != expected_base_sha
    ):
        changed_fields.append("base")
    for name in ("pr", "threads", "checks"):
        if current["fingerprints"][name] != expected[name]:
            changed_fields.append(name)

    result = {
        key: current[key]
        for key in (
            "schema_version",
            "repo",
            "number",
            "headRefOid",
            "baseRefName",
            "baseRefOid",
            "updatedAt",
            "state",
            "mergeStateStatus",
            "fingerprints",
            "summary",
            "timings_ms",
        )
    }
    result.update(
        {
            "mode": "refresh",
            "unchanged": not changed_fields,
            "changed_fields": changed_fields,
            "base_comparison": "checked" if expected_base_name is not None else "not_provided",
            "context_coverage": review_context.coverage(current["pr"]),
        }
    )
    if "head" in changed_fields:
        result.update(
            {name: current[name] for name in ("pr", "threads", "checks")}
        )
    else:
        for name in ("pr", "threads", "checks"):
            if name in changed_fields:
                result[name] = current[name]
    if previous_snapshot is not None:
        # A saved file is useful only if its contents independently match the
        # caller's previously reviewed fingerprints, identity and head.
        if not valid_previous:
            result.update({name: current[name] for name in ("pr", "threads", "checks")})
            result["evidence_reset"] = "previous snapshot does not match reviewed evidence; read full sections"
        elif "head" not in changed_fields and "threads" in changed_fields:
            before = {item["id"]: item for item in previous_snapshot["threads"]["threads"]}
            after = {item["id"]: item for item in current["threads"]["threads"]}
            result.pop("threads", None)
            result["threads_delta"] = {
                "previous_fingerprint": expected_threads_fingerprint,
                "fingerprint": current["fingerprints"]["threads"],
                "identity": {key: value for key, value in current["threads"].items() if key != "threads"},
                "index": [{"id": key, "fingerprint": review_threads.fingerprint(value),
                           "isResolved": value["isResolved"], "isOutdated": value["isOutdated"]}
                          for key, value in sorted(after.items())],
                "removed_ids": sorted(before.keys() - after.keys()),
                "changed": [value for key, value in sorted(after.items()) if key not in before
                            or review_threads.fingerprint(value) != review_threads.fingerprint(before[key])],
            }
    return result


def main() -> int:
    """Parse arguments and emit one versioned JSON result."""

    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    collect_parser = subparsers.add_parser("collect")
    refresh_parser = subparsers.add_parser("refresh")
    page_parser = subparsers.add_parser("page")
    page_parser.add_argument("--snapshot-file", required=True)
    page_parser.add_argument("--expected-storage-sha256", required=True)
    page_parser.add_argument("--offset", type=int, default=0)
    page_parser.add_argument("--chars", type=int, default=24000)
    for command_parser in (collect_parser, refresh_parser):
        command_parser.add_argument("--repo", required=True)
        command_parser.add_argument("--pr", required=True, type=int)
        command_parser.add_argument("--snapshot-out")
        command_parser.add_argument("--page-chars", type=int, default=24000)
        command_parser.add_argument("--issue", action="append", help="Additional issue explicitly selected for review (repeatable)")
        command_parser.add_argument("--issue-comments", action="append", help="Issue whose full discussion must be read and refreshed (repeatable)")
    refresh_parser.add_argument("--expected-head", required=True)
    refresh_parser.add_argument("--expected-pr-fingerprint", required=True)
    refresh_parser.add_argument("--expected-threads-fingerprint", required=True)
    refresh_parser.add_argument("--expected-checks-fingerprint", required=True)
    refresh_parser.add_argument("--expected-base-name")
    refresh_parser.add_argument("--expected-base-sha")
    refresh_parser.add_argument("--previous-snapshot")
    refresh_parser.add_argument("--previous-storage-sha256")
    arguments = parser.parse_args()

    try:
        if arguments.command == "page":
            result = snapshot_transport.page(arguments.snapshot_file, arguments.expected_storage_sha256,
                                             arguments.offset, arguments.chars)
            print(json.dumps(result, ensure_ascii=False, separators=(",", ":")))
            return 0
        if arguments.page_chars <= 0:
            raise SnapshotError("--page-chars must be positive")
        if arguments.command == "collect":
            result = collect_selected(arguments.repo, arguments.pr, arguments.issue, arguments.issue_comments)
            current = result
        else:
            if bool(arguments.previous_snapshot) != bool(arguments.previous_storage_sha256):
                raise SnapshotError("previous snapshot and storage SHA-256 must be provided together")
            previous, reset = None, None
            if arguments.previous_snapshot:
                try:
                    previous = snapshot_transport.read(arguments.previous_snapshot,
                        arguments.previous_storage_sha256)["snapshot"]
                except (OSError, ValueError, KeyError, TypeError) as error:
                    reset = str(error)
            valid_previous = reviewed_previous(previous, arguments.repo, arguments.pr, arguments.expected_head,
                {"pr": arguments.expected_pr_fingerprint, "threads": arguments.expected_threads_fingerprint,
                 "checks": arguments.expected_checks_fingerprint})
            current = collect_selected(arguments.repo, arguments.pr, arguments.issue, arguments.issue_comments,
                                       previous if valid_previous else None)
            result = refresh_snapshot(
                arguments.repo,
                arguments.pr,
                expected_head=arguments.expected_head,
                expected_pr_fingerprint=arguments.expected_pr_fingerprint,
                expected_threads_fingerprint=arguments.expected_threads_fingerprint,
                expected_checks_fingerprint=arguments.expected_checks_fingerprint,
                expected_base_name=arguments.expected_base_name,
                expected_base_sha=arguments.expected_base_sha,
                previous_snapshot=previous,
                current_snapshot=current,
            )
            if reset is not None:
                result.update({name: current[name] for name in ("pr", "threads", "checks")})
                result["evidence_reset"] = "previous snapshot unavailable; read full sections: " + reset
        if arguments.snapshot_out:
            storage_hash = snapshot_transport.save(arguments.snapshot_out, current, result)
            result = snapshot_transport.page(arguments.snapshot_out, storage_hash, 0, arguments.page_chars)
        print(json.dumps(result, ensure_ascii=False, separators=(",", ":")))
        return 0
    except (
        SnapshotError,
        ValueError,
        KeyError,
        TypeError,
        OSError,
        subprocess.SubprocessError,
    ) as error:
        print(
            json.dumps(
                {
                    "schema_version": 1,
                    "error": str(error),
                    "action": "collect a new PR review snapshot before continuing",
                },
                ensure_ascii=False,
            ),
            file=sys.stderr,
        )
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
