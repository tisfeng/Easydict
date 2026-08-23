#!/usr/bin/env python3
"""Render and safely submit an Easydict GitHub pull request."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from typing import Any, Sequence


DEFAULT_REPOSITORY = "tisfeng/Easydict"
DEFAULT_REMOTE = "origin"
DEFAULT_BASE = "dev"
REQUIRED_HEADINGS = (
    "## 变更说明 / Summary",
    "## 关联 Issue / Linked Issues",
    "## 验证 / Verification",
    "## 截图 / Screenshots",
)
UI_SCREENSHOT_NOTICE = (
    "请在 GitHub PR 页面补充截图。 / "
    "Please add screenshots on the GitHub PR page."
)
ISSUE_PATTERNS = (
    re.compile(r"^#[1-9]\d*$"),
    re.compile(
        r"^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/"
        r"issues/[1-9]\d*/?$"
    ),
    re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+#[1-9]\d*$"),
)
AUTO_CLOSE_PATTERN = re.compile(
    r"(?i)\b(?:fix(?:e[sd])?|close[sd]?|resolve[sd]?)\s*:?[ \t]+"
    r"(?:#[1-9]\d*|"
    r"https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/issues/[1-9]\d*|"
    r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+#[1-9]\d*)"
)
CONVENTIONAL_TYPES = (
    "feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert"
)
TITLE_PATTERN = re.compile(
    rf"^(?:{CONVENTIONAL_TYPES})(?:\([a-z0-9][a-z0-9._/-]*\))?!?:\s+\S.*$"
)
BRANCH_PATTERN = re.compile(
    rf"^(?:{CONVENTIONAL_TYPES})/[a-z0-9]+(?:-[a-z0-9]+)*$"
)


class SubmitPRError(RuntimeError):
    """Raised when PR planning or submission is unsafe."""


@dataclass(frozen=True)
class PRContent:
    title: str
    summary: str
    verification: str
    issues: tuple[str, ...]
    ui_change: bool
    draft: bool


def run_command(
    command: Sequence[str],
    *,
    cwd: Path,
    check: bool = True,
) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        list(command),
        cwd=cwd,
        check=False,
        capture_output=True,
        text=True,
    )
    if check and result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise SubmitPRError(
            f"command failed ({result.returncode}): {' '.join(command)}"
            f"\n{detail}"
        )
    return result


def run_json(command: Sequence[str], *, cwd: Path) -> Any:
    result = run_command(command, cwd=cwd)
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise SubmitPRError(
            f"command did not return valid JSON: {' '.join(command)}"
        ) from error


def git_output(repo_root: Path, *arguments: str) -> str:
    return run_command(["git", *arguments], cwd=repo_root).stdout.strip()


def git_result(repo_root: Path, *arguments: str) -> subprocess.CompletedProcess[str]:
    return run_command(["git", *arguments], cwd=repo_root, check=False)


def git_status_output(repo_root: Path) -> str:
    return run_command(
        ["git", "status", "--porcelain=v1"],
        cwd=repo_root,
    ).stdout.rstrip("\n")


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


def normalize_repository_from_remote(remote_url: str) -> str | None:
    patterns = (
        re.compile(r"^git@github\.com:(?P<repo>.+?)(?:\.git)?$"),
        re.compile(r"^ssh://git@github\.com/(?P<repo>.+?)(?:\.git)?$"),
        re.compile(r"^https://github\.com/(?P<repo>.+?)(?:\.git)?/?$"),
    )
    for pattern in patterns:
        match = pattern.match(remote_url.strip())
        if match is not None:
            return match.group("repo").removesuffix(".git").rstrip("/")
    return None


def verify_remote_repository(
    repo_root: Path,
    remote: str,
    repository: str,
) -> str:
    remote_url = git_output(repo_root, "remote", "get-url", remote)
    remote_repository = normalize_repository_from_remote(remote_url)
    if remote_repository is None or remote_repository.casefold() != repository.casefold():
        raise SubmitPRError(
            f"remote {remote!r} points to {remote_url!r}, not {repository!r}"
        )
    return remote_url


def validate_content(content: PRContent) -> None:
    title = content.title.strip()
    if not title or "\n" in title or "\r" in title:
        raise SubmitPRError("PR title must be a non-empty single line")
    if len(title) > 256:
        raise SubmitPRError("PR title exceeds 256 characters")
    if TITLE_PATTERN.fullmatch(title) is None:
        raise SubmitPRError("PR title must use Angular-style type(scope): subject")
    if not content.summary.strip():
        raise SubmitPRError("PR summary must not be empty")
    if not content.verification.strip():
        raise SubmitPRError("PR verification must not be empty")
    if len(set(content.issues)) != len(content.issues):
        raise SubmitPRError("duplicate linked Issue reference")
    for issue in content.issues:
        if not any(pattern.fullmatch(issue.strip()) for pattern in ISSUE_PATTERNS):
            raise SubmitPRError(f"unsupported linked Issue reference: {issue!r}")


def render_pr_body(template_text: str, content: PRContent) -> str:
    validate_content(content)
    lines = template_text.splitlines()
    heading_positions: list[int] = []
    for heading in REQUIRED_HEADINGS:
        positions = [index for index, line in enumerate(lines) if line == heading]
        if len(positions) != 1:
            raise SubmitPRError(
                f"PR template must contain exactly one heading: {heading}"
            )
        heading_positions.append(positions[0])
    if heading_positions != sorted(heading_positions):
        raise SubmitPRError("PR template headings are out of order")

    issue_lines = "\n".join(f"- {issue.strip()}" for issue in content.issues)
    screenshots = UI_SCREENSHOT_NOTICE if content.ui_change else "N/A"
    sections = (
        content.summary.strip(),
        issue_lines,
        content.verification.strip(),
        screenshots,
    )
    rendered_parts: list[str] = []
    for heading, section in zip(REQUIRED_HEADINGS, sections, strict=True):
        rendered_parts.append(f"{heading}\n\n{section}" if section else heading)
    body = "\n\n".join(rendered_parts) + "\n"
    if AUTO_CLOSE_PATTERN.search(body):
        raise SubmitPRError("PR body contains a GitHub auto-closing Issue reference")
    return body


def parse_status(status_text: str) -> dict[str, list[str]]:
    state: dict[str, list[str]] = {
        "staged": [],
        "unstaged": [],
        "untracked": [],
    }
    for line in status_text.splitlines():
        if not line:
            continue
        path = line[3:] if len(line) > 3 else line
        if line.startswith("??"):
            state["untracked"].append(path)
            continue
        if line[0] != " ":
            state["staged"].append(path)
        if len(line) > 1 and line[1] != " ":
            state["unstaged"].append(path)
    return state


def current_branch(repo_root: Path) -> str:
    branch = git_output(repo_root, "branch", "--show-current")
    if not branch:
        raise SubmitPRError("detached HEAD is not supported")
    return branch


def validate_branch_name(repo_root: Path, branch: str) -> None:
    result = git_result(repo_root, "check-ref-format", "--branch", branch)
    if result.returncode != 0:
        raise SubmitPRError(f"invalid head branch name: {branch!r}")
    if BRANCH_PATTERN.fullmatch(branch) is None:
        raise SubmitPRError(
            "head branch must use Conventional <type>/<kebab-case-summary> format"
        )
    if branch in {"main", "dev"} or branch.startswith(("release/", "review/")):
        raise SubmitPRError(f"protected or workflow branch cannot be PR head: {branch}")


def local_branch_sha(repo_root: Path, branch: str) -> str | None:
    result = git_result(
        repo_root,
        "rev-parse",
        "--verify",
        "--quiet",
        f"refs/heads/{branch}",
    )
    if result.returncode == 1:
        return None
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise SubmitPRError(f"cannot inspect local branch {branch}: {detail}")
    return result.stdout.strip()


def remote_branch_sha(repo_root: Path, remote: str, branch: str) -> str | None:
    result = run_command(
        ["git", "ls-remote", "--heads", remote, f"refs/heads/{branch}"],
        cwd=repo_root,
    )
    output = result.stdout.strip()
    return output.split()[0] if output else None


def choose_branch_name(
    repo_root: Path,
    remote: str,
    requested: str,
    head_sha: str,
    *,
    include_remote: bool,
) -> str:
    validate_branch_name(repo_root, requested)
    for suffix in range(1, 101):
        candidate = requested if suffix == 1 else f"{requested}-{suffix}"
        validate_branch_name(repo_root, candidate)
        local_sha = local_branch_sha(repo_root, candidate)
        remote_sha = (
            remote_branch_sha(repo_root, remote, candidate)
            if include_remote
            else None
        )
        local_available = local_sha is None or local_sha == head_sha
        remote_available = remote_sha is None or remote_sha == head_sha
        if local_available and remote_available:
            return candidate
    raise SubmitPRError("cannot find an available task branch name")


def cached_base_ref(repo_root: Path, remote: str, base: str) -> str:
    ref = f"refs/remotes/{remote}/{base}"
    result = git_result(repo_root, "show-ref", "--verify", ref)
    if result.returncode != 0:
        raise SubmitPRError(
            f"cached base {remote}/{base} is missing; run apply or fetch it explicitly"
        )
    return ref


def ensure_commit_range(
    repo_root: Path,
    remote: str,
    base: str,
) -> tuple[str, list[dict[str, str]], list[str]]:
    base_ref = cached_base_ref(repo_root, remote, base)
    ancestry = git_result(repo_root, "merge-base", "--is-ancestor", base_ref, "HEAD")
    if ancestry.returncode != 0:
        raise SubmitPRError(
            f"HEAD does not contain {remote}/{base}; automatic merge or rebase is disabled"
        )
    head_sha = git_output(repo_root, "rev-parse", "HEAD")
    hashes_output = git_output(
        repo_root,
        "rev-list",
        "--reverse",
        f"{base_ref}..HEAD",
    )
    if not hashes_output:
        raise SubmitPRError(f"HEAD contains no commits beyond {remote}/{base}")
    commits = []
    for commit_hash in hashes_output.splitlines():
        subject = git_output(repo_root, "show", "-s", "--format=%s", commit_hash)
        message = git_output(repo_root, "show", "-s", "--format=%B", commit_hash)
        if AUTO_CLOSE_PATTERN.search(message):
            raise SubmitPRError(
                f"commit {commit_hash} contains a GitHub auto-closing Issue reference"
            )
        commits.append({"hash": commit_hash, "subject": subject})
    files_output = git_output(
        repo_root,
        "diff",
        "--name-only",
        f"{base_ref}...HEAD",
    )
    files = files_output.splitlines() if files_output else []
    return head_sha, commits, files


def prepare_content(args: argparse.Namespace) -> PRContent:
    return PRContent(
        title=args.title,
        summary=args.summary,
        verification=args.verification,
        issues=tuple(issue.strip() for issue in args.issue),
        ui_change=args.ui_change,
        draft=args.draft,
    )


def resolve_head_branch(
    repo_root: Path,
    current: str,
    base: str,
    requested: str | None,
    head_sha: str,
    remote: str,
    *,
    include_remote: bool,
) -> tuple[str, str]:
    if current == base:
        if not requested:
            raise SubmitPRError(
                "--head-branch is required when the current branch is the base branch"
            )
        selected = choose_branch_name(
            repo_root,
            remote,
            requested,
            head_sha,
            include_remote=include_remote,
        )
        return selected, "created" if local_branch_sha(repo_root, selected) is None else "reused"
    validate_branch_name(repo_root, current)
    if requested and requested != current:
        raise SubmitPRError(
            f"--head-branch {requested!r} does not match current branch {current!r}"
        )
    return current, "current"


def build_plan(
    args: argparse.Namespace,
    repo_root: Path,
    *,
    include_remote_branch_check: bool,
) -> tuple[dict[str, Any], str]:
    verify_remote_repository(repo_root, args.remote, args.repo)
    content = prepare_content(args)
    template_path = Path(args.template) if args.template else (
        repo_root / ".github" / "pull_request_template.md"
    )
    if not template_path.is_absolute():
        template_path = repo_root / template_path
    try:
        template_text = template_path.read_text(encoding="utf-8")
    except OSError as error:
        raise SubmitPRError(f"cannot read PR template: {template_path}") from error
    body = render_pr_body(template_text, content)
    branch = current_branch(repo_root)
    status = parse_status(git_status_output(repo_root))
    head_sha, commits, files = ensure_commit_range(
        repo_root,
        args.remote,
        args.base,
    )
    head_branch, branch_action = resolve_head_branch(
        repo_root,
        branch,
        args.base,
        args.head_branch,
        head_sha,
        args.remote,
        include_remote=include_remote_branch_check,
    )
    plan = {
        "repository": args.repo,
        "remote": args.remote,
        "base": args.base,
        "current_branch": branch,
        "head_branch": head_branch,
        "head_sha": head_sha,
        "branch_action": branch_action,
        "draft": content.draft,
        "title": content.title.strip(),
        "body": body,
        "commits": commits,
        "files": files,
        "working_tree": status,
        "needs_screenshots": content.ui_change,
    }
    return plan, body


def require_clean_worktree(repo_root: Path) -> None:
    status_text = git_status_output(repo_root)
    if status_text:
        raise SubmitPRError(
            "apply requires a clean working tree; commit staged content and preserve "
            "unstaged or untracked files before submitting the PR"
        )


def fetch_base(repo_root: Path, remote: str, base: str) -> None:
    run_command(
        [
            "git",
            "fetch",
            "--no-tags",
            remote,
            f"refs/heads/{base}:refs/remotes/{remote}/{base}",
        ],
        cwd=repo_root,
    )


def check_github_auth(repo_root: Path) -> None:
    run_command(
        ["gh", "auth", "status", "--hostname", "github.com"],
        cwd=repo_root,
    )


def ensure_local_branch(
    repo_root: Path,
    current: str,
    head_branch: str,
    head_sha: str,
) -> str:
    if current == head_branch:
        return "current"
    existing_sha = local_branch_sha(repo_root, head_branch)
    if existing_sha is None:
        run_command(["git", "branch", head_branch, head_sha], cwd=repo_root)
        return "created"
    if existing_sha != head_sha:
        raise SubmitPRError(
            f"local branch {head_branch} moved after planning: {existing_sha}"
        )
    return "reused"


def list_open_prs(
    repo_root: Path,
    repository: str,
    base: str,
    head: str,
) -> list[dict[str, Any]]:
    payload = run_json(
        [
            "gh",
            "pr",
            "list",
            "--repo",
            repository,
            "--state",
            "open",
            "--base",
            base,
            "--head",
            head,
            "--json",
            "number,title,url,body,baseRefName,headRefName,headRefOid,isDraft,state",
        ],
        cwd=repo_root,
    )
    if not isinstance(payload, list) or not all(
        isinstance(item, dict) for item in payload
    ):
        raise SubmitPRError("gh pr list returned an unexpected payload")
    return payload


def fetch_commit_object(repo_root: Path, remote: str, commit_sha: str) -> None:
    present = git_result(repo_root, "cat-file", "-e", f"{commit_sha}^{{commit}}")
    if present.returncode == 0:
        return
    run_command(
        ["git", "fetch", "--no-tags", remote, commit_sha],
        cwd=repo_root,
    )


def push_head_branch(
    repo_root: Path,
    remote: str,
    remote_branch: str,
    head_sha: str,
) -> str:
    remote_sha = remote_branch_sha(repo_root, remote, remote_branch)
    if remote_sha == head_sha:
        return "reused"
    if remote_sha is not None:
        fetch_commit_object(repo_root, remote, remote_sha)
        ancestry = git_result(
            repo_root,
            "merge-base",
            "--is-ancestor",
            remote_sha,
            head_sha,
        )
        if ancestry.returncode != 0:
            raise SubmitPRError(
                f"remote branch {remote}/{remote_branch} is ahead or diverged; "
                "force push is disabled"
            )
        action = "updated"
    else:
        action = "created"
    run_command(
        [
            "git",
            "push",
            remote,
            f"{head_sha}:refs/heads/{remote_branch}",
        ],
        cwd=repo_root,
    )
    pushed_sha = remote_branch_sha(repo_root, remote, remote_branch)
    if pushed_sha != head_sha:
        raise SubmitPRError(
            f"remote branch verification failed: expected {head_sha}, got {pushed_sha}"
        )
    return action


def create_pr(
    repo_root: Path,
    plan: dict[str, Any],
    body_path: Path,
) -> str:
    command = [
        "gh",
        "pr",
        "create",
        "--repo",
        plan["repository"],
        "--base",
        plan["base"],
        "--head",
        plan["head_branch"],
        "--title",
        plan["title"],
        "--body-file",
        str(body_path),
    ]
    if plan["draft"]:
        command.append("--draft")
    result = run_command(command, cwd=repo_root)
    url = result.stdout.strip().splitlines()[-1] if result.stdout.strip() else ""
    if not url.startswith("https://github.com/"):
        raise SubmitPRError("gh pr create did not return a GitHub PR URL")
    return url


def view_pr(repo_root: Path, repository: str, reference: str) -> dict[str, Any]:
    payload = run_json(
        [
            "gh",
            "pr",
            "view",
            reference,
            "--repo",
            repository,
            "--json",
            "number,title,url,body,baseRefName,headRefName,headRefOid,"
            "headRepository,headRepositoryOwner,isCrossRepository,isDraft,state,"
            "closingIssuesReferences",
        ],
        cwd=repo_root,
    )
    if not isinstance(payload, dict):
        raise SubmitPRError("gh pr view returned an unexpected payload")
    return payload


def verify_pr(pr: dict[str, Any], plan: dict[str, Any]) -> None:
    expected = {
        "state": "OPEN",
        "baseRefName": plan["base"],
        "headRefName": plan["head_branch"],
        "headRefOid": plan["head_sha"],
        "title": plan["title"],
        "isDraft": plan["draft"],
    }
    mismatches = []
    for field, expected_value in expected.items():
        if pr.get(field) != expected_value:
            mismatches.append(
                f"{field}: expected {expected_value!r}, got {pr.get(field)!r}"
            )
    actual_body = pr.get("body")
    if not isinstance(actual_body, str) or actual_body.rstrip() != plan["body"].rstrip():
        mismatches.append("body differs from the generated PR body")
    closing_issues = pr.get("closingIssuesReferences")
    if closing_issues != []:
        mismatches.append("closingIssuesReferences is missing or not empty")
    expected_owner, expected_name = plan["repository"].split("/", 1)
    head_owner = pr.get("headRepositoryOwner")
    actual_owner = head_owner.get("login") if isinstance(head_owner, dict) else None
    if actual_owner != expected_owner:
        mismatches.append(
            f"head repository owner: expected {expected_owner!r}, got {actual_owner!r}"
        )
    head_repository = pr.get("headRepository")
    actual_name = head_repository.get("name") if isinstance(head_repository, dict) else None
    if actual_name != expected_name:
        mismatches.append(
            f"head repository name: expected {expected_name!r}, got {actual_name!r}"
        )
    if pr.get("isCrossRepository") is not False:
        mismatches.append("isCrossRepository is missing or not false")
    if mismatches:
        raise SubmitPRError("existing or created PR failed verification:\n- " + "\n- ".join(mismatches))


def write_apply_state(repo_root: Path, plan: dict[str, Any]) -> tuple[Path, Path]:
    safe_branch = re.sub(r"[^A-Za-z0-9_.-]+", "-", plan["head_branch"]).strip("-")
    state_dir = repo_root / ".tmp" / "submit-pr" / safe_branch
    body_path = state_dir / "body.md"
    plan_path = state_dir / "plan.json"
    atomic_write_text(body_path, plan["body"])
    atomic_write_json(plan_path, plan)
    return body_path, plan_path


def plan_command(args: argparse.Namespace, repo_root: Path) -> dict[str, Any]:
    plan, _ = build_plan(
        args,
        repo_root,
        include_remote_branch_check=False,
    )
    branch_action = plan.pop("branch_action")
    plan["planned_branch_action"] = {
        "created": "would-create",
        "reused": "would-reuse",
        "current": "current",
    }[branch_action]
    plan["mode"] = "plan"
    return plan


def apply_command(args: argparse.Namespace, repo_root: Path) -> dict[str, Any]:
    require_clean_worktree(repo_root)
    verify_remote_repository(repo_root, args.remote, args.repo)
    check_github_auth(repo_root)
    fetch_base(repo_root, args.remote, args.base)
    plan, _ = build_plan(
        args,
        repo_root,
        include_remote_branch_check=True,
    )
    current = plan["current_branch"]
    branch_action = ensure_local_branch(
        repo_root,
        current,
        plan["head_branch"],
        plan["head_sha"],
    )
    plan["branch_action"] = branch_action
    body_path, plan_path = write_apply_state(repo_root, plan)

    open_prs = list_open_prs(
        repo_root,
        plan["repository"],
        plan["base"],
        plan["head_branch"],
    )
    if len(open_prs) > 1:
        raise SubmitPRError("multiple open PRs exist for the same head/base")
    if open_prs:
        pr = view_pr(
            repo_root,
            plan["repository"],
            str(open_prs[0]["number"]),
        )
        verify_pr(pr, plan)
        push_action = "reused"
        pr_action = "reused"
    else:
        push_action = push_head_branch(
            repo_root,
            plan["remote"],
            plan["head_branch"],
            plan["head_sha"],
        )
        pr_url = create_pr(repo_root, plan, body_path)
        pr = view_pr(repo_root, plan["repository"], pr_url)
        verify_pr(pr, plan)
        pr_action = "created"

    result = {
        "mode": "apply",
        "repository": plan["repository"],
        "base": plan["base"],
        "head": plan["head_branch"],
        "head_sha": plan["head_sha"],
        "draft": plan["draft"],
        "branch_action": branch_action,
        "push_action": push_action,
        "pr_action": pr_action,
        "pr_number": pr.get("number"),
        "pr_url": pr.get("url"),
        "needs_screenshots": plan["needs_screenshots"],
        "body_path": str(body_path),
        "plan_path": str(plan_path),
    }
    atomic_write_json(plan_path, {**plan, "result": result})
    return result


def resolve_repo_root(path: str | None) -> Path:
    cwd = Path(path).resolve() if path else Path.cwd()
    result = run_command(
        ["git", "rev-parse", "--show-toplevel"],
        cwd=cwd,
    )
    return Path(result.stdout.strip()).resolve()


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Plan or submit an Easydict GitHub pull request.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)
    for command in ("plan", "apply"):
        subparser = subparsers.add_parser(command)
        subparser.add_argument("--repo", default=DEFAULT_REPOSITORY)
        subparser.add_argument("--remote", default=DEFAULT_REMOTE)
        subparser.add_argument("--base", default=DEFAULT_BASE)
        subparser.add_argument("--repo-root")
        subparser.add_argument("--template")
        subparser.add_argument("--head-branch")
        subparser.add_argument("--title", required=True)
        subparser.add_argument("--summary", required=True)
        subparser.add_argument("--verification", required=True)
        subparser.add_argument("--issue", action="append", default=[])
        subparser.add_argument("--ui-change", action="store_true")
        subparser.add_argument("--draft", action="store_true")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        repo_root = resolve_repo_root(args.repo_root)
        if args.command == "plan":
            result = plan_command(args, repo_root)
        else:
            result = apply_command(args, repo_root)
        print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
        return 0
    except SubmitPRError as error:
        print(f"submit-pr: error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
