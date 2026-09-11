#!/usr/bin/env python3
"""Collect read-only commit/range evidence with bounded, lossless patch pages."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import os
from pathlib import PurePosixPath
import re
import subprocess
import sys
import time
from typing import Any


class SnapshotError(Exception):
    """A requested review snapshot could not be proved."""


def digest(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def decode(value: bytes) -> str:
    # Preserve non-UTF-8 bytes as escaped surrogates in the JSON transport.
    return value.decode("utf-8", errors="surrogateescape")


class Git:
    def __init__(self, repo: str) -> None:
        self.repo = repo
        self.env = os.environ.copy()
        for key in (
            "GIT_DIR", "GIT_WORK_TREE", "GIT_COMMON_DIR", "GIT_INDEX_FILE",
            "GIT_OBJECT_DIRECTORY", "GIT_ALTERNATE_OBJECT_DIRECTORIES",
            "GIT_NAMESPACE", "GIT_PREFIX", "GIT_GLOB_PATHSPECS",
            "GIT_NOGLOB_PATHSPECS", "GIT_ICASE_PATHSPECS",
        ):
            self.env.pop(key, None)
        self.env.update(
            GIT_OPTIONAL_LOCKS="0", GIT_NO_LAZY_FETCH="1",
            GIT_TERMINAL_PROMPT="0", GIT_ATTR_NOSYSTEM="1",
        )

    def run(self, *args: str, input_data: bytes | None = None) -> bytes:
        command = [
            "git", "--no-pager", "--literal-pathspecs", "-C", self.repo,
            "-c", "core.quotePath=true", "-c", "color.ui=false",
            "-c", "core.fsmonitor=false",
            "-c", "protocol.allow=never", *args,
        ]
        try:
            result = subprocess.run(
                command, input=input_data, stdout=subprocess.PIPE,
                stderr=subprocess.PIPE, env=self.env, timeout=60, check=False,
            )
        except (OSError, subprocess.TimeoutExpired) as error:
            raise SnapshotError(f"Cannot run git {args[0]}: {error}") from error
        if result.returncode != 0:
            reason = decode(result.stderr).strip()
            raise SnapshotError(
                f"git {args[0]} failed ({result.returncode}): {reason}. "
                "Check the repository, refs and locally available objects; then retry."
            )
        return result.stdout

    def commit(self, ref: str) -> str:
        return decode(self.run("rev-parse", "--verify", "--end-of-options", f"{ref}^{{commit}}")).strip()


def literal_paths(paths: list[str]) -> list[str]:
    result = set()
    for value in paths:
        path = PurePosixPath(value)
        if not value or "\0" in value or path.is_absolute() or ".." in path.parts:
            raise SnapshotError("--path must be a literal repository-relative path without '..'")
        result.add(str(path))
    return sorted(result)


def resolve_snapshot(git: Git, args: argparse.Namespace) -> dict[str, Any]:
    paths = literal_paths(args.path)
    if args.commit is not None:
        target = git.commit(args.commit)
        # cat-file retains the true parent list even at a shallow boundary.
        headers = git.run("cat-file", "-p", target).split(b"\n\n", 1)[0]
        parents = [decode(line[7:]) for line in headers.splitlines() if line.startswith(b"parent ")]
        if len(parents) > 1 and args.parent is None:
            raise SnapshotError("Merge commit has multiple parents; choose --parent N (1-based)")
        if args.parent is not None and not 1 <= args.parent <= len(parents):
            raise SnapshotError("--parent must select an existing parent (1-based)")
        parent = (args.parent or 1) if parents else None
        base = git.commit(parents[parent - 1]) if parent else decode(
            git.run("hash-object", "-t", "tree", "--stdin", input_data=b"")
        ).strip()
        return {
            "repo": git.repo, "kind": "commit", "base_sha": base,
            "target_sha": target, "parent": parent, "paths": paths,
        }

    if args.parent is not None:
        raise SnapshotError("--parent is only available with --commit")
    match = re.fullmatch(r"(.+?)(\.\.\.?)(.+)", args.range)
    if match is None:
        raise SnapshotError("--range requires two explicit endpoints: A..B or A...B")
    left_ref, separator, right_ref = match.groups()
    left, target = git.commit(left_ref), git.commit(right_ref)
    base = left
    if separator == "...":
        bases = decode(git.run("merge-base", "--all", left, target)).splitlines()
        if len(bases) != 1:
            raise SnapshotError("Range has no unique merge-base; choose an explicit A..B baseline")
        base = bases[0]
    return {
        "repo": git.repo, "kind": "range", "base_sha": base,
        "target_sha": target, "left_sha": left,
        "range_mode": "merge-base" if separator == "..." else "endpoints", "paths": paths,
    }


def parse_changes(raw: bytes) -> list[dict[str, str | None]]:
    records = iter(raw.split(b"\0")[:-1])
    changes = []
    try:
        for record in records:
            old_mode, new_mode, old_oid, new_oid, status = decode(record).split()
            first_path = decode(next(records))
            rename = status.startswith(("R", "C"))
            changes.append({
                "status": status, "old_path": first_path if rename else None,
                "path": decode(next(records)) if rename else first_path,
                "old_mode": old_mode.removeprefix(":"), "new_mode": new_mode,
                "old_oid": old_oid, "new_oid": new_oid,
            })
    except (StopIteration, ValueError) as error:
        raise SnapshotError("Unexpected raw diff format; collect again with a supported Git version") from error
    return changes


def patch_page(raw: bytes, offset: int, limit: int) -> dict[str, Any]:
    text = decode(raw)
    if offset < 0 or offset > len(text) or limit <= 0:
        raise SnapshotError("Patch offset must be within the patch and --patch-chars must be positive")
    end = min(offset + limit, len(text))
    return {
        "text": text[offset:end], "sha256": digest(raw),
        "total_chars": len(text), "total_bytes": len(raw),
        "offset": offset, "end": end,
        "next_offset": end if end < len(text) else None,
        "complete": offset == 0 and end == len(text),
    }


def collect(args: argparse.Namespace) -> dict[str, Any]:
    started = time.monotonic()
    git = Git(args.repo)
    git.repo = decode(git.run("rev-parse", "--show-toplevel")).removesuffix("\n")
    snapshot = resolve_snapshot(git, args)
    resolved = time.monotonic()
    diff_args = [
        "diff", "--no-ext-diff", "--no-textconv", "--no-color", "--no-relative",
        "--find-renames=50%", "--ignore-submodules=none",
        "--diff-algorithm=myers", "--no-indent-heuristic",
    ]
    endpoints = [snapshot["base_sha"], snapshot["target_sha"], "--", *snapshot["paths"]]
    commands = {
        "patch": [*diff_args, "--patch", "--binary", "--full-index", "--unified=5",
                  "--src-prefix=a/", "--dst-prefix=b/", *endpoints],
        "changes": [*diff_args, "--raw", "--no-abbrev", "-z", *endpoints],
        "status": ["status", "--porcelain=v1", "-z", "--untracked-files=all", "--ignore-submodules=none"],
        "head": ["rev-parse", "--verify", "HEAD"],
    }
    with ThreadPoolExecutor(max_workers=4) as executor:
        futures = {key: executor.submit(git.run, *command) for key, command in commands.items()}
        evidence = {key: future.result() for key, future in futures.items()}
    # Include raw records as well as patch bytes, so modes and unusual names are bound.
    content_hash = digest(evidence["changes"] + b"\0" + evidence["patch"])
    snapshot["fingerprint"] = digest(json.dumps(
        {"snapshot": snapshot, "content_sha256": content_hash}, sort_keys=True,
    ).encode("utf-8"))
    page = patch_page(evidence["patch"], args.patch_offset, args.patch_chars)
    unchanged = args.expected_fingerprint == snapshot["fingerprint"]
    result: dict[str, Any] = {
        "schema_version": 1,
        "mode": "verify" if args.expected_fingerprint else "collect",
        "state": "unchanged" if unchanged else "changed" if args.expected_fingerprint else "collected",
        "snapshot": snapshot,
        "checkout": {
            "head_sha": decode(evidence["head"]).strip(),
            "dirty": bool(evidence["status"]), "status_sha256": digest(evidence["status"]),
        },
    }
    if not unchanged:
        result.update(changes=parse_changes(evidence["changes"]), patch=page)
    result["timings_ms"] = {
        "resolve": round((resolved - started) * 1000, 3),
        "evidence": round((time.monotonic() - resolved) * 1000, 3),
        "total": round((time.monotonic() - started) * 1000, 3),
    }
    return result


class Parser(argparse.ArgumentParser):
    def error(self, message: str) -> None:
        raise SnapshotError(f"{message}; use --help for supported arguments")


def emit(value: dict[str, Any]) -> None:
    # Keep ordinary Unicode readable and compact; escape only undecodable bytes.
    encoded = json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    sys.stdout.buffer.write(encoded.encode("utf-8", errors="backslashreplace") + b"\n")


def main() -> int:
    parser = Parser(description=__doc__)
    parser.add_argument("--repo", default=".")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--commit")
    group.add_argument("--range")
    parser.add_argument("--parent", type=int)
    parser.add_argument("--path", action="append", default=[])
    parser.add_argument("--expected-fingerprint")
    parser.add_argument("--patch-offset", type=int, default=0)
    parser.add_argument("--patch-chars", type=int, default=24000)
    try:
        args = parser.parse_args()
        if args.expected_fingerprint is not None and re.fullmatch(r"[0-9a-f]{64}", args.expected_fingerprint) is None:
            raise SnapshotError("--expected-fingerprint must be a lowercase SHA-256 hex digest")
        result = collect(args)
    except SnapshotError as error:
        emit({"schema_version": 1, "error": str(error)})
        return 1
    emit(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
