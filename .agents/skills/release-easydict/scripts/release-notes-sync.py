#!/usr/bin/env python3
"""Preview or synchronize one canonical release-notes Markdown file."""

from __future__ import annotations

import argparse
import base64
import copy
from datetime import datetime, timezone
import difflib
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from urllib.parse import urlsplit
import xml.etree.ElementTree as ET
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))
from release_notes import (  # noqa: E402
    VERSION_PATTERN,
    normalize_body,
    notes_sha256,
    read_notes,
    render_markdown,
)


SPARKLE_NS = "http://www.andymatuschak.org/xml-namespaces/sparkle"
SPARKLE_VERSION = f"{{{SPARKLE_NS}}}version"
SPARKLE_SHORT_VERSION = f"{{{SPARKLE_NS}}}shortVersionString"
ET.register_namespace("sparkle", SPARKLE_NS)

REMOTE_NAME = "origin"
MAIN_BRANCH = "main"
DEV_BRANCH = "dev"
SYNC_BRANCHES = (MAIN_BRANCH, DEV_BRANCH)


class NotesSyncError(RuntimeError):
    """Raised when release-notes synchronization cannot proceed safely."""


def sha256_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def now_utc() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def parse_json_output(result: subprocess.CompletedProcess[str]) -> dict[str, Any]:
    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise NotesSyncError("GitHub API response is not valid JSON") from error
    if not isinstance(payload, dict):
        raise NotesSyncError("GitHub API response is not a JSON object")
    return payload


def parse_included_response(
    result: subprocess.CompletedProcess[str],
) -> tuple[dict[str, str], dict[str, Any]]:
    """Parse `gh api --include` output into headers and its JSON body."""
    raw = result.stdout.replace("\r\n", "\n")
    separator = "\n\n"
    if separator not in raw:
        raise NotesSyncError("GitHub API response did not include headers")
    header_text, body = raw.rsplit(separator, 1)
    headers: dict[str, str] = {}
    for line in header_text.splitlines()[1:]:
        if ":" in line:
            name, value = line.split(":", 1)
            headers[name.strip().lower()] = value.strip()
    try:
        payload = json.loads(body)
    except json.JSONDecodeError as error:
        raise NotesSyncError("GitHub API response body is not valid JSON") from error
    if not isinstance(payload, dict):
        raise NotesSyncError("GitHub API response body is not a JSON object")
    return headers, payload


def fetch_release(repo: str, version: str) -> tuple[dict[str, Any], str]:
    result = run_command(
        ["gh", "api", "--include", f"repos/{repo}/releases/tags/{version}"]
    )
    headers, release = parse_included_response(result)
    if release.get("tag_name") != version:
        raise NotesSyncError(f"GitHub Release tag does not match {version}")
    if release.get("draft") is True:
        raise NotesSyncError(
            f"GitHub Release {version} is still a Draft; use the Draft workflow"
        )
    if not isinstance(release.get("id"), int):
        raise NotesSyncError("GitHub Release database ID is missing")
    etag = headers.get("etag", "")
    if not etag:
        raise NotesSyncError("GitHub Release response did not include an ETag")
    return release, etag


def fetch_appcast(repo: str, branch: str) -> tuple[dict[str, Any], bytes]:
    result = run_command(
        [
            "gh",
            "api",
            "-H",
            "Accept: application/vnd.github+json",
            f"repos/{repo}/contents/appcast.xml?ref={branch}",
        ]
    )
    payload = parse_json_output(result)
    if payload.get("encoding") != "base64" or not isinstance(payload.get("content"), str):
        raise NotesSyncError("remote appcast content is not base64 encoded")
    sha = payload.get("sha")
    if not isinstance(sha, str) or not sha:
        raise NotesSyncError("remote appcast blob SHA is missing")
    try:
        content = base64.b64decode(payload["content"], validate=False)
    except (ValueError, TypeError) as error:
        raise NotesSyncError("remote appcast content is not valid base64") from error
    return payload, content


def fetch_branch_head(repo: str, branch: str) -> str:
    payload = parse_json_output(
        run_command(
            [
                "gh",
                "api",
                "-H",
                "Accept: application/vnd.github+json",
                f"repos/{repo}/git/ref/heads/{branch}",
            ]
        )
    )
    object_payload = payload.get("object")
    if not isinstance(object_payload, dict) or not isinstance(
        object_payload.get("sha"), str
    ):
        raise NotesSyncError(f"remote {branch} branch head is missing")
    return object_payload["sha"]


def fetch_branch_snapshot(repo: str, branch: str) -> dict[str, Any]:
    head_before = fetch_branch_head(repo, branch)
    payload, content = fetch_appcast(repo, branch)
    head_after = fetch_branch_head(repo, branch)
    if head_before != head_after:
        raise NotesSyncError(f"remote {branch} changed while reading appcast")
    return {
        "branch": branch,
        "head": head_after,
        "appcast_sha": payload["sha"],
        "appcast_content": content,
        "appcast_content_sha256": hashlib.sha256(content).hexdigest(),
    }


def parse_appcast(content: bytes) -> ET.ElementTree:
    try:
        return ET.ElementTree(ET.fromstring(content))
    except ET.ParseError as error:
        raise NotesSyncError(f"remote appcast is invalid XML: {error}") from error


def target_items(tree: ET.ElementTree, version: str) -> list[ET.Element]:
    return [
        item
        for item in tree.getroot().findall("./channel/item")
        if item.findtext(SPARKLE_SHORT_VERSION) == version
    ]


def target_item(tree: ET.ElementTree, version: str) -> ET.Element:
    items = target_items(tree, version)
    if len(items) != 1:
        raise NotesSyncError(
            f"appcast must contain exactly one {version} item; found {len(items)}"
        )
    return items[0]


def write_appcast(tree: ET.ElementTree) -> bytes:
    ET.indent(tree, space="    ")
    with tempfile.NamedTemporaryFile() as temporary:
        tree.write(
            temporary.name,
            encoding="UTF-8",
            xml_declaration=True,
            short_empty_elements=True,
        )
        temporary.seek(0)
        contents = temporary.read().decode("UTF-8")
    _, separator, body = contents.partition("\n")
    if not separator:
        body = contents
    declaration = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
    return (declaration + body).encode("UTF-8")


def canonical_item_without_description(item: ET.Element) -> bytes:
    clone = copy.deepcopy(item)
    for element in clone.iter():
        if element.text is not None and not element.text.strip():
            element.text = None
        if element.tail is not None and not element.tail.strip():
            element.tail = None
    description = clone.find("description")
    if description is not None:
        clone.remove(description)
    return ET.tostring(clone, encoding="UTF-8")


def build_appcast_candidate(
    original: bytes, version: str, description: str
) -> tuple[bytes, str]:
    original_tree = parse_appcast(original)
    original_target = target_item(original_tree, version)
    build = original_target.findtext(SPARKLE_VERSION)
    if not build:
        raise NotesSyncError(f"appcast {version} item has no Sparkle build number")
    candidate_tree = parse_appcast(original)
    candidate_target = target_item(candidate_tree, version)
    description_element = candidate_target.find("description")
    if description_element is None:
        description_element = ET.Element("description")
        children = list(candidate_target)
        publication_date = candidate_target.find("pubDate")
        insert_index = (
            children.index(publication_date) + 1
            if publication_date is not None
            else 0
        )
        candidate_target.insert(insert_index, description_element)
    description_element.text = description

    original_items = original_tree.getroot().findall("./channel/item")
    candidate_items = candidate_tree.getroot().findall("./channel/item")
    if len(original_items) != len(candidate_items):
        raise NotesSyncError("appcast item count changed while preparing candidate")
    for original_item, candidate_item in zip(original_items, candidate_items):
        original_without_description = canonical_item_without_description(original_item)
        candidate_without_description = canonical_item_without_description(candidate_item)
        if original_without_description != candidate_without_description:
            raise NotesSyncError("candidate changed appcast fields outside description")
    candidate = write_appcast(candidate_tree)
    return candidate, build


def git_root() -> Path:
    result = run_command(["git", "rev-parse", "--show-toplevel"])
    return Path(result.stdout.strip()).resolve()


def validate_notes_checkout(notes_file: Path, require_clean: bool) -> Path:
    root = git_root()
    notes_path = notes_file.resolve()
    try:
        relative = notes_path.relative_to(root)
    except ValueError as error:
        raise NotesSyncError("release notes must be inside the current Git worktree") from error
    run_command(["git", "ls-files", "--error-unmatch", "--", str(relative)])
    if require_clean:
        status = run_command(["git", "status", "--porcelain", "--untracked-files=all"])
        if status.stdout.strip():
            raise NotesSyncError("sync-notes --execute requires a clean Git worktree")
    return root


def atomic_write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.", dir=path.parent, text=True
    )
    try:
        with os.fdopen(descriptor, "w", encoding="UTF-8") as handle:
            json.dump(payload, handle, ensure_ascii=False, indent=2, sort_keys=True)
            handle.write("\n")
        os.replace(temporary_name, path)
    except Exception:
        try:
            os.unlink(temporary_name)
        except FileNotFoundError:
            pass
        raise


def sync_state_path(root: Path, version: str, requested: Path | None) -> Path:
    if requested is not None:
        return requested.resolve()
    return root / ".tmp" / "release" / version / "state" / "notes-sync.json"


def release_body_matches(current: str, notes: str) -> bool:
    return normalize_body(current) == normalize_body(notes)


def build_branch_preview(
    version: str,
    snapshot: dict[str, Any],
    rendered: str,
) -> dict[str, Any]:
    candidate, build = build_appcast_candidate(
        snapshot["appcast_content"], version, rendered
    )
    current_description = (
        target_item(parse_appcast(snapshot["appcast_content"]), version).findtext(
            "description"
        )
        or ""
    )
    return {
        "branch": snapshot["branch"],
        "head": snapshot["head"],
        "appcast_sha": snapshot["appcast_sha"],
        "appcast_build": build,
        "appcast_update_required": current_description != rendered,
        "appcast_before_sha256": snapshot["appcast_content_sha256"],
        "appcast_candidate_sha256": hashlib.sha256(candidate).hexdigest(),
    }


def build_preview(
    repo: str,
    version: str,
    release: dict[str, Any],
    snapshots: dict[str, dict[str, Any]],
    local_branches: dict[str, str],
    notes: str,
    rendered: str,
) -> dict[str, Any]:
    release_body = normalize_body(notes)
    current_body = release.get("body") or ""
    diff = list(
        difflib.unified_diff(
            current_body.splitlines(),
            release_body.splitlines(),
            fromfile="github-release",
            tofile=f"changelog/{version}.md",
            lineterm="",
        )
    )
    preview = {
        "repo": repo,
        "version": version,
        "release_id": release["id"],
        "release_url": release.get("html_url"),
        "release_draft": release.get("draft"),
        "release_prerelease": release.get("prerelease"),
        "release_body_sha256": sha256_text(normalize_body(current_body)),
        "release_notes_sha256": notes_sha256(notes),
        "release_update_required": not release_body_matches(current_body, notes),
        "release_diff": diff,
        "targets": {
            branch: build_branch_preview(version, snapshot, rendered)
            for branch, snapshot in snapshots.items()
        },
        "local": {
            "branches": local_branches,
            "dev_update_required": local_branches[DEV_BRANCH]
            != snapshots[DEV_BRANCH]["head"],
            "main_update_required": local_branches[MAIN_BRANCH]
            != snapshots[MAIN_BRANCH]["head"],
        },
        "state": "preview",
    }
    return preview


def update_release_body(repo: str, release: dict[str, Any], etag: str, body: str) -> None:
    endpoint = f"repos/{repo}/releases/{release['id']}"
    payload = json.dumps({"body": body}, ensure_ascii=False)
    run_command(
        [
            "gh",
            "api",
            "--method",
            "PATCH",
            "--header",
            f"If-Match: {etag}",
            "--input",
            "-",
            endpoint,
        ],
        payload,
    )


def run_command(
    command: list[str],
    input_text: str | None = None,
) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        command,
        check=False,
        input=input_text,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise NotesSyncError(f"command failed: {' '.join(command)}\n{detail}")
    return result


def git_command(root: Path, arguments: list[str]) -> subprocess.CompletedProcess[str]:
    return run_command(["git", "-C", str(root), *arguments])


def git_probe(root: Path, arguments: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", "-C", str(root), *arguments],
        check=False,
        capture_output=True,
        text=True,
    )


def git_output(root: Path, arguments: list[str]) -> str:
    return git_command(root, arguments).stdout.strip()


def local_branch_heads(root: Path) -> dict[str, str]:
    return {
        branch: git_output(root, ["rev-parse", f"refs/heads/{branch}"])
        for branch in SYNC_BRANCHES
    }


def fetch_git_branches(root: Path) -> None:
    git_command(
        root,
        [
            "fetch",
            "--quiet",
            REMOTE_NAME,
            "+refs/heads/main:refs/remotes/origin/main",
            "+refs/heads/dev:refs/remotes/origin/dev",
        ],
    )


def validate_origin_repository(root: Path, repo: str) -> None:
    remote_url = git_output(root, ["remote", "get-url", REMOTE_NAME])
    if remote_url.startswith("git@"):
        authority, separator, remote_path = remote_url.partition(":")
        remote_host = authority.rsplit("@", 1)[-1]
        if not separator:
            remote_path = ""
    else:
        parsed = urlsplit(remote_url)
        remote_host = parsed.hostname or ""
        remote_path = parsed.path
    if remote_host.lower() != "github.com":
        raise NotesSyncError(
            f"origin remote is not a GitHub repository; cannot sync {repo} safely"
        )
    remote_repo = remote_path.strip("/").removesuffix(".git")
    if remote_repo.lower() != repo.lower():
        raise NotesSyncError(
            f"origin remote {remote_repo} does not match requested repository {repo}"
        )


def verify_fetched_heads(root: Path, snapshots: dict[str, dict[str, Any]]) -> None:
    for branch, snapshot in snapshots.items():
        fetched = git_output(root, ["rev-parse", f"refs/remotes/{REMOTE_NAME}/{branch}"])
        if fetched != snapshot["head"]:
            raise NotesSyncError(
                f"remote {branch} changed while preparing sync; rerun sync-notes"
            )


def branch_worktree(root: Path, branch: str) -> Path | None:
    output = git_output(root, ["worktree", "list", "--porcelain"])
    for block in output.split("\n\n"):
        lines = block.splitlines()
        if f"branch refs/heads/{branch}" in lines:
            for line in lines:
                if line.startswith("worktree "):
                    return Path(line.removeprefix("worktree "))
    return None


def ensure_clean_worktree(path: Path, label: str) -> None:
    status = run_command(
        ["git", "-C", str(path), "status", "--porcelain", "--untracked-files=all"]
    )
    if status.stdout.strip():
        raise NotesSyncError(f"local {label} worktree must be clean: {path}")


def validate_local_update_ready(root: Path, branch: str, old_head: str) -> None:
    path = branch_worktree(root, branch)
    if path is None:
        return
    current = git_output(path, ["rev-parse", "HEAD"])
    if current != old_head:
        raise NotesSyncError(f"local {branch} changed while preparing sync")
    ensure_clean_worktree(path, branch)


def create_sync_worktree(root: Path, version: str, base: str) -> Path:
    parent = root / ".tmp" / "release" / version / "state"
    parent.mkdir(parents=True, exist_ok=True)
    path = Path(tempfile.mkdtemp(prefix="notes-sync-", dir=parent))
    path.rmdir()
    try:
        git_command(root, ["worktree", "add", "--detach", str(path), base])
    except Exception:
        path.exists() and path.rmdir()
        raise
    return path


def remove_sync_worktree(root: Path, path: Path) -> None:
    git_command(root, ["worktree", "remove", "--force", str(path)])


def make_main_commit(
    worktree: Path, base: str, candidate: bytes, version: str
) -> tuple[str, bool]:
    appcast_path = worktree / "appcast.xml"
    if not appcast_path.is_file():
        raise NotesSyncError("main branch does not contain appcast.xml")
    if appcast_path.read_bytes() == candidate:
        return base, False
    appcast_path.write_bytes(candidate)
    git_command(worktree, ["add", "--", "appcast.xml"])
    git_command(worktree, ["commit", "-m", f"chore(release): sync {version} release notes"])
    return git_output(worktree, ["rev-parse", "HEAD"]), True


def merge_commit(worktree: Path, commit: str, label: str) -> str:
    current = git_output(worktree, ["rev-parse", "HEAD"])
    if git_probe(worktree, ["merge-base", "--is-ancestor", commit, current]).returncode == 0:
        return current
    if git_probe(worktree, ["merge-base", "--is-ancestor", current, commit]).returncode == 0:
        git_command(worktree, ["merge", "--ff-only", commit])
        return commit
    try:
        git_command(worktree, ["merge", "--no-edit", "--no-ff", commit])
    except NotesSyncError as error:
        raise NotesSyncError(f"merge conflict while integrating {label}: {error}") from error
    return git_output(worktree, ["rev-parse", "HEAD"])


def push_branches(
    root: Path,
    old_heads: dict[str, str],
    new_heads: dict[str, str],
) -> None:
    if all(old_heads[branch] == new_heads[branch] for branch in SYNC_BRANCHES):
        return
    arguments = ["push", "--atomic"]
    for branch in SYNC_BRANCHES:
        arguments.append(
            f"--force-with-lease=refs/heads/{branch}:{old_heads[branch]}"
        )
    arguments.extend(
        [
            REMOTE_NAME,
            f"{new_heads[MAIN_BRANCH]}:refs/heads/{MAIN_BRANCH}",
            f"{new_heads[DEV_BRANCH]}:refs/heads/{DEV_BRANCH}",
        ]
    )
    git_command(root, arguments)


def update_local_branch(root: Path, branch: str, old_head: str, new_head: str) -> None:
    if old_head == new_head:
        return
    if git_probe(root, ["merge-base", "--is-ancestor", old_head, new_head]).returncode != 0:
        raise NotesSyncError(f"local {branch} cannot fast-forward to synchronized commit")
    path = branch_worktree(root, branch)
    if path is not None:
        current_head = git_output(path, ["rev-parse", "HEAD"])
        if current_head != old_head:
            raise NotesSyncError(f"local {branch} changed before fast-forward")
        ensure_clean_worktree(path, branch)
        git_command(path, ["merge", "--ff-only", new_head])
    else:
        git_command(root, ["update-ref", f"refs/heads/{branch}", new_head, old_head])


def validate_local_fast_forward(
    root: Path, branch: str, old_head: str, new_head: str
) -> None:
    if old_head == new_head:
        return
    if git_probe(root, ["merge-base", "--is-ancestor", old_head, new_head]).returncode != 0:
        raise NotesSyncError(
            f"local {branch} cannot fast-forward to synchronized commit; resolve it before syncing"
        )


def verify_remote(
    repo: str,
    version: str,
    notes: str,
    rendered: str,
    expected_heads: dict[str, str],
) -> dict[str, Any]:
    release, _ = fetch_release(repo, version)
    if not release_body_matches(release.get("body") or "", notes):
        raise NotesSyncError("GitHub Release body does not match canonical changelog")
    branches: dict[str, Any] = {}
    for branch in SYNC_BRANCHES:
        snapshot = fetch_branch_snapshot(repo, branch)
        if snapshot["head"] != expected_heads[branch]:
            raise NotesSyncError(f"remote {branch} did not reach synchronized commit")
        item = target_item(parse_appcast(snapshot["appcast_content"]), version)
        if (item.findtext("description") or "") != rendered:
            raise NotesSyncError(
                f"remote {branch} appcast description does not match rendered changelog"
            )
        branches[branch] = {
            "head": snapshot["head"],
            "appcast_sha": snapshot["appcast_sha"],
            "appcast_sha256": snapshot["appcast_content_sha256"],
        }
    return {
        "release_body_sha256": sha256_text(normalize_body(release.get("body") or "")),
        "branches": branches,
    }


def prepare_git_sync(
    root: Path,
    version: str,
    snapshots: dict[str, dict[str, Any]],
    local_branches: dict[str, str],
    rendered: str,
) -> dict[str, Any]:
    fetch_git_branches(root)
    verify_fetched_heads(root, snapshots)
    for branch in SYNC_BRANCHES:
        validate_local_update_ready(root, branch, local_branches[branch])

    temporary_worktrees: list[Path] = []
    try:
        main_worktree = create_sync_worktree(
            root, version, f"refs/remotes/{REMOTE_NAME}/{MAIN_BRANCH}"
        )
        temporary_worktrees.append(main_worktree)
        if (main_worktree / "appcast.xml").read_bytes() != snapshots[MAIN_BRANCH]["appcast_content"]:
            raise NotesSyncError(
                "Git main appcast differs from GitHub Contents; rerun sync-notes"
            )
        main_candidate, _ = build_appcast_candidate(
            snapshots[MAIN_BRANCH]["appcast_content"], version, rendered
        )
        main_commit, _ = make_main_commit(
            main_worktree,
            snapshots[MAIN_BRANCH]["head"],
            main_candidate,
            version,
        )

        dev_worktree = create_sync_worktree(root, version, local_branches[DEV_BRANCH])
        temporary_worktrees.append(dev_worktree)
        merge_commit(
            dev_worktree,
            git_output(root, ["rev-parse", f"refs/remotes/{REMOTE_NAME}/{DEV_BRANCH}"]),
            f"remote {DEV_BRANCH}",
        )
        merge_commit(dev_worktree, main_commit, f"{MAIN_BRANCH} appcast")
        merged_appcast = (dev_worktree / "appcast.xml").read_bytes()
        dev_candidate, _ = build_appcast_candidate(merged_appcast, version, rendered)
        if dev_candidate != main_candidate:
            raise NotesSyncError(
                "integrated dev appcast differs from main candidate; reconcile the feeds before syncing"
            )
        if merged_appcast != dev_candidate:
            (dev_worktree / "appcast.xml").write_bytes(dev_candidate)
            git_command(dev_worktree, ["add", "--", "appcast.xml"])
            git_command(
                dev_worktree,
                ["commit", "-m", f"chore(release): sync {version} release notes"],
            )
        dev_commit = git_output(dev_worktree, ["rev-parse", "HEAD"])
        return {
            "temporary_worktrees": temporary_worktrees,
            "new_heads": {MAIN_BRANCH: main_commit, DEV_BRANCH: dev_commit},
            "remote_main_updated": main_commit != snapshots[MAIN_BRANCH]["head"],
            "remote_dev_updated": dev_commit != snapshots[DEV_BRANCH]["head"],
            "local_main_updated": main_commit != local_branches[MAIN_BRANCH],
            "local_dev_updated": dev_commit != local_branches[DEV_BRANCH],
        }
    except Exception:
        for worktree in reversed(temporary_worktrees):
            if worktree.exists():
                try:
                    remove_sync_worktree(root, worktree)
                except NotesSyncError:
                    pass
        raise


def sync_notes(args: argparse.Namespace) -> None:
    if not VERSION_PATTERN.fullmatch(args.version):
        raise NotesSyncError("version must use x.y.z format")
    notes_file = args.notes_file.resolve()
    root = validate_notes_checkout(notes_file, args.execute)
    notes = read_notes(notes_file, args.version)
    rendered = render_markdown(notes)
    release, etag = fetch_release(args.repo, args.version)
    snapshots = {
        branch: fetch_branch_snapshot(args.repo, branch) for branch in SYNC_BRANCHES
    }
    local_branches = local_branch_heads(root)
    preview = build_preview(
        args.repo,
        args.version,
        release,
        snapshots,
        local_branches,
        notes,
        rendered,
    )
    state_path = sync_state_path(root, args.version, args.state)
    state = {
        "schema_version": 2,
        "updated_at": now_utc(),
        "notes_file": str(notes_file.relative_to(root)),
        "notes_sha256": notes_sha256(notes),
        "html_sha256": sha256_text(rendered),
        "preview": preview,
    }
    atomic_write_json(state_path, state)
    if not args.execute:
        print(json.dumps(preview, ensure_ascii=False, indent=2, sort_keys=True))
        return

    body = normalize_body(notes)
    stage = "git-preparation"
    temporary_worktrees: list[Path] = []
    try:
        validate_origin_repository(root, args.repo)
        git_plan = prepare_git_sync(
            root, args.version, snapshots, local_branches, rendered
        )
        temporary_worktrees = git_plan["temporary_worktrees"]
        new_heads = git_plan["new_heads"]
        remote_main_updated = git_plan["remote_main_updated"]
        remote_dev_updated = git_plan["remote_dev_updated"]
        local_main_updated = git_plan["local_main_updated"]
        local_dev_updated = git_plan["local_dev_updated"]
        state.update(
            {
                "updated_at": now_utc(),
                "status": "prepared",
                "prepared_heads": new_heads,
            }
        )
        atomic_write_json(state_path, state)

        for branch in SYNC_BRANCHES:
            validate_local_fast_forward(
                root,
                branch,
                local_branches[branch],
                new_heads[branch],
            )

        stage = "git-push"
        fetch_git_branches(root)
        verify_fetched_heads(root, snapshots)
        push_branches(
            root,
            {branch: snapshots[branch]["head"] for branch in SYNC_BRANCHES},
            new_heads,
        )
        state.update(
            {
                "updated_at": now_utc(),
                "status": "remote-git-updated",
                "remote_heads": new_heads,
            }
        )
        atomic_write_json(state_path, state)

        stage = "local-update"
        update_local_branch(
            root, MAIN_BRANCH, local_branches[MAIN_BRANCH], new_heads[MAIN_BRANCH]
        )
        update_local_branch(
            root, DEV_BRANCH, local_branches[DEV_BRANCH], new_heads[DEV_BRANCH]
        )

        stage = "release"
        if preview["release_update_required"]:
            update_release_body(args.repo, release, etag, body)

        stage = "verification"
        verification = verify_remote(
            args.repo, args.version, notes, rendered, new_heads
        )
    except NotesSyncError as error:
        state.update(
            {
                "updated_at": now_utc(),
                "status": "failed",
                "failed_stage": stage,
                "error": str(error),
            }
        )
        atomic_write_json(state_path, state)
        raise
    finally:
        for worktree in reversed(temporary_worktrees):
            if worktree.exists():
                try:
                    remove_sync_worktree(root, worktree)
                except NotesSyncError as cleanup_error:
                    print(
                        f"warning: failed to remove temporary worktree {worktree}: {cleanup_error}",
                        file=sys.stderr,
                    )

    state.update(
        {
            "updated_at": now_utc(),
            "status": "completed",
            "verification": verification,
            "release_updated": preview["release_update_required"],
            "remote_main_updated": remote_main_updated,
            "remote_dev_updated": remote_dev_updated,
            "local_main_updated": local_main_updated,
            "local_dev_updated": local_dev_updated,
            "remote_heads": new_heads,
        }
    )
    atomic_write_json(state_path, state)
    print(json.dumps(state, ensure_ascii=False, indent=2, sort_keys=True))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("version")
    parser.add_argument("--repo", default="tisfeng/Easydict")
    parser.add_argument("--notes-file", type=Path)
    parser.add_argument("--state", type=Path)
    parser.add_argument(
        "--execute",
        action="store_true",
        help="write the GitHub Release body, remote main/dev appcasts, and local branches",
    )
    return parser


def main() -> int:
    args = build_parser().parse_args()
    if args.notes_file is None:
        args.notes_file = Path("changelog") / f"{args.version}.md"
    try:
        sync_notes(args)
    except (NotesSyncError, OSError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
