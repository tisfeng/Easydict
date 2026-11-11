#!/usr/bin/env python3
"""Finish a verified ASC publication and retain its receipt after cleanup."""

import argparse
import fcntl
from functools import partial
from pathlib import Path
import re
import subprocess
import sys

from release_issues import (
    ReleaseIssueError,
    atomic_write_json,
    read_json,
    render_summary,
    stable_hash,
)


SCRIPTS = Path(__file__).resolve().parent
ROOT = SCRIPTS.parents[3]
RELEASE_ROOT = ROOT / ".tmp" / "release"
RUNS = RELEASE_ROOT / "asc" / "runs"
RECEIPTS = RELEASE_ROOT / "asc" / "completion"


def run_locked(lock, script, *args):
    subprocess.run(
        [sys.executable, str(SCRIPTS / script), *args],
        cwd=ROOT,
        check=True,
        pass_fds=(lock.fileno(),),
    )


def verified_run(run_id):
    path = RUNS / f"{run_id}.json"
    try:
        record = read_json(path)
    except ReleaseIssueError as error:
        if isinstance(error.__cause__, FileNotFoundError):
            return None
        raise
    if record.get("status") != "ok" or record.get("dry_run"):
        return None
    if record.get("run_id") != run_id or record.get("workflow") != run_id.split("-", 1)[0]:
        raise ReleaseIssueError("ASC run identity does not match")
    passed = {step["name"] for step in record["steps"].values() if step["status"] == "ok"}
    if not {"verify_remote_release", "cleanup_release_worktree"} <= passed:
        raise ReleaseIssueError("ASC run lacks final remote verification or worktree cleanup")
    return record


def finish_followup(version, channel, repo, run):
    state = RELEASE_ROOT / version / "state" / "issue-followup"
    state.mkdir(parents=True, exist_ok=True)
    content = state / "release-content.json"
    candidates = state / "candidates.json"
    decisions = state / "decisions.json"
    plan = state / "plan.json"

    if not candidates.exists():
        if not content.exists():
            run("release_content.py", "capture", "--repo", repo, "--version", version,
                "--output", content)
        run("release_issues.py", "collect", "--repo", repo, "--version", version,
            "--content", content, "--output", candidates)

    source = read_json(candidates)
    if source.get("source_sha256") != stable_hash(source):
        raise ReleaseIssueError("follow-up candidate snapshot failed its integrity check")
    if not decisions.exists():
        if source["candidates"]:
            raise ReleaseIssueError(
                f"Issue 跟进等待证据决策。请按 issue-followup-policy.md 审阅 "
                f"{candidates} 并生成 {decisions}"
            )
        atomic_write_json(decisions, {
            "schema_version": source["schema_version"],
            "source_sha256": source["source_sha256"],
            "decisions": [],
        })

    if plan.exists():
        saved = read_json(plan)
        if (saved.get("repository"), saved.get("version"), saved.get("channel"),
                saved.get("source_sha256"), saved.get("decision_sha256"),
                saved.get("plan_sha256")) != (
                repo, version, channel, source["source_sha256"],
                stable_hash(read_json(decisions)), stable_hash(saved)):
            raise ReleaseIssueError("frozen follow-up plan does not match its inputs")
        if saved.get("executed") is True:
            return saved

    args = [
        "--repo", repo, "--version", version, "--channel", channel,
        "--candidates", candidates, "--decisions", decisions, "--plan", plan,
        "--summary", state / "summary.md", "--state", state / "actions.json",
    ]
    if not plan.exists():
        run("release_issues.py", "apply", *args)
    run("release_issues.py", "apply", *args, "--execute")
    return read_json(plan)


def complete(run_id, repo):
    path = RECEIPTS / f"{run_id}.json"
    receipt = read_json(path) if path.exists() else None
    if receipt is None:
        record = verified_run(run_id)
        if record is None:
            # Another process may have removed the ASC record during cleanup.
            if not path.exists():
                return 3  # The ASC workflow still needs to run or resume.
            receipt = read_json(path)
        else:
            version = record["params"]["VERSION"]
            channel = record["params"].get("CHANNEL", "beta")
    if receipt is not None:
        version = receipt["version"]
        channel = receipt["channel"]
        if receipt["run_id"] != run_id or receipt["repository"] != repo:
            raise ReleaseIssueError("completion receipt identity does not match")

    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version) or channel not in {"beta", "stable"}:
        raise ReleaseIssueError("invalid version or channel in release state")

    RECEIPTS.mkdir(parents=True, exist_ok=True)
    with (RECEIPTS / f"{version}.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        run = partial(run_locked, lock)
        if path.exists():
            receipt = read_json(path)
            if receipt["repository"] != repo:
                raise ReleaseIssueError("completion receipt repository does not match")
        if receipt is None:
            plan = finish_followup(version, channel, repo, run)
            receipt = {
                "run_id": run_id,
                "version": version,
                "channel": channel,
                "repository": repo,
                "url": plan["release"]["url"],
                "title": plan["release"]["name"] or version,
                "notes": f"changelog/{version}.md",
                "summary": render_summary(plan),
                "cleanup_completed": False,
            }
            atomic_write_json(path, receipt)

        if not receipt["cleanup_completed"]:
            run("release-cleanup.py", version)
            run("release-cleanup.py", version, "--execute")
            receipt["cleanup_completed"] = True
            atomic_write_json(path, receipt)

    print(f"Easydict {version} ({channel}) 发布完成")
    print(f"{receipt['title']} · {receipt['url']}")
    print(receipt["summary"])
    print(f"更新日志：{receipt['notes']}")
    print(f"运行 ID：{run_id}")
    print(f"本地归档已清理。完成记录：{path}")
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("run_id")
    parser.add_argument("--repo", required=True)
    args = parser.parse_args()
    if not re.fullmatch(r"(publish|release)-[A-Za-z0-9_.-]+", args.run_id):
        parser.error("invalid publication run ID")
    try:
        return complete(args.run_id, args.repo)
    except (ReleaseIssueError, OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        print(f"发布收尾尚未完成：{error}", file=sys.stderr)
        print(f"恢复命令：release-easydict.sh resume {args.run_id}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
