#!/usr/bin/env python3
"""Remove one completed release's local artifacts after Issue follow-up."""

import argparse
import errno
import json
import os
import re
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path


VERSION_PATTERN = re.compile(r"[0-9]+\.[0-9]+\.[0-9]+\Z")
GENERATED_ENTRIES = {
    ".DS_Store",
    "Easydict-notarization.zip",
    "Easydict.xcarchive",
    "appcast",
    "artifacts",
    "derived-data",
    "export",
    "logs",
    "publish-integration",
    "replacement",
    "stale",
    "state",
    "verify",
    "worktree",
}
REQUIRED_STEPS = {"verify_remote_release", "cleanup_release_worktree"}


class CleanupError(Exception):
    """A safety gate prevented local cleanup."""


def run_git(root, *args):
    result = subprocess.run(
        ["git", "-C", str(root), *args],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode:
        raise CleanupError(result.stderr.strip() or f"git {' '.join(args)} failed")
    return result.stdout


def read_json(path):
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        raise CleanupError(f"cannot read {path}: {error}") from error
    if not isinstance(payload, dict):
        raise CleanupError(f"expected JSON object: {path}")
    return payload


def check_layout(root, release_root, version_dir, marker):
    if Path(run_git(root, "rev-parse", "--show-toplevel").strip()).resolve() != root:
        raise CleanupError("RELEASE_SOURCE_ROOT must be the Git repository root")
    for path in (
        root / ".tmp",
        release_root,
        release_root / "asc",
        release_root / "asc" / "runs",
        release_root / "asc" / "cleanup",
        marker,
        version_dir,
    ):
        if path.is_symlink():
            raise CleanupError(f"refusing symlink in release path: {path}")


def matching_runs(runs_dir, version):
    matches = []
    if not runs_dir.exists():
        return matches
    for path in runs_dir.glob("*.json"):
        if path.is_symlink():
            raise CleanupError(f"refusing symlinked run record: {path}")
        run = read_json(path)
        params = run.get("params", {})
        if isinstance(params, dict) and params.get("VERSION") == version:
            matches.append((path, run))
    return matches


def completed_run(matches):
    for path, run in matches:
        status = run.get("status")
        if status not in {"ok", "error", "failed", "cancelled"}:
            raise CleanupError(f"release run still active or has unknown status: {path}")
    if not matches:
        raise CleanupError("no ASC run records for this version")
    path, run = max(matches, key=lambda item: item[1].get("updated_at", ""))
    steps = run.get("steps", {})
    passed = (
        {
            step.get("name")
            for step in steps.values()
            if isinstance(step, dict) and step.get("status") == "ok"
        }
        if isinstance(steps, dict)
        else set()
    )
    if (
        run.get("workflow") not in {"publish", "release"}
        or run.get("status") != "ok"
        or run.get("dry_run") is True
        or not REQUIRED_STEPS <= passed
    ):
        raise CleanupError(
            "no successful publish/release run with remote verification and worktree cleanup"
        )
    return path, run


def registered_worktrees(root, version_dir):
    paths = []
    for line in run_git(root, "worktree", "list", "--porcelain").splitlines():
        if not line.startswith("worktree "):
            continue
        path = Path(line.removeprefix("worktree ")).resolve()
        if path == version_dir or version_dir in path.parents:
            paths.append(path)
    return sorted(paths, key=lambda path: len(path.parts), reverse=True)


def validate_targets(version_dir, worktrees):
    if not version_dir.is_dir():
        raise CleanupError(f"release directory missing: {version_dir}")
    unknown = {path.name for path in version_dir.iterdir()} - GENERATED_ENTRIES
    if unknown:
        names = ", ".join(sorted(unknown))
        raise CleanupError(f"unknown release entries; inspect manually: {names}")
    for entry in version_dir.iterdir():
        if entry.is_symlink():
            raise CleanupError(f"refusing symlinked release entry: {entry}")
    registered = set(worktrees)
    candidates = [
        version_dir / "worktree",
        version_dir / "publish-integration",
        version_dir / "replacement" / "backup" / "worktree",
    ]
    stale = version_dir / "stale"
    if stale.exists():
        candidates.extend(attempt / "worktree" for attempt in stale.iterdir() if attempt.is_dir())
    for path in candidates:
        if path.exists() and (path / ".git").exists() and path.resolve() not in registered:
            raise CleanupError(f"unregistered Git worktree: {path}")
    for path in worktrees:
        if not path.is_dir():
            raise CleanupError(f"registered worktree missing: {path}")
        if run_git(path, "status", "--porcelain", "--untracked-files=all").strip():
            raise CleanupError(f"worktree has local changes: {path}")


def remove_path(path):
    if path.is_symlink():
        raise CleanupError(f"refusing symlink: {path}")
    if path.is_dir():
        for attempt in range(5):
            try:
                shutil.rmtree(path)
                break
            except OSError as error:
                if error.errno != errno.ENOTEMPTY or attempt == 4:
                    raise
                if not path.exists():
                    break
                time.sleep(0.1)
    elif path.exists():
        path.unlink()


def estimated_size_kib(path):
    if not path.exists():
        return 0
    result = subprocess.run(["du", "-sk", str(path)], capture_output=True, text=True, check=False)
    if result.returncode:
        raise CleanupError(result.stderr.strip() or f"cannot measure {path}")
    return int(result.stdout.split()[0])


def parse_time(value):
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except (AttributeError, ValueError) as error:
        raise CleanupError(f"invalid cleanup/run timestamp: {value}") from error


def execute_cleanup(root, release_root, version_dir, marker, version, run_id):
    cache = release_root / "cache"
    if cache.is_symlink():
        raise CleanupError(f"refusing symlinked release cache: {cache}")
    cache.mkdir(exist_ok=True)
    lock = cache / "build.lock"
    try:
        lock.mkdir()
    except FileExistsError as error:
        raise CleanupError(f"release build cache is locked: {lock}") from error
    try:
        (lock / "owner").write_text(f"pid={os.getpid()}\nversion={version}\n", encoding="utf-8")
        matches = matching_runs(release_root / "asc" / "runs", version)
        final_statuses = {"ok", "error", "failed", "cancelled"}
        if any(run.get("status") not in final_statuses for _, run in matches):
            raise CleanupError("another release run for this version is active")
        if marker.exists():
            started = parse_time(read_json(marker).get("started_at"))
            if any(
                parse_time(run["created_at"]) > started
                for _, run in matches
                if run.get("created_at")
            ):
                raise CleanupError("a newer release run started after local cleanup began")
        worktrees = registered_worktrees(root, version_dir) if version_dir.exists() else []
        if version_dir.exists():
            validate_targets(version_dir, worktrees)
        if not marker.exists():
            marker.parent.mkdir(parents=True, exist_ok=True)
            receipt = {
                "version": version,
                "run_id": run_id,
                "started_at": datetime.now(timezone.utc).isoformat(),
            }
            marker.write_text(
                json.dumps(receipt) + "\n",
                encoding="utf-8",
            )
        for path in worktrees:
            run_git(root, "worktree", "remove", str(path))
        if version_dir.exists():
            # Preserve the Issue completion gate until the large artifacts are gone.
            for entry in version_dir.iterdir():
                if entry.name not in {"state", "logs"}:
                    remove_path(entry)
            for name in ("logs", "state"):
                remove_path(version_dir / name)
            remove_path(version_dir)
        for path, _ in matches:
            path.unlink()
        marker.unlink()
    finally:
        (lock / "owner").unlink(missing_ok=True)
        lock.rmdir()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("version")
    parser.add_argument("--execute", action="store_true", help="remove completed release artifacts")
    args = parser.parse_args()
    if not VERSION_PATTERN.fullmatch(args.version):
        raise CleanupError("version must use x.y.z format")

    default_root = Path(__file__).resolve().parents[4]
    root = Path(os.environ.get("RELEASE_SOURCE_ROOT", default_root)).resolve()
    release_root = root / ".tmp" / "release"
    version_dir = release_root / args.version
    marker = release_root / "asc" / "cleanup" / f"{args.version}.json"
    check_layout(root, release_root, version_dir, marker)

    if not version_dir.exists() and not marker.exists():
        if matching_runs(release_root / "asc" / "runs", args.version):
            raise CleanupError("release directory missing while ASC records still exist")
        print(f"{args.version}: already cleaned")
        return

    if marker.exists():
        receipt = read_json(marker)
        if receipt.get("version") != args.version or not isinstance(receipt.get("run_id"), str):
            raise CleanupError(f"invalid cleanup receipt: {marker}")
        run_id = receipt["run_id"]
    else:
        matches = matching_runs(release_root / "asc" / "runs", args.version)
        _, run = completed_run(matches)
        plan = read_json(version_dir / "state" / "issue-followup" / "plan.json")
        if plan.get("version") != args.version or plan.get("executed") is not True:
            raise CleanupError("Issue follow-up plan has not completed for this version")
        run_id = run.get("run_id")
        if not isinstance(run_id, str) or not run_id:
            raise CleanupError("successful run has no run ID")

    if (release_root / "cache" / "build.lock").exists():
        raise CleanupError("release build cache is locked")
    matches = matching_runs(release_root / "asc" / "runs", args.version)
    if any(run.get("status") not in {"ok", "error", "failed", "cancelled"} for _, run in matches):
        raise CleanupError("another release run for this version is active")
    worktrees = registered_worktrees(root, version_dir) if version_dir.exists() else []
    if version_dir.exists():
        validate_targets(version_dir, worktrees)
    print(f"version: {args.version}; completed publish run: {run_id}")
    print(f"version directory: {version_dir}")
    print(f"estimated version data: {estimated_size_kib(version_dir) / (1024 * 1024):.2f} GiB")
    print(f"registered worktrees: {len(worktrees)}; matching ASC records: {len(matches)}")
    print("cross-version cache: retained")
    if not args.execute:
        print("preview only; pass --execute after saving the release report")
        return

    execute_cleanup(root, release_root, version_dir, marker, args.version, run_id)
    print(f"{args.version}: local release cleanup completed")


if __name__ == "__main__":
    try:
        main()
    except (CleanupError, OSError) as error:
        print(f"cleanup blocked: {error}", file=sys.stderr)
        sys.exit(1)
