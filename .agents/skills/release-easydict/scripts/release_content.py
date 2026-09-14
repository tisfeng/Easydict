#!/usr/bin/env python3
"""Validate a canonical changelog and safely update a Draft release title."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unicodedata
from typing import Any


REPOSITORY_ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(REPOSITORY_ROOT / "scripts" / "release"))

from release_notes import (  # noqa: E402
    ReleaseNotesError,
    normalize_body,
    read_notes,
)


TITLE_PATTERN_TEMPLATE = (
    r"^{version}\s+(?P<emoji>✨|🐞|🔒|🚀|🔧)\s+"
    r"(?P<type>feat|fix|security|perf|chore):\s+\S.+$"
)
TITLE_EMOJI = {
    "feat": "✨",
    "fix": "🐞",
    "security": "🔒",
    "perf": "🚀",
    "chore": "🔧",
}
ENTRY_PATTERN = re.compile(
    r"^(?P<bullet>\s*[*+-]\s+)"
    r"(?P<title>.+?)\s+by\s+"
    r"(?P<author>@\S+)\s+in\s+"
    r"(?P<url>https://github\.com/[^/\s]+/[^/\s]+/pull/(?P<number>\d+))\s*$"
)


class ReleaseContentError(RuntimeError):
    """Raised when a Draft cannot be safely updated."""


def run_json(command: list[str]) -> dict[str, Any]:
    result = subprocess.run(
        command,
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise ReleaseContentError(f"command failed: {' '.join(command)}\n{detail}")
    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise ReleaseContentError("command did not return valid JSON") from error
    if not isinstance(payload, dict):
        raise ReleaseContentError("expected a JSON object")
    return payload


def atomic_write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.", dir=path.parent, text=True
    )
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            json.dump(payload, handle, ensure_ascii=False, indent=2, sort_keys=True)
            handle.write("\n")
        os.replace(temporary_name, path)
    except Exception:
        try:
            os.unlink(temporary_name)
        except FileNotFoundError:
            pass
        raise


def parse_change_entries(body: str) -> list[dict[str, Any]]:
    entries: list[dict[str, Any]] = []
    seen_numbers: set[int] = set()
    for line_index, line in enumerate(body.splitlines()):
        match = ENTRY_PATTERN.match(line)
        if match is None:
            continue
        number = int(match.group("number"))
        if number in seen_numbers:
            raise ReleaseContentError(f"duplicate PR entry in release notes: #{number}")
        seen_numbers.add(number)
        entries.append(
            {
                "pr_number": number,
                "source_title": match.group("title"),
                "author": match.group("author"),
                "pr_url": match.group("url"),
                "line_index": line_index,
                "bullet": match.group("bullet"),
            }
        )
    if not entries:
        raise ReleaseContentError("release body contains no PR entries")
    return entries


def capture_payload(
    repository: str,
    version: str,
    release: dict[str, Any],
) -> dict[str, Any]:
    if release.get("tagName") != version:
        raise ReleaseContentError("release tag does not match the requested version")
    body = release.get("body")
    if not isinstance(body, str):
        raise ReleaseContentError("release body is missing")
    payload: dict[str, Any] = {
        "schema_version": 2,
        "repository": repository,
        "version": version,
        "release": {
            "name": release.get("name"),
            "tag_name": release.get("tagName"),
            "url": release.get("url"),
            "is_draft": release.get("isDraft"),
            "is_prerelease": release.get("isPrerelease"),
        },
        "source_body": body,
        "entries": parse_change_entries(body),
    }
    encoded = json.dumps(
        payload, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")
    payload["source_sha256"] = hashlib.sha256(encoded).hexdigest()
    return payload


def capture_command(args: argparse.Namespace) -> None:
    release = run_json(
        [
            "gh",
            "release",
            "view",
            args.version,
            "--repo",
            args.repo,
            "--json",
            "body,name,isDraft,isPrerelease,tagName,url",
        ]
    )
    payload = capture_payload(args.repo, args.version, release)
    atomic_write_json(args.output, payload)
    print(json.dumps({"output": str(args.output), "entries": len(payload["entries"])}))


def contains_non_latin_letter(value: str) -> bool:
    for character in value:
        if not unicodedata.category(character).startswith("L"):
            continue
        if "LATIN" not in unicodedata.name(character, ""):
            return True
    return False


def validate_release_title(version: str, title: str) -> None:
    pattern = re.compile(TITLE_PATTERN_TEMPLATE.format(version=re.escape(version)))
    match = pattern.match(title)
    if match is None:
        raise ReleaseContentError(
            "release title must use '<version> <emoji> <type>: <summary>'"
        )
    if TITLE_EMOJI[match.group("type")] != match.group("emoji"):
        raise ReleaseContentError("release title emoji does not match its type")
    if len(title) > 120 or contains_non_latin_letter(title):
        raise ReleaseContentError("release title must be concise English")


def validate_draft(
    release: dict[str, Any],
    version: str,
    notes: str,
) -> None:
    if release.get("tagName") != version or release.get("isDraft") is not True:
        raise ReleaseContentError("release must be the expected Draft")
    body = release.get("body")
    if not isinstance(body, str) or normalize_body(body) != normalize_body(notes):
        raise ReleaseContentError(
            "Draft body differs from canonical changelog; update the Markdown "
            "and rebuild the Draft instead of editing GitHub directly"
        )


def fetch_draft(repo: str, version: str) -> dict[str, Any]:
    return run_json(
        [
            "gh",
            "release",
            "view",
            version,
            "--repo",
            repo,
            "--json",
            "body,name,isDraft,tagName,url",
        ]
    )


def apply_command(args: argparse.Namespace) -> None:
    validate_release_title(args.version, args.title)
    notes = read_notes(args.notes, args.version)
    release = fetch_draft(args.repo, args.version)
    validate_draft(release, args.version, notes)

    plan = {
        "version": args.version,
        "release_title": args.title,
        "notes": str(args.notes),
        "execute": args.execute,
        "url": release.get("url"),
    }
    if not args.execute:
        print(json.dumps(plan, ensure_ascii=False, indent=2))
        return

    subprocess.run(
        [
            "gh",
            "release",
            "edit",
            args.version,
            "--repo",
            args.repo,
            "--title",
            args.title,
        ],
        check=True,
    )
    updated = fetch_draft(args.repo, args.version)
    validate_draft(updated, args.version, notes)
    if updated.get("name") != args.title:
        raise ReleaseContentError("updated Draft title failed remote verification")
    print(json.dumps(plan, ensure_ascii=False, indent=2))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    capture = subparsers.add_parser(
        "capture", help="capture verified release content for issue auditing"
    )
    capture.add_argument("--repo", required=True)
    capture.add_argument("--version", required=True)
    capture.add_argument("--output", type=Path, required=True)
    capture.set_defaults(handler=capture_command)

    apply = subparsers.add_parser("apply", help="validate notes and update title")
    apply.add_argument("--repo", required=True)
    apply.add_argument("--version", required=True)
    apply.add_argument("--notes", type=Path, required=True)
    apply.add_argument("--title", required=True)
    apply.add_argument("--execute", action="store_true")
    apply.set_defaults(handler=apply_command)
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        args.handler(args)
    except (
        ReleaseContentError,
        ReleaseNotesError,
        OSError,
        subprocess.SubprocessError,
    ) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
