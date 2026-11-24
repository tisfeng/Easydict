#!/usr/bin/env python3
"""Plan and safely create a GitHub pull request from any Git checkout."""

from __future__ import annotations

import argparse
from contextlib import contextmanager
from dataclasses import dataclass
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time
from typing import Any, Iterator, Sequence
from urllib.parse import urlsplit


PR_BODY_TEMPLATE_PATH = (
    Path(__file__).resolve().parents[1] / "assets" / "pull_request_template.md"
)
PR_BODY_TEMPLATE_FIELDS = (
    "context",
    "changes",
    "issues",
    "verification",
    "screenshots",
)
PR_BODY_TEMPLATE_PLACEHOLDER = re.compile(r"\{\{(?P<name>[a-z_]+)\}\}")
UI_SCREENSHOT_NOTICE = (
    "请在 GitHub PR 页面补充截图。 / "
    "Please add screenshots on the GitHub PR page."
)
GITHUB_ASSET_URL = r"https://github\.com/user-attachments/assets/[A-Za-z0-9-]+"
IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg"}
ISSUE_PATTERNS = (
    re.compile(r"^#[1-9]\d*$"),
    re.compile(
        r"^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/"
        r"issues/[1-9]\d*/?$"
    ),
    re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+#[1-9]\d*$"),
)
RELATED_PR_PATTERN = re.compile(
    r"https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/pull/[1-9]\d*/?"
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
MINIMUM_PYTHON = (3, 10)


class SubmitPRError(RuntimeError):
    """Raised when PR planning or submission is unsafe."""


def branch_policy():
    """Load the installed git-commit naming dependency, never a host checkout."""

    path = Path(__file__).resolve().parents[2] / "git-commit" / "scripts" / "branch_name.py"
    if not path.is_file():
        raise SubmitPRError("Missing git-commit naming dependency; install the complete git-commit skill beside this skill")
    spec = importlib.util.spec_from_file_location("shared_branch_naming", path)
    module = importlib.util.module_from_spec(spec)
    # Loading policy must not write __pycache__ into a managed skill snapshot.
    exec(compile(path.read_bytes(), str(path), "exec"), module.__dict__)
    return module


def require_supported_python(
    version_info: Sequence[int] = sys.version_info,
) -> None:
    actual = tuple(version_info[:2])
    if actual < MINIMUM_PYTHON:
        required = ".".join(str(part) for part in MINIMUM_PYTHON)
        detected = ".".join(str(part) for part in actual)
        raise SubmitPRError(
            f"Python {required}+ is required; detected {detected}. "
            "Select one compatible interpreter and reuse it for plan and apply."
        )


@contextmanager
def measure_phase(
    timings_ms: dict[str, float],
    name: str,
) -> Iterator[None]:
    started = time.monotonic()
    try:
        yield
    finally:
        timings_ms[name] = round((time.monotonic() - started) * 1000, 3)


@dataclass(frozen=True)
class PRContent:
    title: str
    context: str
    changes: str
    verification: str
    issues: tuple[str, ...]
    ui_change: bool
    draft: bool
    issue_policy: str = "neutral"
    related_prs: tuple[tuple[str, str], ...] = ()
    screenshots: tuple[tuple[str, str], ...] = ()
    screenshots_incomplete: bool = False

    @property
    def needs_screenshots(self) -> bool:
        return self.screenshots_incomplete or (self.ui_change and not self.screenshots)


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
    current_branch: str | None

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


def remote_urls(repo_root: Path, remote: str, *, push: bool = False) -> list[str]:
    arguments = ["remote", "get-url"]
    if push:
        arguments.extend(("--push", "--all"))
    result = git_result(repo_root, *arguments, remote)
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise SubmitPRError(f"cannot inspect remote {remote}: {detail}")
    return list(dict.fromkeys(result.stdout.splitlines()))


def unique_push_url(repo_root: Path, remote: str) -> str:
    urls = remote_urls(repo_root, remote, push=True)
    if len(urls) != 1:
        detail = ", ".join(urls) if urls else "none"
        raise SubmitPRError(
            f"head remote {remote!r} must have exactly one push URL; found: {detail}"
        )
    if normalize_repository_from_remote(urls[0]) is None:
        raise SubmitPRError(f"head remote {remote!r} does not have a GitHub push URL")
    return urls[0]


def remote_repositories(repo_root: Path, *, push: bool = False) -> dict[str, str]:
    result: dict[str, str] = {}
    for remote in git_output(repo_root, "remote").splitlines():
        urls = remote_urls(repo_root, remote, push=push)
        if push and len(urls) > 1:
            detail = ", ".join(urls)
            raise SubmitPRError(
                f"remote {remote!r} has multiple push URLs: {detail}. "
                "Configure one exact push destination before submitting a PR."
            )
        url = urls[0] if urls else ""
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


def current_branch(repo_root: Path) -> str | None:
    branch = git_output(repo_root, "branch", "--show-current")
    return branch or None


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
        base_info = next(
            (
                info
                for repository, info in infos.items()
                if repository.casefold() == requested_repo.casefold()
            ),
            None,
        )
        if base_info is None:
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
    upstream = config_value(repo_root, f"branch.{current}.remote") if current else None
    push_remote = (
        config_value(repo_root, f"branch.{current}.pushRemote") if current else None
    )
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

    configured_base = (
        config_value(repo_root, f"branch.{current}.gh-merge-base")
        if current
        else None
    )
    base_branch = args.base or configured_base
    base_branch = base_branch or base_info.default_branch
    return RepositoryContext(
        base_repository,
        base_remote,
        base_branch,
        head_repository.name_with_owner,
        head_remote,
        base_info.default_branch,
        current,
    )


def validate_content(content: PRContent) -> None:
    title = content.title.strip()
    if not title or "\n" in title or "\r" in title:
        raise SubmitPRError("PR title must be a non-empty single line")
    if len(title) > 256:
        raise SubmitPRError("PR title exceeds 256 characters")
    if TITLE_PATTERN.fullmatch(title) is None:
        raise SubmitPRError("PR title must use Angular-style type(scope): subject")
    if not content.context.strip():
        raise SubmitPRError("PR context must not be empty")
    if not content.changes.strip():
        raise SubmitPRError("PR changes must not be empty")
    if not content.verification.strip():
        raise SubmitPRError("PR verification must not be empty")
    references = set()
    for issue in content.issues:
        validate_single_line(issue.strip(), "linked Issue")
        parts = issue.split(maxsplit=1)
        if not any(pattern.fullmatch(parts[0]) for pattern in ISSUE_PATTERNS):
            raise SubmitPRError(f"unsupported linked Issue reference: {issue!r}")
        reference = parts[0].rstrip("/").casefold()
        if reference in references:
            raise SubmitPRError("duplicate linked Issue reference")
        references.add(reference)
    references.clear()
    for url, relationship in content.related_prs:
        if RELATED_PR_PATTERN.fullmatch(url) is None:
            raise SubmitPRError(f"expected a GitHub pull request URL: {url!r}")
        validate_single_line(relationship, "PR relationship")
        reference = url.rstrip("/").casefold()
        if reference in references:
            raise SubmitPRError("duplicate related PR reference")
        references.add(reference)
    for label, url in content.screenshots:
        validate_single_line(label, "screenshot label")
        try:
            parsed = urlsplit(url)
            valid_url = (
                parsed.scheme == "https"
                and bool(parsed.hostname)
                and parsed.username is None
                and parsed.password is None
            )
        except ValueError:
            valid_url = False
        if not valid_url or re.search(r"[\s\x00-\x1f\x7f<>\\]", url):
            raise SubmitPRError("screenshot URL must be a valid HTTPS image URL")


def validate_single_line(value: str, label: str) -> None:
    if not value.strip() or len(value.splitlines()) != 1 or re.search(r"[\x00-\x1f\x7f]", value):
        raise SubmitPRError(f"{label} must be a non-empty single line")


def load_pr_body_template() -> str:
    try:
        template_text = PR_BODY_TEMPLATE_PATH.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        raise SubmitPRError(
            f"cannot read bundled PR body template: {PR_BODY_TEMPLATE_PATH}"
        ) from error
    placeholders = PR_BODY_TEMPLATE_PLACEHOLDER.findall(template_text)
    if sorted(placeholders) != sorted(PR_BODY_TEMPLATE_FIELDS):
        expected = ", ".join(PR_BODY_TEMPLATE_FIELDS)
        raise SubmitPRError(
            "bundled PR body template must contain each required placeholder "
            f"exactly once: {expected}"
        )
    return template_text


def escape_image_label(label: str) -> str:
    return re.sub(r"([\\\[\]])", r"\\\1", label)


def render_pr_body_parts(
    content: PRContent,
    *,
    attach_on_create: bool = False,
) -> tuple[str, str]:
    """Return the immutable template prefix and its final screenshot section."""
    validate_content(content)
    links = []
    for issue in content.issues:
        parts = issue.split(maxsplit=1)
        links.append("- " + " — ".join(parts))
    links.extend(f"- {url} — {relationship}" for url, relationship in content.related_prs)
    screenshots = []
    for label, url in content.screenshots:
        screenshots.append(f"![{escape_image_label(label)}](<{url}>)")
    if content.screenshots_incomplete or (content.needs_screenshots and not attach_on_create):
        screenshots.append(UI_SCREENSHOT_NOTICE)
    generated = {
        "context": content.context.strip(),
        "changes": content.changes.strip(),
        "issues": "\n".join(links),
        "verification": content.verification.strip(),
    }
    template_prefix, _, suffix = load_pr_body_template().partition("{{screenshots}}")
    if suffix.strip():
        raise SubmitPRError("the screenshot placeholder must end the bundled PR body template")
    prefix = PR_BODY_TEMPLATE_PLACEHOLDER.sub(
        lambda match: generated[match.group("name")],
        template_prefix,
    )
    screenshot_section = "\n\n".join(screenshots)
    if not screenshot_section and not attach_on_create:
        screenshot_section = "N/A"
    if content.issue_policy == "forbid" and AUTO_CLOSE_PATTERN.search(prefix + screenshot_section):
        raise SubmitPRError("PR body contains a GitHub auto-closing Issue reference")
    return prefix, screenshot_section


def render_pr_body(content: PRContent) -> str:
    prefix, screenshots = render_pr_body_parts(content)
    return (prefix + screenshots).rstrip() + "\n"


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
    try:
        branch_policy().validate_literal(branch)
    except (ValueError, OSError) as error:
        raise SubmitPRError(f"invalid head branch name: {branch!r}: {error}") from error


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


def local_branch_action(
    repo_root: Path,
    current: str | None,
    branch: str,
    head_sha: str,
) -> str:
    if current == branch:
        return "current"
    existing_sha = local_branch_sha(repo_root, branch)
    if existing_sha is None:
        return "created"
    if existing_sha == head_sha:
        return "reused"
    ancestry = git_result(
        repo_root,
        "merge-base",
        "--is-ancestor",
        existing_sha,
        head_sha,
    )
    if ancestry.returncode == 0:
        return "updated"
    raise SubmitPRError(
        f"local branch {branch} changed while planning: {existing_sha}"
    )


def remote_branch_sha(
    repo_root: Path,
    remote: str,
    branch: str,
    *,
    push_url: str | None = None,
) -> str | None:
    push_url = push_url or unique_push_url(repo_root, remote)
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
    push_url: str | None = None,
    protected: set[str] | None = None,
) -> str:
    validate_branch_name(repo_root, requested)
    protected = protected or set()
    if requested in protected:
        raise SubmitPRError(f"head branch is protected: {requested!r}")
    for suffix in range(1, 101):
        candidate = branch_policy().candidate_name(requested, suffix)
        if candidate in protected:
            continue
        validate_branch_name(repo_root, candidate)
        local_sha = local_branch_sha(repo_root, candidate)
        remote_sha = (
            remote_branch_sha(
                repo_root,
                remote,
                candidate,
                push_url=push_url,
            )
            if include_remote
            else None
        )
        local_is_compatible = local_sha is None or local_sha == head_sha
        if local_sha is not None and local_sha != head_sha:
            local_is_compatible = (
                git_result(
                    repo_root,
                    "merge-base",
                    "--is-ancestor",
                    local_sha,
                    head_sha,
                ).returncode
                == 0
            )
        remote_is_compatible = remote_sha is None or remote_sha == head_sha
        if remote_sha is not None and remote_sha != head_sha:
            fetch_commit_object(
                repo_root,
                remote,
                remote_sha,
                push_url=push_url,
            )
            remote_is_compatible = (
                git_result(
                    repo_root,
                    "merge-base",
                    "--is-ancestor",
                    remote_sha,
                    head_sha,
                ).returncode
                == 0
            )
        if local_is_compatible and remote_is_compatible:
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
    commit_output = run_command(
        [
            "git",
            "log",
            "--reverse",
            "-z",
            "--format=%H%x00%s%x00%B",
            f"{base_ref}..HEAD",
        ],
        cwd=repo_root,
    ).stdout
    if not commit_output:
        raise SubmitPRError(
            f"HEAD contains no commits beyond {context.base_remote}/{context.base_branch}"
        )
    fields = commit_output.split("\0")
    if fields[-1] == "":
        fields.pop()
    if not fields or len(fields) % 3 != 0:
        raise SubmitPRError("git log returned an unexpected commit payload")
    commits: list[dict[str, str]] = []
    for index in range(0, len(fields), 3):
        commit_hash, subject, message = fields[index : index + 3]
        if issue_policy == "forbid" and AUTO_CLOSE_PATTERN.search(message):
            raise SubmitPRError(
                f"commit {commit_hash} contains a GitHub auto-closing Issue reference"
            )
        commits.append({"hash": commit_hash, "subject": subject})
    files_output = git_output(repo_root, "diff", "--name-only", f"{base_ref}...HEAD")
    return head_sha, commits, files_output.splitlines() if files_output else []


def prepare_content(args: argparse.Namespace) -> PRContent:
    return PRContent(
        title=args.title,
        context=args.context,
        changes=args.changes,
        verification=args.verification,
        issues=tuple(issue.strip() for issue in args.issue),
        ui_change=args.ui_change,
        draft=args.draft,
        issue_policy=args.issue_policy,
        related_prs=tuple((url.strip(), reason.strip()) for url, reason in args.related_pr),
        screenshots=tuple((label.strip(), url.strip()) for label, url in args.screenshot),
        screenshots_incomplete=args.screenshots_incomplete,
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


def protected_branch_description(
    context: RepositoryContext,
    branch: str,
) -> str:
    matches: list[str] = []
    if branch == context.base_branch:
        matches.append(f"PR base {context.base_branch!r}")
    if branch == context.default_branch:
        matches.append(f"repository default {context.default_branch!r}")
    return " and ".join(matches) if matches else "a protected branch"


def preflight_branch_safety(
    repo_root: Path,
    context: RepositoryContext,
    args: argparse.Namespace,
) -> None:
    # This dependency is required even without an explicit --head-branch.
    # Check it before apply can fetch or callers can commit staged changes.
    branch_policy()
    branch = current_branch(repo_root)
    if branch != context.current_branch:
        raise SubmitPRError(
            "checkout branch changed during branch preflight: "
            f"expected {context.current_branch!r}, got {branch!r}"
        )
    if branch in {context.base_branch, context.default_branch}:
        description = protected_branch_description(context, branch)
        raise SubmitPRError(
            f"current branch {branch!r} matches protected {description}; "
            "create and check out a new task branch from the current commit, "
            "then rerun submit-pr. Existing commits will be preserved."
        )

    if args.head_branch:
        validate_branch_name(repo_root, args.head_branch)
        if args.head_branch in protected_branches(context, args.protected_branch):
            description = protected_branch_description(context, args.head_branch)
            raise SubmitPRError(
                f"head branch {args.head_branch!r} matches protected {description}; "
                "choose a different task branch"
            )


def resolve_head_branch(
    repo_root: Path,
    current: str | None,
    protected: set[str],
    requested: str | None,
    head_sha: str,
    remote: str,
    *,
    include_remote: bool,
    push_url: str | None = None,
) -> tuple[str, str]:
    if requested:
        validate_branch_name(repo_root, requested)
        if requested in protected:
            raise SubmitPRError(f"head branch is protected: {requested!r}")
    current_is_task = current is not None and current not in protected and (
        branch_policy().is_task_name(current) or requested == current
    )
    if current_is_task:
        if requested and requested != current:
            raise SubmitPRError(
                f"--head-branch {requested!r} does not match current branch {current!r}"
            )
        validate_branch_name(repo_root, current)
        return current, "current"
    if not requested:
        reason = (
            "when HEAD is detached"
            if current is None
            else "on a protected or non-Conventional branch"
        )
        raise SubmitPRError(f"--head-branch is required {reason}")
    selected = choose_branch_name(
        repo_root,
        remote,
        requested,
        head_sha,
        include_remote=include_remote,
        push_url=push_url,
        protected=protected,
    )
    action = local_branch_action(repo_root, current, selected, head_sha)
    return selected, action


def build_plan(
    args: argparse.Namespace,
    repo_root: Path,
    context: RepositoryContext,
    *,
    include_remote_branch_check: bool,
    push_url: str | None = None,
) -> tuple[dict[str, Any], str]:
    branch = current_branch(repo_root)
    if branch != context.current_branch:
        raise SubmitPRError(
            "checkout branch changed during planning: "
            f"expected {context.current_branch!r}, got {branch!r}"
        )
    preflight_branch_safety(repo_root, context, args)
    content = prepare_content(args)
    body_prefix, screenshots = render_pr_body_parts(content)
    body = (body_prefix + screenshots).rstrip() + "\n"
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
        push_url=push_url,
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
        "body_prefix": body_prefix,
        "commits": commits,
        "files": files,
        "working_tree": status,
        "needs_screenshots": content.needs_screenshots,
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
    current: str | None,
    head_branch: str,
    head_sha: str,
) -> str:
    actual_current = current_branch(repo_root)
    actual_head = git_output(repo_root, "rev-parse", "HEAD")
    if actual_current != current or actual_head != head_sha:
        raise SubmitPRError(
            "checkout changed after planning: "
            f"expected branch {current!r} at {head_sha}, "
            f"got {actual_current!r} at {actual_head}"
        )
    if current == head_branch:
        return "current"
    existing_sha = local_branch_sha(repo_root, head_branch)
    if existing_sha is None:
        run_command(["git", "branch", head_branch, head_sha], cwd=repo_root)
        return "created"
    if existing_sha == head_sha:
        return "reused"
    ancestry = git_result(
        repo_root,
        "merge-base",
        "--is-ancestor",
        existing_sha,
        head_sha,
    )
    if ancestry.returncode != 0:
        raise SubmitPRError(
            f"local branch {head_branch} moved after planning: {existing_sha}"
        )
    run_command(["git", "branch", "-f", head_branch, head_sha], cwd=repo_root)
    return "updated"


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
            "number,title,url,body,baseRefName,headRefName,headRefOid,"
            "headRepository,headRepositoryOwner,isCrossRepository,isDraft,state,"
            "closingIssuesReferences",
        ],
        cwd=repo_root,
    )
    if not isinstance(payload, list) or not all(
        isinstance(item, dict) for item in payload
    ):
        raise SubmitPRError("gh pr list returned an unexpected payload")
    return payload


def fetch_commit_object(
    repo_root: Path,
    remote: str,
    commit_sha: str,
    *,
    push_url: str | None = None,
) -> None:
    if git_result(repo_root, "cat-file", "-e", f"{commit_sha}^{{commit}}").returncode == 0:
        return
    push_url = push_url or unique_push_url(repo_root, remote)
    run_command(["git", "fetch", "--no-tags", push_url, commit_sha], cwd=repo_root)


def push_head_branch(
    repo_root: Path,
    remote: str,
    remote_branch: str,
    head_sha: str,
    *,
    push_url: str | None = None,
) -> str:
    push_url = push_url or unique_push_url(repo_root, remote)
    remote_sha = remote_branch_sha(
        repo_root,
        remote,
        remote_branch,
        push_url=push_url,
    )
    if remote_sha == head_sha:
        return "reused"
    if remote_sha is not None:
        fetch_commit_object(
            repo_root,
            remote,
            remote_sha,
            push_url=push_url,
        )
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
        ["git", "push", push_url, f"{head_sha}:refs/heads/{remote_branch}"],
        cwd=repo_root,
    )
    pushed_sha = remote_branch_sha(
        repo_root,
        remote,
        remote_branch,
        push_url=push_url,
    )
    if pushed_sha != head_sha:
        raise SubmitPRError(
            f"remote branch verification failed: expected {head_sha}, got {pushed_sha}"
        )
    return action


def screenshot_files(args: argparse.Namespace) -> tuple[tuple[str, Path], ...]:
    files = tuple((label.strip(), Path(path).absolute()) for label, path in args.screenshot_file)
    if len(files) > 50:
        raise SubmitPRError("--screenshot-file accepts at most 50 images")
    for label, path in files:
        validate_single_line(label, "screenshot label")
        if args.issue_policy == "forbid" and AUTO_CLOSE_PATTERN.search(label):
            raise SubmitPRError("screenshot label contains a GitHub auto-closing Issue reference")
        if path.suffix.lower() not in IMAGE_EXTENSIONS:
            raise SubmitPRError(f"unsupported screenshot file type: {path}")
    if len({label for label, _ in files}) != len(files):
        raise SubmitPRError("--screenshot-file labels must be distinct")
    return files


def validate_creation_attachments(repo_root: Path, files: Sequence[tuple[str, Path]]) -> None:
    if len({path.resolve() for _, path in files}) != len(files):
        raise SubmitPRError("the same screenshot file cannot be attached twice")
    for _, path in files:
        if not path.is_file():
            raise SubmitPRError(f"screenshot file is not accessible: {path}")
    help_text = run_command(["gh", "pr", "create", "--help"], cwd=repo_root).stdout
    if "--attach" not in help_text:
        raise SubmitPRError(
            "this GitHub CLI does not support gh pr create --attach; "
            "upgrade gh or upload the screenshots in GitHub and pass their URLs"
        )


def read_creation_attachments(
    pr: dict[str, Any],
    upload_body: str,
    files: Sequence[tuple[str, Path]],
    content: PRContent,
) -> list[dict[str, str]]:
    """Accept only the ordered image suffix GitHub CLI can append to the frozen body."""
    body = pr.get("body")
    prefix = upload_body.rstrip() + "\n\n"
    if not isinstance(body, str) or not body.startswith(prefix):
        raise SubmitPRError("PR body differs from the planned body for screenshot creation")
    paragraphs = body[len(prefix):].rstrip().split("\n\n")
    if len(paragraphs) > len(files):
        raise SubmitPRError("PR body contains more attachments than requested")
    urls = {url for _, url in content.screenshots}
    uploaded = []
    for paragraph, (label, _) in zip(paragraphs, files):
        alt = re.escape(escape_image_label(label))
        match = re.fullmatch(rf"!\[{alt}\]\(({GITHUB_ASSET_URL})\)", paragraph)
        if not match or match[1] in urls:
            raise SubmitPRError(f"PR body does not contain the expected GitHub attachment for {label!r}")
        urls.add(match[1])
        uploaded.append({"label": label, "url": match[1]})
    return uploaded


def create_pr(
    repo_root: Path,
    plan: dict[str, Any],
    body: str,
    files: Sequence[tuple[str, Path]],
) -> tuple[str, str]:
    with tempfile.TemporaryDirectory(prefix="submit-pr-") as directory:
        body_file = Path(directory) / "body.md"
        body_file.write_text(body, encoding="utf-8")
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
            str(body_file),
        ]
        if plan["draft"]:
            command.append("--draft")
        for index, (label, path) in enumerate(files, start=1):
            # Keep original file paths out of Markdown's attachment rewrite scope.
            staged_image = Path(directory) / f"screenshot-{index}{path.suffix.lower()}"
            try:
                shutil.copyfile(path, staged_image)
            except OSError as error:
                raise SubmitPRError(f"cannot prepare screenshot {path}: {error}") from error
            command.extend(("--attach", f"{staged_image}#{label}"))
        result = run_command(command, cwd=repo_root, check=not files)
    url = result.stdout.strip().splitlines()[-1] if result.stdout.strip() else ""
    repository = re.escape(plan["repository"])
    if not re.fullmatch(rf"https://github\.com/{repository}/pull/[1-9]\d*", url):
        detail = result.stderr.strip()
        raise SubmitPRError(
            "gh pr create did not return a PR URL for the target repository; "
            f"check for an existing PR before retrying{': ' + detail if detail else ''}"
        )
    return url, result.stderr.strip() if result.returncode else ""


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


def verify_pr(
    pr: dict[str, Any],
    plan: dict[str, Any],
    *,
    require_head_sha: bool = True,
    allow_cli_image_syntax: bool = False,
) -> None:
    expected = {
        "state": "OPEN",
        "baseRefName": plan["base"],
        "headRefName": plan["head_branch"],
        "title": plan["title"],
        "isDraft": plan["draft"],
        "isCrossRepository": plan["is_cross_repository"],
    }
    if require_head_sha:
        expected["headRefOid"] = plan["head_sha"]
    mismatches: list[str] = []
    for field, expected_value in expected.items():
        if pr.get(field) != expected_value:
            mismatches.append(
                f"{field}: expected {expected_value!r}, got {pr.get(field)!r}"
            )
    actual_body = pr.get("body")
    if (
        allow_cli_image_syntax
        and isinstance(actual_body, str)
        and actual_body.startswith(plan["body_prefix"])
    ):
        prefix = plan["body_prefix"]
        screenshots = re.sub(
            rf"^(!\[(?:\\.|[^\]\\\n])*\])\(({GITHUB_ASSET_URL})\)$",
            r"\1(<\2>)",
            actual_body[len(prefix):],
            flags=re.MULTILINE,
        )
        paragraphs = screenshots.rstrip().split("\n\n")
        if paragraphs.count(UI_SCREENSHOT_NOTICE) == 1:
            paragraphs.remove(UI_SCREENSHOT_NOTICE)
            paragraphs.append(UI_SCREENSHOT_NOTICE)
        actual_body = prefix + "\n\n".join(paragraphs)
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


def pr_verification_receipt(pr: dict[str, Any]) -> dict[str, Any]:
    body = pr.get("body")
    if not isinstance(body, str):
        raise SubmitPRError("verified PR body is missing from the final payload")
    return {
        "status": "passed",
        "state": pr.get("state"),
        "title": pr.get("title"),
        "body_sha256": hashlib.sha256(body.encode("utf-8")).hexdigest(),
        "head_sha": pr.get("headRefOid"),
    }


def plan_from_apply_receipt(
    args: argparse.Namespace,
    repo_root: Path,
) -> dict[str, Any]:
    """Render and optionally verify against the original delivery's identity."""
    try:
        receipt = json.loads(Path(args.apply_receipt).read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        raise SubmitPRError(f"cannot read apply receipt: {error}") from error
    if not isinstance(receipt, dict) or receipt.get("mode") != "apply":
        raise SubmitPRError("--apply-receipt requires the JSON output of a successful apply")
    verification = receipt.get("pr_verification")
    number = receipt.get("pr_number")
    head_sha = receipt.get("head_sha")
    repository = receipt.get("repository")
    head_repository = receipt.get("head_repository")
    if (
        not isinstance(verification, dict)
        or verification.get("status") != "passed"
        or type(number) is not int
        or number < 1
        or not isinstance(head_sha, str)
        or re.fullmatch(r"[0-9a-f]{40}|[0-9a-f]{64}", head_sha) is None
        or verification.get("head_sha") != head_sha
        or not all(
            isinstance(value, str) and re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", value)
            for value in (repository, head_repository)
        )
        or receipt.get("pr_url") != f"https://github.com/{repository}/pull/{number}"
        or not all(isinstance(receipt.get(key), str) and receipt[key] for key in ("base", "head"))
    ):
        raise SubmitPRError("apply receipt is missing a verified PR identity or head SHA")
    if args.verify_pr is not None and args.verify_pr != number:
        raise SubmitPRError("--verify-pr must match the PR number in the apply receipt")
    topology = {
        "repo": "repository",
        "base": "base",
        "base_remote": "base_remote",
        "head_branch": "head",
        "head_remote": "head_remote",
    }
    for option, key in topology.items():
        value = getattr(args, option)
        if value is not None and value != receipt.get(key):
            raise SubmitPRError(f"--{option.replace('_', '-')} must match the apply receipt")

    content = prepare_content(args)
    if (
        content.title.strip() != verification.get("title")
        or content.draft is not receipt.get("draft")
        or content.issue_policy != receipt.get("issue_policy")
    ):
        raise SubmitPRError("title, Draft state, and Issue policy must match the apply receipt")
    body_prefix, screenshots = render_pr_body_parts(content)
    non_screenshot_sha256 = receipt.get("non_screenshot_sha256")
    if non_screenshot_sha256 is None:
        raise SubmitPRError("apply receipt lacks a non-screenshot body digest; use an updated apply receipt")
    if hashlib.sha256(body_prefix.encode("utf-8")).hexdigest() != non_screenshot_sha256:
        raise SubmitPRError("non-screenshot PR body differs from the original apply receipt")
    plan = {
        "mode": "plan",
        "repository": repository,
        "base": receipt["base"],
        "head_repository": head_repository,
        "head_branch": receipt["head"],
        "head_sha": head_sha,
        "pr_number": number,
        "pr_url": receipt["pr_url"],
        "is_cross_repository": repository.casefold() != head_repository.casefold(),
        "draft": content.draft,
        "issue_policy": content.issue_policy,
        "title": content.title.strip(),
        "body": (body_prefix + screenshots).rstrip() + "\n",
        "body_prefix": body_prefix,
        "needs_screenshots": content.needs_screenshots,
    }
    if args.verify_pr is not None:
        pr = view_pr(repo_root, repository, str(number))
        if pr.get("number") != number or pr.get("url") != plan["pr_url"]:
            raise SubmitPRError("gh pr view returned a different PR than the apply receipt")
        verify_pr(pr, plan, allow_cli_image_syntax=True)
        plan["pr_verification"] = pr_verification_receipt(pr)
    del plan["body_prefix"]
    return plan


def plan_command(args: argparse.Namespace, repo_root: Path) -> dict[str, Any]:
    if args.apply_receipt is not None:
        return plan_from_apply_receipt(args, repo_root)
    if args.verify_pr is not None:
        raise SubmitPRError("--verify-pr requires --apply-receipt from the original delivery")
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
        "updated": "would-update",
        "reused": "would-reuse",
        "current": "current",
    }[branch_action]
    plan["mode"] = "plan"
    del plan["body_prefix"]
    return plan


def preflight_command(args: argparse.Namespace, repo_root: Path) -> dict[str, Any]:
    previous_locks = os.environ.get("GIT_OPTIONAL_LOCKS")
    os.environ["GIT_OPTIONAL_LOCKS"] = "0"
    try:
        context = resolve_repository_context(args, repo_root)
        preflight_branch_safety(repo_root, context, args)
    finally:
        if previous_locks is None:
            os.environ.pop("GIT_OPTIONAL_LOCKS", None)
        else:
            os.environ["GIT_OPTIONAL_LOCKS"] = previous_locks
    return {
        "mode": "preflight",
        "repository": context.base_repository,
        "base_remote": context.base_remote,
        "base": context.base_branch,
        "default_branch": context.default_branch,
        "head_repository": context.head_repository,
        "head_remote": context.head_remote,
        "head_branch": args.head_branch,
        "current_branch": context.current_branch,
        "protected_branches": sorted(
            protected_branches(context, args.protected_branch)
        ),
        "status": "passed",
    }


def apply_command(args: argparse.Namespace, repo_root: Path) -> dict[str, Any]:
    started = time.monotonic()
    timings_ms: dict[str, float] = {}
    files = screenshot_files(args)
    content = prepare_content(args)
    uploaded: list[dict[str, str]] = []
    attachment_warning = ""
    with measure_phase(timings_ms, "worktree_check"):
        require_clean_worktree(repo_root)
    with measure_phase(timings_ms, "github_auth"):
        check_github_auth(repo_root)
    with measure_phase(timings_ms, "topology"):
        context = resolve_repository_context(args, repo_root)
        preflight_branch_safety(repo_root, context, args)
        push_url = unique_push_url(repo_root, context.head_remote)
    with measure_phase(timings_ms, "fetch_base"):
        fetch_base(repo_root, context.base_remote, context.base_branch)
    with measure_phase(timings_ms, "plan_revalidation"):
        plan, _ = build_plan(
            args,
            repo_root,
            context,
            include_remote_branch_check=True,
            push_url=push_url,
        )
    with measure_phase(timings_ms, "existing_pr_lookup"):
        open_prs = list_open_prs(
            repo_root,
            plan["repository"],
            plan["base"],
            plan["head_query"],
        )
    if len(open_prs) > 1:
        raise SubmitPRError("multiple open PRs exist for the same head/base")
    upload_body = plan["body"]
    if files:
        prefix, screenshots = render_pr_body_parts(content, attach_on_create=True)
        upload_body = (prefix + screenshots).rstrip() + "\n"
        if not open_prs:
            validate_creation_attachments(repo_root, files)
    if open_prs:
        with measure_phase(timings_ms, "existing_pr_validation"):
            existing_body = open_prs[0].get("body")
            if files and (
                not isinstance(existing_body, str) or existing_body.rstrip() != plan["body"].rstrip()
            ):
                uploaded = read_creation_attachments(open_prs[0], upload_body, files, content)
                plan["body"] = open_prs[0]["body"]
            verify_pr(open_prs[0], plan, require_head_sha=bool(files))
    with measure_phase(timings_ms, "local_branch"):
        branch_action = ensure_local_branch(
            repo_root,
            plan["current_branch"],
            plan["head_branch"],
            plan["head_sha"],
        )
    with measure_phase(timings_ms, "push"):
        push_action = push_head_branch(
            repo_root,
            plan["head_remote"],
            plan["head_branch"],
            plan["head_sha"],
            push_url=push_url,
        )
    if open_prs:
        pr_reference = str(open_prs[0]["number"])
        pr_action = "reused"
    else:
        with measure_phase(timings_ms, "pr_create"):
            pr_reference, attachment_warning = create_pr(repo_root, plan, upload_body, files)
        pr_action = "created"
    with measure_phase(timings_ms, "final_pr_verification"):
        pr = view_pr(repo_root, plan["repository"], pr_reference)
        if pr_action == "created" and files:
            if pr.get("url") != pr_reference:
                raise SubmitPRError("gh pr view returned a different PR than gh pr create")
            uploaded = read_creation_attachments(pr, upload_body, files, content)
            plan["body"] = pr["body"]
        verify_pr(pr, plan)
    timings_ms["total"] = round((time.monotonic() - started) * 1000, 3)
    result = {
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
        "pr_verification": pr_verification_receipt(pr),
        "non_screenshot_sha256": hashlib.sha256(plan["body_prefix"].encode("utf-8")).hexdigest(),
        "timings_ms": timings_ms,
        "needs_screenshots": plan["needs_screenshots"],
    }
    if files:
        missing = [label for label, _ in files[len(uploaded):]]
        result["uploaded_screenshots"] = uploaded
        result["missing_screenshots"] = missing
        result["needs_screenshots"] = content.screenshots_incomplete or bool(missing)
        if attachment_warning:
            result["attachment_warning"] = attachment_warning
    return result


def resolve_repo_root(path: str | None) -> Path:
    cwd = Path(path).resolve() if path else Path.cwd()
    result = run_command(["git", "rev-parse", "--show-toplevel"], cwd=cwd)
    return Path(result.stdout.strip()).resolve()


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Preflight, plan, or submit a GitHub pull request from the current checkout."
        ),
    )
    subparsers = parser.add_subparsers(dest="command", required=True)
    for command in ("preflight", "plan", "apply"):
        subparser = subparsers.add_parser(command)
        subparser.add_argument("--repo")
        subparser.add_argument("--repo-root")
        subparser.add_argument("--base")
        subparser.add_argument("--base-remote")
        subparser.add_argument("--head-remote")
        subparser.add_argument("--head-branch")
        subparser.add_argument("--protected-branch", action="append", default=[])
        if command == "preflight":
            continue
        subparser.add_argument("--title", required=True)
        subparser.add_argument("--context", required=True)
        subparser.add_argument("--changes", required=True)
        subparser.add_argument("--verification", required=True)
        subparser.add_argument("--issue", action="append", default=[], metavar="REF [RELATION]")
        subparser.add_argument(
            "--related-pr", action="append", nargs=2, default=[], metavar=("URL", "RELATION"),
        )
        subparser.add_argument(
            "--issue-policy",
            choices=("neutral", "allow", "forbid"),
            default="neutral",
        )
        subparser.add_argument("--ui-change", action="store_true")
        subparser.add_argument(
            "--screenshot", action="append", nargs=2, default=[], metavar=("LABEL", "URL"),
        )
        subparser.add_argument("--screenshots-incomplete", action="store_true")
        if command == "plan":
            subparser.add_argument("--verify-pr", type=int, metavar="NUMBER")
            subparser.add_argument("--apply-receipt", metavar="PATH")
        else:
            subparser.add_argument(
                "--screenshot-file", action="append", nargs=2, default=[], metavar=("LABEL", "PATH"),
            )
        subparser.add_argument("--draft", action="store_true")
    return parser


def main() -> int:
    try:
        require_supported_python()
        args = build_parser().parse_args()
        repo_root = resolve_repo_root(args.repo_root)
        if args.command == "preflight":
            result = preflight_command(args, repo_root)
        elif args.command == "plan":
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
