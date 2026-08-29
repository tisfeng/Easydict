#!/usr/bin/env python3
"""Report Git text-line changes grouped into code and documentation."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from dataclasses import dataclass
from pathlib import PurePosixPath


DOCUMENT_EXTENSIONS = {".adoc", ".md", ".mdx", ".rst"}
DOCUMENT_DIRECTORIES = {"docs", "documentation"}
DOCUMENT_FILENAMES = {"agents.md", "skill.md"}


class ChangeStatsError(RuntimeError):
    """Describe an invalid revision or unreadable Git change set."""


@dataclass
class ChangeStats:
    """Accumulate line and file counts for one text-file category."""

    files: int = 0
    insertions: int = 0
    deletions: int = 0

    def add(self, insertions: int, deletions: int) -> None:
        """Add one text file's line changes."""

        self.files += 1
        self.insertions += insertions
        self.deletions += deletions

    def payload(self) -> dict[str, int]:
        """Return the stable JSON representation used by commit workflows."""

        return {
            "deletions": self.deletions,
            "files": self.files,
            "insertions": self.insertions,
            "net": self.insertions - self.deletions,
        }


def run_git(arguments: list[str]) -> bytes:
    """Run one read-only Git command and return its raw stdout."""

    try:
        result = subprocess.run(
            ["git", *arguments],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except subprocess.CalledProcessError as error:
        message = error.stderr.decode("utf-8", errors="replace").strip()
        raise ChangeStatsError(message or "Git command failed") from error
    return result.stdout


def resolve_commit(revision: str) -> str:
    """Resolve a user-supplied commit revision to a full object ID."""

    output = run_git(
        ["rev-parse", "--verify", "--end-of-options", f"{revision}^{{commit}}"]
    )
    return output.decode("ascii").strip()


def resolve_range(revision_range: str) -> str:
    """Resolve both sides of a three-dot integration range."""

    parts = revision_range.split("...")
    if len(parts) != 2 or not all(parts):
        raise ChangeStatsError("range must use the BASE...SOURCE form")
    base, source = (resolve_commit(part) for part in parts)
    return f"{base}...{source}"


def read_numstat(revision: str, is_range: bool) -> bytes:
    """Read rename-aware, NUL-delimited numstat data."""

    if is_range:
        return run_git(["diff", "--numstat", "-z", "--find-renames", revision])
    return run_git(
        ["show", "--format=", "--numstat", "-z", "--find-renames", revision]
    )


def parse_numstat(data: bytes) -> list[tuple[str, str, str]]:
    """Parse NUL-delimited numstat records and preserve destination paths."""

    tokens = data.split(b"\0")
    if tokens and tokens[-1] == b"":
        tokens.pop()

    changes: list[tuple[str, str, str]] = []
    index = 0
    while index < len(tokens):
        fields = tokens[index].split(b"\t", 2)
        index += 1
        if len(fields) != 3:
            raise ChangeStatsError("unexpected Git numstat record")

        insertions, deletions, path = fields
        if path == b"":
            if index + 1 >= len(tokens):
                raise ChangeStatsError("incomplete Git rename record")
            index += 1  # The source path does not affect classification.
            path = tokens[index]
            index += 1

        changes.append(
            (
                insertions.decode("ascii"),
                deletions.decode("ascii"),
                os.fsdecode(path),
            )
        )
    return changes


def is_documentation(path: str) -> bool:
    """Return whether a repository path belongs to the documentation category."""

    normalized = PurePosixPath(path)
    parts = {part.lower() for part in normalized.parts[:-1]}
    filename = normalized.name.lower()

    return (
        bool(parts & DOCUMENT_DIRECTORIES)
        or filename in DOCUMENT_FILENAMES
        or filename.startswith("readme")
        or filename.startswith("changelog")
        or normalized.suffix.lower() in DOCUMENT_EXTENSIONS
    )


def collect_stats(data: bytes) -> tuple[ChangeStats, ChangeStats, ChangeStats]:
    """Aggregate text changes and silently skip binary numstat entries."""

    code = ChangeStats()
    docs = ChangeStats()
    for insertions_text, deletions_text, path in parse_numstat(data):
        if insertions_text == "-" or deletions_text == "-":
            continue

        insertions = int(insertions_text)
        deletions = int(deletions_text)
        category = docs if is_documentation(path) else code
        category.add(insertions, deletions)

    total = ChangeStats(
        files=code.files + docs.files,
        insertions=code.insertions + docs.insertions,
        deletions=code.deletions + docs.deletions,
    )
    return total, code, docs


def parse_arguments() -> argparse.Namespace:
    """Parse a commit revision or an aggregate three-dot range."""

    parser = argparse.ArgumentParser(
        description="Report text changes grouped into code and documentation."
    )
    parser.add_argument(
        "revision",
        nargs="?",
        default="HEAD",
        help="commit revision to inspect (default: HEAD)",
    )
    parser.add_argument(
        "--range",
        dest="revision_range",
        help="aggregate a BASE...SOURCE integration range",
    )
    arguments = parser.parse_args()
    if arguments.revision_range and arguments.revision != "HEAD":
        parser.error("do not combine a positional revision with --range")
    return arguments


def main() -> int:
    """Resolve the requested change set and print a stable JSON report."""

    arguments = parse_arguments()
    try:
        is_range = arguments.revision_range is not None
        revision = (
            resolve_range(arguments.revision_range)
            if is_range
            else resolve_commit(arguments.revision)
        )
        total, code, docs = collect_stats(read_numstat(revision, is_range))
    except ChangeStatsError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    print(
        json.dumps(
            {
                "code": code.payload(),
                "docs": docs.payload(),
                "revision": revision,
                "scope": "range" if is_range else "commit",
                "total": total.payload(),
            },
            ensure_ascii=False,
            indent=2,
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
