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


PR_FIELDS = (
    "number,title,url,body,baseRefName,baseRefOid,headRefName,headRefOid,"
    "headRepository,headRepositoryOwner,isCrossRepository,isDraft,state,"
    "mergeable,mergeStateStatus,updatedAt,files,commits,"
    "closingIssuesReferences,comments,reviews"
)
CHECK_FIELDS = "bucket,link,name,state,workflow"
CHECK_EXIT_CODES = (0, 1, 8)


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


def collect_snapshot(repo: str, number: int) -> dict[str, Any]:
    """Anchor the PR identity, then collect independent review facts in parallel."""

    started = time.monotonic()
    pr, pr_ms = measured(lambda: collect_pr(repo, number))
    expected_head = pr.get("headRefOid")
    if not isinstance(expected_head, str):
        raise SnapshotError("gh pr view did not return headRefOid")
    with ThreadPoolExecutor(max_workers=2) as executor:
        futures = {
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
    if pr.get("number") != number or threads.get("number") != number:
        raise SnapshotError("PR number changed during snapshot collection")
    if pr.get("headRefOid") != threads.get("headRefOid"):
        raise SnapshotError("PR head changed during snapshot collection; collect again")
    if pr.get("headRefOid") != checks.get("headRefOid"):
        raise SnapshotError("checks do not match the collected PR head; collect again")
    if pr.get("url") != threads.get("url"):
        raise SnapshotError("PR identity changed during snapshot collection; collect again")

    fingerprints = {
        "pr": canonical_fingerprint(pr),
        "threads": canonical_fingerprint(threads),
        "checks": canonical_fingerprint(checks),
    }
    return {
        "schema_version": 1,
        "mode": "collect",
        "repo": repo,
        "number": number,
        "headRefOid": pr["headRefOid"],
        "updatedAt": pr["updatedAt"],
        "state": pr["state"],
        "mergeStateStatus": pr["mergeStateStatus"],
        "fingerprints": fingerprints,
        "summary": {
            "threads": summarize_threads(threads),
            "checks": summarize_checks(checks),
        },
        "timings_ms": {
            "pr": pr_ms,
            "threads": threads_ms,
            "checks": checks_ms,
            "wall": round((time.monotonic() - started) * 1000, 3),
        },
        "pr": pr,
        "threads": threads,
        "checks": checks,
    }


def refresh_snapshot(
    repo: str,
    number: int,
    *,
    expected_head: str,
    expected_pr_fingerprint: str,
    expected_threads_fingerprint: str,
    expected_checks_fingerprint: str,
) -> dict[str, Any]:
    """Fully refresh remote state, returning full sections only when they changed."""

    current = collect_snapshot(repo, number)
    changed_fields: list[str] = []
    if current["headRefOid"] != expected_head:
        changed_fields.append("head")
    expected = {
        "pr": expected_pr_fingerprint,
        "threads": expected_threads_fingerprint,
        "checks": expected_checks_fingerprint,
    }
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
    return result


def main() -> int:
    """Parse arguments and emit one versioned JSON result."""

    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    collect_parser = subparsers.add_parser("collect")
    refresh_parser = subparsers.add_parser("refresh")
    for command_parser in (collect_parser, refresh_parser):
        command_parser.add_argument("--repo", required=True)
        command_parser.add_argument("--pr", required=True, type=int)
    refresh_parser.add_argument("--expected-head", required=True)
    refresh_parser.add_argument("--expected-pr-fingerprint", required=True)
    refresh_parser.add_argument("--expected-threads-fingerprint", required=True)
    refresh_parser.add_argument("--expected-checks-fingerprint", required=True)
    arguments = parser.parse_args()

    try:
        if arguments.command == "collect":
            result = collect_snapshot(arguments.repo, arguments.pr)
        else:
            result = refresh_snapshot(
                arguments.repo,
                arguments.pr,
                expected_head=arguments.expected_head,
                expected_pr_fingerprint=arguments.expected_pr_fingerprint,
                expected_threads_fingerprint=arguments.expected_threads_fingerprint,
                expected_checks_fingerprint=arguments.expected_checks_fingerprint,
            )
        print(json.dumps(result, ensure_ascii=False, indent=2))
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
