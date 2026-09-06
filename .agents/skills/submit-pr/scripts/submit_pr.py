#!/usr/bin/env python3
"""Plan and safely create a GitHub pull request from any Git checkout."""

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


CANONICAL_HEADINGS = (
    "## 变更说明 / Summary",
    "## 关联 Issue / Linked Issues",
    "## 验证 / Verification",
    "## 截图 / Screenshots",
)
# Public alias retained for callers of the first implementation.
REQUIRED_HEADINGS = CANONICAL_HEADINGS
SECTION_ALIASES = (
    {"变更说明 / summary", "summary", "description", "changes"},
    {"关联 issue / linked issues", "linked issues", "related issues", "issues"},
    {"验证 / verification", "verification", "testing", "tests"},
    {"截图 / screenshots", "screenshots", "screenshot"},
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
TEMPLATE_PARENT_DIRECTORIES = ("", "docs", ".github")
TEMPLATE_EXTENSIONS = {".md", ".txt"}


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
    issue_policy: str = "neutral"
    extra_body: str = ""


@dataclass(frozen=True)
class RepositoryInfo:
    name_with_owner: str
    default_branch: str
    is_fork: bool
    parent: str | None

    @property
    def root(self) -> str:
        return self.parent or self.name_with_owner


@dataclass(frozen=True)
class RepositoryContext:
    base_repository: str
    base_remote: str
    base_branch: str
    head_repository: str
    head_remote: str
    default_branch: str

    @property
    def cross_repository(self) -> bool:
        return self.base_repository.casefold() != self.head_repository.casefold()


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


def remote_repositories(repo_root: Path, *, push: bool = False) -> dict[str, str]:
    result: dict[str, str] = {}
    for remote in git_output(repo_root, "remote").splitlines():
        arguments = ["remote", "get-url"]
        if push:
            arguments.append("--push")
        url = git_output(repo_root, *arguments, remote)
        repository = normalize_repository_from_remote(url)
        if repository is not None:
            result[remote] = repository
    if not result:
        raise SubmitPRError("no GitHub remote is configured for this checkout")
    return result


def github_repository_info(repo_root: Path, repository: str) -> RepositoryInfo:
    payload = run_json(
        [
            "gh",
            "repo",
            "view",
            repository,
            "--json",
            "nameWithOwner,defaultBranchRef,isFork,parent",
        ],
        cwd=repo_root,
    )
    if not isinstance(payload, dict):
        raise SubmitPRError(f"gh repo view returned invalid data for {repository}")
    canonical = payload.get("nameWithOwner")
    default_ref = payload.get("defaultBranchRef")
    default_branch = default_ref.get("name") if isinstance(default_ref, dict) else None
    parent_payload = payload.get("parent")
    parent = (
        parent_payload.get("nameWithOwner")
        if isinstance(parent_payload, dict)
        else None
    )
    if not isinstance(canonical, str) or not isinstance(default_branch, str):
        raise SubmitPRError(f"cannot resolve GitHub repository metadata: {repository}")
    return RepositoryInfo(
        canonical,
        default_branch,
        bool(payload.get("isFork")),
        parent if isinstance(parent, str) else None,
    )


def config_value(repo_root: Path, key: str) -> str | None:
    result = git_result(repo_root, "config", "--get", key)
    return result.stdout.strip() if result.returncode == 0 and result.stdout.strip() else None


def select_unique(candidates: Sequence[str], description: str) -> str:
    unique = list(dict.fromkeys(candidates))
    if len(unique) != 1:
        detail = ", ".join(unique) if unique else "none"
        raise SubmitPRError(
            f"cannot determine {description}; candidates: {detail}. "
            "Provide the corresponding explicit option."
        )
    return unique[0]


def current_branch(repo_root: Path) -> str:
    branch = git_output(repo_root, "branch", "--show-current")
    if not branch:
        raise SubmitPRError("detached HEAD is not supported")
    return branch


def resolve_repository_context(
    args: argparse.Namespace,
    repo_root: Path,
) -> RepositoryContext:
    remotes = remote_repositories(repo_root)
    push_remotes = remote_repositories(repo_root, push=True)
    infos = {
        repository: github_repository_info(repo_root, repository)
        for repository in dict.fromkeys([*remotes.values(), *push_remotes.values()])
    }
    requested_repo = args.repo or os.environ.get("GH_REPO")
    if requested_repo:
        base_info = github_repository_info(repo_root, requested_repo)
    else:
        roots = [info.root for info in infos.values()]
        base_repository = select_unique(roots, "base repository (--repo)")
        base_info = next(
            (
                info
                for info in infos.values()
                if info.name_with_owner.casefold() == base_repository.casefold()
            ),
            None,
        )
        if base_info is None:
            base_info = github_repository_info(repo_root, base_repository)
    base_repository = base_info.name_with_owner

    if args.base_remote:
        if remotes.get(args.base_remote, "").casefold() != base_repository.casefold():
            raise SubmitPRError(
                f"--base-remote {args.base_remote!r} does not point to {base_repository}"
            )
        base_remote = args.base_remote
    else:
        base_remote = select_unique(
            [
                remote
                for remote, repository in remotes.items()
                if repository.casefold() == base_repository.casefold()
            ],
            "base remote (--base-remote)",
        )

    current = current_branch(repo_root)
    upstream = config_value(repo_root, f"branch.{current}.remote")
    push_remote = config_value(repo_root, f"branch.{current}.pushRemote")
    remote_default = config_value(repo_root, "remote.pushDefault")
    if args.head_remote:
        head_candidates = [args.head_remote]
    else:
        preferred = [push_remote, remote_default]
        head_candidates = [
            remote
            for remote in preferred
            if remote in push_remotes
            and infos[push_remotes[remote]].root.casefold()
            == base_repository.casefold()
        ]
        if not head_candidates:
            fork_remotes = [
                remote
                for remote, repository in push_remotes.items()
                if infos[repository].root.casefold() == base_repository.casefold()
                and repository.casefold() != base_repository.casefold()
            ]
            head_candidates = fork_remotes
        if not head_candidates and upstream in push_remotes:
            upstream_info = infos[push_remotes[upstream]]
            if upstream_info.root.casefold() == base_repository.casefold():
                head_candidates = [upstream]
        if not head_candidates:
            head_candidates = [base_remote]
    head_remote = select_unique(head_candidates, "head remote (--head-remote)")
    if head_remote not in push_remotes:
        raise SubmitPRError(f"head remote is not a GitHub remote: {head_remote}")
    head_repository = infos[push_remotes[head_remote]]
    if head_repository.root.casefold() != base_repository.casefold():
        raise SubmitPRError(
            f"head repository {head_repository.name_with_owner} is not in the "
            f"{base_repository} fork network"
        )

    base_branch = args.base or config_value(repo_root, f"branch.{current}.gh-merge-base")
    base_branch = base_branch or base_info.default_branch
    return RepositoryContext(
        base_repository,
        base_remote,
        base_branch,
        head_repository.name_with_owner,
        head_remote,
        base_info.default_branch,
    )


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


def section_index(heading: str) -> int | None:
    normalized = heading.strip().removeprefix("##").strip().casefold()
    for index, aliases in enumerate(SECTION_ALIASES):
        if normalized in aliases:
            return index
    return None


def clean_template_body(text: str) -> str:
    text = re.sub(r"<!--[\s\S]*?-->", "", text)
    lines = [line.rstrip() for line in text.strip().splitlines()]
    while lines and not lines[0].strip():
        lines.pop(0)
    while lines and not lines[-1].strip():
        lines.pop()
    if lines == ["-"]:
        return ""
    return "\n".join(lines).strip()


def parse_template(template_text: str) -> tuple[list[str], list[tuple[str, str]]]:
    sections: list[tuple[str, str]] = []
    preamble: list[str] = []
    current_heading: str | None = None
    current_lines: list[str] = []
    for line in template_text.splitlines():
        if line.startswith("## "):
            if current_heading is None:
                preamble = current_lines
            else:
                sections.append((current_heading, "\n".join(current_lines)))
            current_heading = line
            current_lines = []
        else:
            current_lines.append(line)
    if current_heading is None:
        preamble = current_lines
    else:
        sections.append((current_heading, "\n".join(current_lines)))
    return preamble, sections


def render_pr_body(template_text: str, content: PRContent) -> str:
    validate_content(content)
    preamble, template_sections = parse_template(template_text)
    preserved = ["" for _ in CANONICAL_HEADINGS]
    extras: list[str] = []
    seen: set[int] = set()
    for heading, body in template_sections:
        index = section_index(heading)
        cleaned = clean_template_body(body)
        if index is None:
            extras.append(f"{heading}\n\n{cleaned}".rstrip())
            continue
        if index in seen:
            raise SubmitPRError(f"PR template repeats semantic section: {heading}")
        seen.add(index)
        preserved[index] = cleaned

    issue_lines = "\n".join(f"- {issue.strip()}" for issue in content.issues)
    generated = [
        content.summary.strip(),
        issue_lines,
        content.verification.strip(),
        UI_SCREENSHOT_NOTICE if content.ui_change else "N/A",
    ]
    rendered: list[str] = []
    preamble_text = clean_template_body("\n".join(preamble))
    if preamble_text:
        rendered.append(preamble_text)
    for heading, value, template_body in zip(
        CANONICAL_HEADINGS,
        generated,
        preserved,
        strict=True,
    ):
        body_parts = [part for part in (value, template_body) if part]
        rendered.append(f"{heading}\n\n" + "\n\n".join(body_parts))
    rendered.extend(extras)
    if content.extra_body.strip():
        for line in content.extra_body.splitlines():
            if line.startswith("## ") and section_index(line) is not None:
                raise SubmitPRError("extra PR body repeats a canonical section")
        rendered.append(content.extra_body.strip())
    body = "\n\n".join(part.rstrip() for part in rendered if part.strip()) + "\n"
    if content.issue_policy == "forbid" and AUTO_CLOSE_PATTERN.search(body):
        raise SubmitPRError("PR body contains a GitHub auto-closing Issue reference")
    return body


def discover_template(repo_root: Path, requested: str | None) -> tuple[str, str | None]:
    if requested:
        path = Path(requested)
        path = path if path.is_absolute() else repo_root / path
        try:
            return path.read_text(encoding="utf-8"), str(path)
        except OSError as error:
            raise SubmitPRError(f"cannot read PR template: {path}") from error
    candidates: list[Path] = []
    for relative in TEMPLATE_PARENT_DIRECTORIES:
        parent = repo_root / relative
        if not parent.is_dir():
            continue
        for path in sorted(parent.iterdir(), key=lambda item: item.name.casefold()):
            name = path.stem.casefold()
            extension = path.suffix.casefold()
            if (
                path.is_file()
                and name == "pull_request_template"
                and extension in TEMPLATE_EXTENSIONS
            ):
                candidates.append(path)
            elif path.is_dir() and path.name.casefold() == "pull_request_template":
                candidates.extend(
                    sorted(
                        (
                            child
                            for child in path.iterdir()
                            if child.is_file()
                            and child.suffix.casefold() in TEMPLATE_EXTENSIONS
                        ),
                        key=lambda item: item.name.casefold(),
                    )
                )
    existing: list[Path] = []
    seen_files: set[tuple[int, int]] = set()
    for path in candidates:
        if not path.is_file():
            continue
        stat = path.stat()
        identity = (stat.st_dev, stat.st_ino)
        if identity not in seen_files:
            existing.append(path)
            seen_files.add(identity)
    if len(existing) > 1:
        raise SubmitPRError(
            "multiple PR templates found; select one with --template: "
            + ", ".join(str(path.relative_to(repo_root)) for path in existing)
        )
    if existing:
        return existing[0].read_text(encoding="utf-8"), str(existing[0])
    return "\n\n".join(CANONICAL_HEADINGS) + "\n", None


def read_extra_body(repo_root: Path, requested: str | None) -> str:
    if not requested:
        return ""
    if requested == "-":
        return sys.stdin.read()
    path = Path(requested)
    path = path if path.is_absolute() else repo_root / path
    try:
        return path.read_text(encoding="utf-8")
    except OSError as error:
        raise SubmitPRError(f"cannot read extra PR body: {path}") from error


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


def validate_branch_name(repo_root: Path, branch: str) -> None:
    result = git_result(repo_root, "check-ref-format", "--branch", branch)
    if result.returncode != 0:
        raise SubmitPRError(f"invalid head branch name: {branch!r}")
    if BRANCH_PATTERN.fullmatch(branch) is None:
        raise SubmitPRError(
            "head branch must use Conventional <type>/<kebab-case-summary> format"
        )


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
    push_url = git_output(repo_root, "remote", "get-url", "--push", remote)
    result = run_command(
        ["git", "ls-remote", "--heads", push_url, f"refs/heads/{branch}"],
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
        if (local_sha is None or local_sha == head_sha) and (
            remote_sha is None or remote_sha == head_sha
        ):
            return candidate
    raise SubmitPRError("cannot find an available task branch name")


def cached_base_ref(repo_root: Path, remote: str, base: str) -> str:
    ref = f"refs/remotes/{remote}/{base}"
    if git_result(repo_root, "show-ref", "--verify", ref).returncode != 0:
        raise SubmitPRError(
            f"cached base {remote}/{base} is missing; run apply or fetch it explicitly"
        )
    return ref


def ensure_commit_range(
    repo_root: Path,
    context: RepositoryContext,
    issue_policy: str,
) -> tuple[str, list[dict[str, str]], list[str]]:
    base_ref = cached_base_ref(repo_root, context.base_remote, context.base_branch)
    ancestry = git_result(repo_root, "merge-base", "--is-ancestor", base_ref, "HEAD")
    if ancestry.returncode != 0:
        raise SubmitPRError(
            f"HEAD does not contain {context.base_remote}/{context.base_branch}; "
            "automatic merge or rebase is disabled"
        )
    head_sha = git_output(repo_root, "rev-parse", "HEAD")
    hashes_output = git_output(repo_root, "rev-list", "--reverse", f"{base_ref}..HEAD")
    if not hashes_output:
        raise SubmitPRError(
            f"HEAD contains no commits beyond {context.base_remote}/{context.base_branch}"
        )
    commits: list[dict[str, str]] = []
    for commit_hash in hashes_output.splitlines():
        subject = git_output(repo_root, "show", "-s", "--format=%s", commit_hash)
        message = git_output(repo_root, "show", "-s", "--format=%B", commit_hash)
        if issue_policy == "forbid" and AUTO_CLOSE_PATTERN.search(message):
            raise SubmitPRError(
                f"commit {commit_hash} contains a GitHub auto-closing Issue reference"
            )
        commits.append({"hash": commit_hash, "subject": subject})
    files_output = git_output(repo_root, "diff", "--name-only", f"{base_ref}...HEAD")
    return head_sha, commits, files_output.splitlines() if files_output else []


def prepare_content(args: argparse.Namespace, repo_root: Path) -> PRContent:
    return PRContent(
        title=args.title,
        summary=args.summary,
        verification=args.verification,
        issues=tuple(issue.strip() for issue in args.issue),
        ui_change=args.ui_change,
        draft=args.draft,
        issue_policy=args.issue_policy,
        extra_body=read_extra_body(repo_root, args.extra_body_file),
    )


def protected_branches(
    context: RepositoryContext,
    configured: Sequence[str],
) -> set[str]:
    return {
        context.base_branch,
        context.default_branch,
        *(branch for branch in configured if branch),
    }


def resolve_head_branch(
    repo_root: Path,
    current: str,
    protected: set[str],
    requested: str | None,
    head_sha: str,
    remote: str,
    *,
    include_remote: bool,
) -> tuple[str, str]:
    current_is_task = current not in protected and BRANCH_PATTERN.fullmatch(current)
    if current_is_task:
        if requested and requested != current:
            raise SubmitPRError(
                f"--head-branch {requested!r} does not match current branch {current!r}"
            )
        validate_branch_name(repo_root, current)
        return current, "current"
    if not requested:
        raise SubmitPRError(
            "--head-branch is required on a protected or non-Conventional branch"
        )
    selected = choose_branch_name(
        repo_root,
        remote,
        requested,
        head_sha,
        include_remote=include_remote,
    )
    action = "created" if local_branch_sha(repo_root, selected) is None else "reused"
    return selected, action


def build_plan(
    args: argparse.Namespace,
    repo_root: Path,
    context: RepositoryContext,
    *,
    include_remote_branch_check: bool,
) -> tuple[dict[str, Any], str]:
    content = prepare_content(args, repo_root)
    template_text, template_path = discover_template(repo_root, args.template)
    body = render_pr_body(template_text, content)
    branch = current_branch(repo_root)
    status = parse_status(git_status_output(repo_root))
    head_sha, commits, files = ensure_commit_range(
        repo_root,
        context,
        content.issue_policy,
    )
    protected = protected_branches(context, args.protected_branch)
    head_branch, branch_action = resolve_head_branch(
        repo_root,
        branch,
        protected,
        args.head_branch,
        head_sha,
        context.head_remote,
        include_remote=include_remote_branch_check,
    )
    head_owner = context.head_repository.split("/", 1)[0]
    head_query = (
        f"{head_owner}:{head_branch}"
        if context.cross_repository
        else head_branch
    )
    plan = {
        "repository": context.base_repository,
        "base_remote": context.base_remote,
        "base": context.base_branch,
        "head_repository": context.head_repository,
        "head_remote": context.head_remote,
        "head_branch": head_branch,
        "head_query": head_query,
        "is_cross_repository": context.cross_repository,
        "current_branch": branch,
        "head_sha": head_sha,
        "branch_action": branch_action,
        "protected_branches": sorted(protected),
        "draft": content.draft,
        "issue_policy": content.issue_policy,
        "title": content.title.strip(),
        "body": body,
        "template": template_path,
        "commits": commits,
        "files": files,
        "working_tree": status,
        "needs_screenshots": content.ui_change,
    }
    return plan, body


def require_clean_worktree(repo_root: Path) -> None:
    if git_status_output(repo_root):
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
    head_query: str,
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
            head_query,
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
    if git_result(repo_root, "cat-file", "-e", f"{commit_sha}^{{commit}}").returncode == 0:
        return
    push_url = git_output(repo_root, "remote", "get-url", "--push", remote)
    run_command(["git", "fetch", "--no-tags", push_url, commit_sha], cwd=repo_root)


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
        ["git", "push", remote, f"{head_sha}:refs/heads/{remote_branch}"],
        cwd=repo_root,
    )
    pushed_sha = remote_branch_sha(repo_root, remote, remote_branch)
    if pushed_sha != head_sha:
        raise SubmitPRError(
            f"remote branch verification failed: expected {head_sha}, got {pushed_sha}"
        )
    return action


def create_pr(repo_root: Path, plan: dict[str, Any]) -> str:
    descriptor, body_name = tempfile.mkstemp(prefix="submit-pr-", suffix=".md")
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.write(plan["body"])
        command = [
            "gh",
            "pr",
            "create",
            "--repo",
            plan["repository"],
            "--base",
            plan["base"],
            "--head",
            plan["head_query"],
            "--title",
            plan["title"],
            "--body-file",
            body_name,
        ]
        if plan["draft"]:
            command.append("--draft")
        result = run_command(command, cwd=repo_root)
    finally:
        try:
            os.unlink(body_name)
        except FileNotFoundError:
            pass
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
        "isCrossRepository": plan["is_cross_repository"],
    }
    mismatches: list[str] = []
    for field, expected_value in expected.items():
        if pr.get(field) != expected_value:
            mismatches.append(
                f"{field}: expected {expected_value!r}, got {pr.get(field)!r}"
            )
    actual_body = pr.get("body")
    if not isinstance(actual_body, str) or actual_body.rstrip() != plan["body"].rstrip():
        mismatches.append("body differs from the generated PR body")
    if plan["issue_policy"] == "forbid" and pr.get("closingIssuesReferences") != []:
        mismatches.append("closingIssuesReferences is missing or not empty")
    expected_owner, expected_name = plan["head_repository"].split("/", 1)
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
    if mismatches:
        raise SubmitPRError(
            "existing or created PR failed verification:\n- " + "\n- ".join(mismatches)
        )


def plan_command(args: argparse.Namespace, repo_root: Path) -> dict[str, Any]:
    previous_locks = os.environ.get("GIT_OPTIONAL_LOCKS")
    os.environ["GIT_OPTIONAL_LOCKS"] = "0"
    try:
        context = resolve_repository_context(args, repo_root)
        plan, _ = build_plan(
            args,
            repo_root,
            context,
            include_remote_branch_check=False,
        )
    finally:
        if previous_locks is None:
            os.environ.pop("GIT_OPTIONAL_LOCKS", None)
        else:
            os.environ["GIT_OPTIONAL_LOCKS"] = previous_locks
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
    check_github_auth(repo_root)
    context = resolve_repository_context(args, repo_root)
    fetch_base(repo_root, context.base_remote, context.base_branch)
    plan, _ = build_plan(
        args,
        repo_root,
        context,
        include_remote_branch_check=True,
    )
    open_prs = list_open_prs(
        repo_root,
        plan["repository"],
        plan["base"],
        plan["head_query"],
    )
    if len(open_prs) > 1:
        raise SubmitPRError("multiple open PRs exist for the same head/base")
    if open_prs:
        pr = view_pr(repo_root, plan["repository"], str(open_prs[0]["number"]))
        verify_pr(pr, plan)
        push_action = "reused"
        pr_action = "reused"
    else:
        push_action = push_head_branch(
            repo_root,
            plan["head_remote"],
            plan["head_branch"],
            plan["head_sha"],
        )
        pr_url = create_pr(repo_root, plan)
        pr = view_pr(repo_root, plan["repository"], pr_url)
        verify_pr(pr, plan)
        pr_action = "created"
    branch_action = ensure_local_branch(
        repo_root,
        plan["current_branch"],
        plan["head_branch"],
        plan["head_sha"],
    )
    return {
        "mode": "apply",
        "repository": plan["repository"],
        "base_remote": plan["base_remote"],
        "base": plan["base"],
        "head_repository": plan["head_repository"],
        "head_remote": plan["head_remote"],
        "head": plan["head_branch"],
        "head_sha": plan["head_sha"],
        "is_cross_repository": plan["is_cross_repository"],
        "draft": plan["draft"],
        "issue_policy": plan["issue_policy"],
        "branch_action": branch_action,
        "push_action": push_action,
        "pr_action": pr_action,
        "pr_number": pr.get("number"),
        "pr_url": pr.get("url"),
        "needs_screenshots": plan["needs_screenshots"],
    }


def resolve_repo_root(path: str | None) -> Path:
    cwd = Path(path).resolve() if path else Path.cwd()
    result = run_command(["git", "rev-parse", "--show-toplevel"], cwd=cwd)
    return Path(result.stdout.strip()).resolve()


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Plan or submit a GitHub pull request from the current checkout.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)
    for command in ("plan", "apply"):
        subparser = subparsers.add_parser(command)
        subparser.add_argument("--repo")
        subparser.add_argument("--repo-root")
        subparser.add_argument("--base")
        subparser.add_argument("--base-remote")
        subparser.add_argument("--head-remote")
        subparser.add_argument("--head-branch")
        subparser.add_argument("--protected-branch", action="append", default=[])
        subparser.add_argument("--template")
        subparser.add_argument("--extra-body-file")
        subparser.add_argument("--title", required=True)
        subparser.add_argument("--summary", required=True)
        subparser.add_argument("--verification", required=True)
        subparser.add_argument("--issue", action="append", default=[])
        subparser.add_argument(
            "--issue-policy",
            choices=("neutral", "allow", "forbid"),
            default="neutral",
        )
        subparser.add_argument("--ui-change", action="store_true")
        subparser.add_argument("--draft", action="store_true")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        repo_root = resolve_repo_root(args.repo_root)
        result = (
            plan_command(args, repo_root)
            if args.command == "plan"
            else apply_command(args, repo_root)
        )
        print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
        return 0
    except SubmitPRError as error:
        print(f"submit-pr: error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
