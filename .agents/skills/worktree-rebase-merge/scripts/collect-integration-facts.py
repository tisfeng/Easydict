#!/usr/bin/env python3
"""Collect compact, read-only Git facts for worktree integration."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
from typing import Any


class InspectionError(RuntimeError):
    """The requested Git facts could not be collected safely."""


def git(
    repository: Path,
    *arguments: str,
    allowed: tuple[int, ...] = (0,),
    timeout: int = 30,
) -> bytes:
    """Run one read-only Git command and return its raw stdout."""

    environment = dict(os.environ, GIT_OPTIONAL_LOCKS="0", LC_ALL="C")
    try:
        result = subprocess.run(
            [
                "git",
                "--no-pager",
                "-c",
                "core.fsmonitor=false",
                "-C",
                os.fspath(repository),
                *arguments,
            ],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=environment,
            timeout=timeout,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        raise InspectionError(f"cannot run git {arguments[0]}: {error}") from error
    if result.returncode not in allowed:
        detail = os.fsdecode(result.stderr).strip()
        raise InspectionError(
            f"git {arguments[0]} failed with {result.returncode}: "
            f"{detail or 'no diagnostic'}"
        )
    return result.stdout


def text(repository: Path, *arguments: str, **kwargs: Any) -> str:
    """Run Git and decode stdout with filesystem semantics."""

    return os.fsdecode(git(repository, *arguments, **kwargs))


def branch_ref(repository: Path, name: str) -> str:
    """Validate a local branch name and return its full ref."""

    ref = f"refs/heads/{name}"
    text(repository, "check-ref-format", ref)
    return ref


def commit_oid(repository: Path, revision: str) -> str:
    """Resolve one revision to a full commit object ID."""

    return text(
        repository,
        "rev-parse",
        "--verify",
        "--end-of-options",
        f"{revision}^{{commit}}",
    ).strip()


def status_records(repository: Path) -> list[dict[str, str]]:
    """Parse porcelain v1 -z output without losing rename source paths."""

    fields = os.fsdecode(
        git(
            repository,
            "status",
            "--porcelain=v1",
            "-z",
            "--untracked-files=all",
        )
    ).split("\0")
    records: list[dict[str, str]] = []
    index = 0
    while index < len(fields):
        field = fields[index]
        index += 1
        if not field:
            continue
        if len(field) < 3:
            raise InspectionError("git status returned a malformed porcelain record")
        record = {"index": field[0], "worktree": field[1], "path": field[3:]}
        if field[0] in "RC" or field[1] in "RC":
            if index >= len(fields) or not fields[index]:
                raise InspectionError("git status omitted a rename or copy source path")
            record["original_path"] = fields[index]
            index += 1
        records.append(record)
    return records


def hash_worktree_path(
    digest: Any,
    repository: Path,
    raw_path: bytes,
    label: bytes,
) -> None:
    """Hash one worktree path including its type, mode, and raw bytes."""

    path = repository / os.fsdecode(raw_path)
    digest.update(label)
    digest.update(raw_path)
    digest.update(b"\0")
    try:
        metadata = path.lstat()
    except FileNotFoundError:
        digest.update(b"missing\0")
        return
    digest.update(str(metadata.st_mode).encode("ascii"))
    digest.update(b"\0")
    if path.is_symlink():
        digest.update(os.fsencode(os.readlink(path)))
    elif path.is_file():
        with path.open("rb") as stream:
            while chunk := stream.read(1024 * 1024):
                digest.update(chunk)


def content_fingerprint(
    repository: Path,
    status: list[dict[str, str]],
) -> str:
    """Hash Git evidence and candidate worktree bytes without emitting them."""

    digest = hashlib.sha256()
    for label, arguments in (
        (
            b"staged\0",
            (
                "diff",
                "--cached",
                "--binary",
                "--full-index",
                "--no-ext-diff",
                "--no-textconv",
            ),
        ),
        (
            b"unstaged\0",
            (
                "diff",
                "--binary",
                "--full-index",
                "--no-ext-diff",
                "--no-textconv",
            ),
        ),
    ):
        digest.update(label)
        digest.update(git(repository, *arguments))

    tracked_paths = {
        value
        for record in status
        if not (record["index"] == "?" and record["worktree"] == "?")
        for key in ("path", "original_path")
        if (value := record.get(key)) is not None
    }
    for tracked_path in sorted(tracked_paths):
        hash_worktree_path(
            digest,
            repository,
            os.fsencode(tracked_path),
            b"tracked-worktree\0",
        )

    untracked = git(repository, "ls-files", "--others", "--exclude-standard", "-z")
    for raw_path in filter(None, untracked.split(b"\0")):
        hash_worktree_path(digest, repository, raw_path, b"untracked\0")
    return digest.hexdigest()


def operation_names(git_directory: Path) -> list[str]:
    """Return active sequencer or merge operations for one checkout."""

    names = (
        "MERGE_HEAD",
        "CHERRY_PICK_HEAD",
        "REVERT_HEAD",
        "rebase-merge",
        "rebase-apply",
        "sequencer",
        "BISECT_START",
    )
    return [name for name in names if (git_directory / name).exists()]


def checkout(repository: Path) -> dict[str, Any]:
    """Collect the mutable state relevant to one checkout."""

    root = Path(text(repository, "rev-parse", "--show-toplevel").rstrip("\n"))
    git_directory = Path(
        text(repository, "rev-parse", "--absolute-git-dir").rstrip("\n")
    )
    status = status_records(root)
    branch = text(root, "symbolic-ref", "-q", "HEAD", allowed=(0, 1)).strip()
    return {
        "path": os.fspath(root),
        "head": commit_oid(root, "HEAD"),
        "branch_ref": branch or None,
        "branch": branch.removeprefix("refs/heads/") if branch else None,
        "status": status,
        "content_fingerprint": content_fingerprint(root, status),
        "clean": not status,
        "operations": operation_names(git_directory),
    }


def worktree_records(repository: Path) -> list[dict[str, str]]:
    """Parse the machine-readable worktree inventory."""

    raw = os.fsdecode(git(repository, "worktree", "list", "--porcelain", "-z"))
    records: list[dict[str, str]] = []
    for block in raw.split("\0\0"):
        record: dict[str, str] = {}
        for field in filter(None, block.split("\0")):
            key, separator, value = field.partition(" ")
            record[key] = value if separator else "true"
        if record:
            records.append(record)
    return records


def select_remote(repository: Path) -> str:
    """Apply the Skill's origin-or-only-remote rule."""

    remotes = [item for item in text(repository, "remote").splitlines() if item]
    if "origin" in remotes:
        return "origin"
    if len(remotes) == 1:
        return remotes[0]
    if not remotes:
        raise InspectionError("no Git remote is configured; specify --target")
    raise InspectionError(
        "remote selection is ambiguous; specify --target or leave only one remote"
    )


def cached_remote_head(repository: Path, remote: str) -> str | None:
    """Return a diagnostic-only cached remote HEAD candidate."""

    candidate = text(
        repository,
        "symbolic-ref",
        "-q",
        f"refs/remotes/{remote}/HEAD",
        allowed=(0, 1),
    ).strip()
    return candidate or None


def resolve_target(repository: Path, requested: str | None) -> tuple[str, dict[str, str]]:
    """Resolve an explicit target or query the live remote HEAD."""

    if requested:
        branch_ref(repository, requested)
        return requested, {"kind": "explicit"}

    remote = select_remote(repository)
    try:
        output = text(repository, "ls-remote", "--symref", remote, "HEAD", timeout=60)
    except InspectionError as error:
        cached = cached_remote_head(repository, remote)
        suffix = f"; cached candidate (not selected): {cached}" if cached else ""
        raise InspectionError(f"live remote HEAD query failed: {error}{suffix}") from error

    prefix = "ref: refs/heads/"
    for line in output.splitlines():
        if line.startswith(prefix) and line.endswith("\tHEAD"):
            return line[len(prefix) : -len("\tHEAD")], {
                "kind": "remote-head",
                "remote": remote,
            }
    cached = cached_remote_head(repository, remote)
    suffix = f"; cached candidate (not selected): {cached}" if cached else ""
    raise InspectionError(f"live remote HEAD did not contain a branch ref{suffix}")


def choose_source_branch(
    repository: Path,
    requested: str | None,
    source: dict[str, Any],
    worktrees: list[dict[str, str]],
) -> dict[str, str] | None:
    """Choose an exact create/reuse action for a detached source."""

    if source["branch"] or requested is None:
        return None
    branch_ref(repository, requested)
    occupied = {item.get("branch") for item in worktrees}
    number = 1
    while True:
        name = requested if number == 1 else f"{requested}-{number}"
        ref = branch_ref(repository, name)
        try:
            result = subprocess.run(
                [
                    "git",
                    "--no-pager",
                    "-c",
                    "core.fsmonitor=false",
                    "-C",
                    os.fspath(repository),
                    "show-ref",
                    "--verify",
                    "--quiet",
                    ref,
                ],
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE,
                env=dict(os.environ, GIT_OPTIONAL_LOCKS="0", LC_ALL="C"),
                timeout=30,
            )
        except (OSError, subprocess.TimeoutExpired) as error:
            raise InspectionError(
                f"cannot inspect candidate branch {name}: {error}"
            ) from error
        if result.returncode == 1:
            return {"name": name, "action": "create"}
        if result.returncode != 0:
            detail = os.fsdecode(result.stderr).strip()
            raise InspectionError(
                f"cannot inspect candidate branch {name}: "
                f"{detail or result.returncode}"
            )
        if commit_oid(repository, ref) == source["head"] and ref not in occupied:
            return {"name": name, "action": "reuse"}
        number += 1


def target_facts(
    repository: Path,
    target: str,
    worktrees: list[dict[str, str]],
) -> dict[str, Any]:
    """Return only worktrees that exactly checkout the target branch."""

    ref = branch_ref(repository, target)
    head = commit_oid(repository, ref)
    checkouts = [
        checkout(Path(item["worktree"]))
        for item in worktrees
        if item.get("branch") == ref
    ]
    selected = next((item["path"] for item in checkouts if item["clean"]), None)
    return {
        "name": target,
        "ref": ref,
        "head": head,
        "mode": (
            "existing-target-worktree" if checkouts else "temporary-target-worktree"
        ),
        "selected": selected,
        "checkouts": checkouts,
    }


def range_facts(repository: Path, source_head: str, target_head: str) -> dict[str, Any]:
    """Collect commits and every path touched by the source range."""

    revision_range = f"{target_head}..{source_head}"
    commits = text(repository, "rev-list", "--reverse", revision_range, "--").splitlines()
    paths = sorted(
        set(
            filter(
                None,
                text(
                    repository,
                    "log",
                    "--format=",
                    "--name-only",
                    "-z",
                    "--no-renames",
                    "-m",
                    "--no-ext-diff",
                    "--no-textconv",
                    revision_range,
                    "--",
                ).split("\0"),
            )
        )
    )
    merge_bases = text(
        repository,
        "merge-base",
        "--all",
        target_head,
        source_head,
        allowed=(0, 1),
    ).splitlines()
    return {"commits": commits, "paths": paths, "merge_bases": merge_bases}


def collect(
    source_path: Path,
    requested_target: str | None,
    requested_source_branch: str | None,
) -> dict[str, Any]:
    """Collect one compact snapshot and detect drift during collection."""

    repository = Path(
        text(source_path, "rev-parse", "--show-toplevel").rstrip("\n")
    )
    with ThreadPoolExecutor(max_workers=2) as executor:
        source_future = executor.submit(checkout, repository)
        target_future = executor.submit(resolve_target, repository, requested_target)
        source = source_future.result()
        target_name, resolution = target_future.result()

    target_ref = branch_ref(repository, target_name)
    target_head = commit_oid(repository, target_ref)
    if source["branch_ref"] == target_ref:
        changed_fields: list[str] = []
        if checkout(repository) != source:
            changed_fields.append("source")
        if commit_oid(repository, target_ref) != target_head:
            changed_fields.append("target-head")
        return {
            "schema_version": 1,
            "stable": not changed_fields,
            "changed_fields": changed_fields,
            "target_resolution": resolution,
            "mode": "direct-commit",
            "source": source,
            "target": {
                "name": target_name,
                "ref": target_ref,
                "head": target_head,
                "source_is_target": True,
            },
            "source_branch": None,
        }

    worktrees = worktree_records(repository)
    target = target_facts(repository, target_name, worktrees)
    source_branch = choose_source_branch(
        repository, requested_source_branch, source, worktrees
    )
    integration_range = range_facts(repository, source["head"], target["head"])

    changed_fields: list[str] = []
    if checkout(repository) != source:
        changed_fields.append("source")
    if commit_oid(repository, target["ref"]) != target["head"]:
        changed_fields.append("target-head")
    if worktree_records(repository) != worktrees:
        changed_fields.append("worktrees")
    current_targets = target_facts(repository, target_name, worktrees)["checkouts"]
    if current_targets != target["checkouts"]:
        changed_fields.append("target-checkouts")

    return {
        "schema_version": 1,
        "stable": not changed_fields,
        "changed_fields": changed_fields,
        "target_resolution": resolution,
        "mode": "rebase-merge",
        "source": source,
        "target": target,
        "source_branch": source_branch,
        "range": integration_range,
    }


def main() -> int:
    """Parse arguments, emit one JSON object, and use stable exit codes."""

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", default=".", help="Source checkout path")
    parser.add_argument("--target", help="Explicit local target branch")
    parser.add_argument(
        "--source-branch",
        help="Candidate Conventional branch when the source is detached",
    )
    arguments = parser.parse_args()
    try:
        payload = collect(
            Path(arguments.source), arguments.target, arguments.source_branch
        )
        print(json.dumps(payload, ensure_ascii=True, separators=(",", ":")))
        return 0 if payload["stable"] else 2
    except (InspectionError, OSError, ValueError, KeyError, TypeError) as error:
        print(
            json.dumps(
                {
                    "schema_version": 1,
                    "error": str(error),
                    "action": "inspect the reported Git state before retrying",
                },
                ensure_ascii=True,
                separators=(",", ":"),
            ),
            file=sys.stderr,
        )
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
