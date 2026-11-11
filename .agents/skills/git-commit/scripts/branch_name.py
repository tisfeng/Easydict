#!/usr/bin/env python3
"""Generate and validate branch names without modifying Git state."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys


TASK_TYPES = (
    "feat", "fix", "docs", "style", "refactor", "perf", "test", "build", "ci", "chore", "revert",
)
TASK_PATTERN = re.compile(
    rf"(?:{'|'.join(TASK_TYPES)})/[a-z0-9]+(?:-[a-z0-9]+)*"
)


def validate_literal(name: str) -> str:
    """Validate an exact user-supplied ref, excluding Git checkout shorthand."""

    if not name or name.startswith("-") or "@{" in name:
        raise ValueError(f"Invalid literal branch name: {name!r}")
    result = subprocess.run(
        ["git", "check-ref-format", "--branch", name],
        capture_output=True, text=True, check=False,
    )
    if result.returncode:
        raise ValueError(f"Invalid literal branch name: {name!r}")
    return name


def is_task_name(name: str) -> bool:
    """Classify a name using the shared default task convention."""

    return TASK_PATTERN.fullmatch(name) is not None


def task_name(task_type: str, summary: str) -> str:
    """Build a task name from an explicit type and English kebab-case summary."""

    name = f"{task_type}/{summary}"
    if not is_task_name(name):
        raise ValueError("Use a supported task type and a lowercase English kebab-case summary")
    return validate_literal(name)


def review_name(pr_number: int, sha: str, *, merge_latest: bool = False) -> str:
    """Build the ordinary or latest-base review name from its frozen identity."""

    if pr_number < 1 or re.fullmatch(r"(?:[a-fA-F0-9]{10}|[a-fA-F0-9]{40}|[a-fA-F0-9]{64})", sha) is None:
        raise ValueError("Review naming requires a positive PR number and a Git object ID (or its 10-digit prefix)")
    operation = "-merge" if merge_latest else ""
    return validate_literal(f"review/pr-{pr_number}{operation}-{sha[:10].lower()}")


def release_name(version: str) -> str:
    """Build a release synchronization name from a version token."""

    if re.fullmatch(r"v?[0-9]+(?:\.[0-9]+)+(?:-[a-z0-9]+(?:[.-][a-z0-9]+)*)?", version) is None:
        raise ValueError("Release naming requires a numeric dotted version with an optional lowercase prerelease")
    return validate_literal(f"release/sync-{version}")


def candidate_name(name: str, number: int = 1) -> str:
    """Return one collision candidate; callers decide whether a ref is occupied."""

    validate_literal(name)
    if number < 1:
        raise ValueError("Candidate number must be positive")
    return validate_literal(name if number == 1 else f"{name}-{number}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    task = commands.add_parser("task")
    task.add_argument("--type", choices=TASK_TYPES, required=True)
    task.add_argument("--summary", required=True)
    review = commands.add_parser("review")
    review.add_argument("--pr", type=int, required=True)
    review.add_argument("--sha", required=True)
    review.add_argument("--merge-latest", action="store_true")
    release = commands.add_parser("release")
    release.add_argument("--version", required=True)
    for command in ("validate", "is-task", "candidate"):
        subparser = commands.add_parser(command)
        subparser.add_argument("--name", required=True)
        if command == "candidate":
            subparser.add_argument("--number", type=int, default=1)
    arguments = parser.parse_args()
    try:
        if arguments.command == "task":
            name = task_name(arguments.type, arguments.summary)
        elif arguments.command == "review":
            name = review_name(arguments.pr, arguments.sha, merge_latest=arguments.merge_latest)
        elif arguments.command == "release":
            name = release_name(arguments.version)
        elif arguments.command == "candidate":
            name = candidate_name(arguments.name, arguments.number)
        elif arguments.command == "is-task":
            return 0 if is_task_name(arguments.name) else 1
        else:
            name = validate_literal(arguments.name)
        print(name)
        return 0
    except (ValueError, OSError) as error:
        print(f"Branch naming failed: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
