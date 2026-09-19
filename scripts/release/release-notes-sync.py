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


class NotesSyncError(RuntimeError):
    """Raised when release-notes synchronization cannot proceed safely."""


def sha256_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def now_utc() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def run_command(
    command: list[str], input_text: str | None = None
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


def build_preview(
    repo: str,
    version: str,
    appcast_branch: str,
    release: dict[str, Any],
    appcast_payload: dict[str, Any],
    appcast_content: bytes,
    notes: str,
    rendered: str,
) -> dict[str, Any]:
    candidate, build = build_appcast_candidate(
        appcast_content, version, rendered
    )
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
        "appcast_branch": appcast_branch,
        "appcast_sha": appcast_payload["sha"],
        "appcast_build": build,
        "appcast_update_required": (
            target_item(parse_appcast(appcast_content), version).findtext("description")
            or ""
        )
        != rendered,
        "appcast_before_sha256": hashlib.sha256(appcast_content).hexdigest(),
        "appcast_candidate_sha256": hashlib.sha256(candidate).hexdigest(),
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


def update_appcast(repo: str, branch: str, sha: str, content: bytes, version: str) -> None:
    payload = json.dumps(
        {
            "message": f"chore(release): sync {version} release notes",
            "content": base64.b64encode(content).decode("ascii"),
            "sha": sha,
            "branch": branch,
        }
    )
    run_command(
        [
            "gh",
            "api",
            "--method",
            "PUT",
            "-H",
            "Accept: application/vnd.github+json",
            "--input",
            "-",
            f"repos/{repo}/contents/appcast.xml",
        ],
        payload,
    )


def verify_remote(
    repo: str,
    version: str,
    appcast_branch: str,
    notes: str,
    rendered: str,
) -> dict[str, Any]:
    release, _ = fetch_release(repo, version)
    if not release_body_matches(release.get("body") or "", notes):
        raise NotesSyncError("GitHub Release body does not match canonical changelog")
    appcast_payload, appcast_content = fetch_appcast(repo, appcast_branch)
    tree = parse_appcast(appcast_content)
    item = target_item(tree, version)
    description = item.findtext("description") or ""
    if description != rendered:
        raise NotesSyncError("remote appcast description does not match rendered changelog")
    return {
        "release_body_sha256": sha256_text(normalize_body(release.get("body") or "")),
        "appcast_sha": appcast_payload["sha"],
        "appcast_sha256": hashlib.sha256(appcast_content).hexdigest(),
    }


def sync_notes(args: argparse.Namespace) -> None:
    if not VERSION_PATTERN.fullmatch(args.version):
        raise NotesSyncError("version must use x.y.z format")
    notes_file = args.notes_file.resolve()
    root = validate_notes_checkout(notes_file, args.execute)
    notes = read_notes(notes_file, args.version)
    rendered = render_markdown(notes)
    release, etag = fetch_release(args.repo, args.version)
    appcast_payload, appcast_content = fetch_appcast(args.repo, args.appcast_branch)
    preview = build_preview(
        args.repo,
        args.version,
        args.appcast_branch,
        release,
        appcast_payload,
        appcast_content,
        notes,
        rendered,
    )
    state_path = sync_state_path(root, args.version, args.state)
    state = {
        "schema_version": 1,
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
    stage = "release"
    try:
        if preview["release_update_required"]:
            update_release_body(args.repo, release, etag, body)

        stage = "appcast"
        current_appcast_payload, current_appcast = fetch_appcast(
            args.repo, args.appcast_branch
        )
        if current_appcast_payload["sha"] != preview["appcast_sha"]:
            raise NotesSyncError(
                "remote appcast changed after preview; rerun sync-notes to refresh the SHA"
            )
        current_tree = parse_appcast(current_appcast)
        current_description = target_item(current_tree, args.version).findtext(
            "description"
        ) or ""
        appcast_updated = current_description != rendered
        if appcast_updated:
            current_candidate, _ = build_appcast_candidate(
                current_appcast, args.version, rendered
            )
            update_appcast(
                args.repo,
                args.appcast_branch,
                current_appcast_payload["sha"],
                current_candidate,
                args.version,
            )

        stage = "verification"
        verification = verify_remote(
            args.repo, args.version, args.appcast_branch, notes, rendered
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

    state.update(
        {
            "updated_at": now_utc(),
            "status": "completed",
            "verification": verification,
            "release_updated": preview["release_update_required"],
            "appcast_updated": appcast_updated,
        }
    )
    atomic_write_json(state_path, state)
    print(json.dumps(state, ensure_ascii=False, indent=2, sort_keys=True))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("version")
    parser.add_argument("--repo", default="tisfeng/Easydict")
    parser.add_argument("--notes-file", type=Path)
    parser.add_argument("--appcast-branch", default="main")
    parser.add_argument("--state", type=Path)
    parser.add_argument(
        "--execute",
        action="store_true",
        help="write the GitHub Release body and remote appcast",
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
