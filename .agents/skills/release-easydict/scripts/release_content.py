#!/usr/bin/env python3
"""Capture, validate, render, and apply curated GitHub Release content."""

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


SCHEMA_VERSION = 1
ENTRY_PATTERN = re.compile(
    r"^(?P<bullet>\s*[*+-]\s+)"
    r"(?P<title>.+?)\s+by\s+"
    r"(?P<author>@\S+)\s+in\s+"
    r"(?P<url>https://github\.com/[^/\s]+/[^/\s]+/pull/(?P<number>\d+))\s*$"
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


class ReleaseContentError(RuntimeError):
    """Raised when release content is malformed or unsafe to apply."""


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


def read_json(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ReleaseContentError(f"cannot read JSON file: {path}") from error
    if not isinstance(payload, dict):
        raise ReleaseContentError(f"expected a JSON object: {path}")
    return payload


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


def stable_hash(payload: dict[str, Any]) -> str:
    source = dict(payload)
    source.pop("source_sha256", None)
    encoded = json.dumps(
        source,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


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
        raise ReleaseContentError("release body contains no generated PR entries")
    return entries


def capture_payload(
    repository: str,
    version: str,
    release: dict[str, Any],
) -> dict[str, Any]:
    if release.get("tagName") != version:
        raise ReleaseContentError(
            f"release tag {release.get('tagName')!r} does not match {version!r}"
        )
    body = release.get("body")
    if not isinstance(body, str):
        raise ReleaseContentError("release body is missing")
    payload: dict[str, Any] = {
        "schema_version": SCHEMA_VERSION,
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
    payload["source_sha256"] = stable_hash(payload)
    return payload


def capture_command(args: argparse.Namespace) -> None:
    if args.input_json is not None:
        release = read_json(args.input_json)
    else:
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


def validate_curated(
    source: dict[str, Any],
    curated: dict[str, Any],
) -> dict[int, str]:
    if source.get("schema_version") != SCHEMA_VERSION:
        raise ReleaseContentError("unsupported source schema version")
    if source.get("source_sha256") != stable_hash(source):
        raise ReleaseContentError("captured source failed its integrity check")
    if curated.get("schema_version") != SCHEMA_VERSION:
        raise ReleaseContentError("unsupported curated schema version")
    if curated.get("source_sha256") != source.get("source_sha256"):
        raise ReleaseContentError("curated content does not match the captured source")

    version = source.get("version")
    release_title = curated.get("release_title")
    if not isinstance(version, str) or not isinstance(release_title, str):
        raise ReleaseContentError("version or release_title is missing")
    title_pattern = re.compile(
        TITLE_PATTERN_TEMPLATE.format(version=re.escape(version))
    )
    title_match = title_pattern.match(release_title)
    if title_match is None:
        raise ReleaseContentError(
            "release_title must use '<version> <emoji> <type>: <summary>'"
        )
    if TITLE_EMOJI[title_match.group("type")] != title_match.group("emoji"):
        raise ReleaseContentError("release_title emoji does not match its type")
    if len(release_title) > 120 or contains_non_latin_letter(release_title):
        raise ReleaseContentError("release_title must be concise English")

    entries = source.get("entries")
    translations = curated.get("entries")
    if not isinstance(entries, list) or not isinstance(translations, list):
        raise ReleaseContentError("source or curated entries are missing")
    source_numbers = {
        entry.get("pr_number") for entry in entries if isinstance(entry, dict)
    }
    translated: dict[int, str] = {}
    for item in translations:
        if not isinstance(item, dict):
            raise ReleaseContentError("curated entry must be an object")
        number = item.get("pr_number")
        title = item.get("title")
        if not isinstance(number, int) or not isinstance(title, str):
            raise ReleaseContentError("curated entry needs pr_number and title")
        if number in translated:
            raise ReleaseContentError(f"duplicate curated PR entry: #{number}")
        if not title.strip() or "\n" in title or len(title) > 180:
            raise ReleaseContentError(f"invalid translated title for PR #{number}")
        if contains_non_latin_letter(title):
            raise ReleaseContentError(f"translated title is not English: PR #{number}")
        translated[number] = title.strip()
    if set(translated) != source_numbers:
        missing = sorted(source_numbers - set(translated))
        extra = sorted(set(translated) - source_numbers)
        raise ReleaseContentError(
            f"curated PR set differs from source; missing={missing}, extra={extra}"
        )
    highlight_pr = curated.get("highlight_pr")
    if highlight_pr not in source_numbers:
        raise ReleaseContentError("highlight_pr must identify a source PR")
    return translated


def render_notes(
    source: dict[str, Any],
    curated: dict[str, Any],
) -> str:
    translations = validate_curated(source, curated)
    body = source.get("source_body")
    entries = source.get("entries")
    if not isinstance(body, str) or not isinstance(entries, list):
        raise ReleaseContentError("captured source is incomplete")
    lines = body.splitlines()
    for entry in entries:
        if not isinstance(entry, dict):
            raise ReleaseContentError("source entry must be an object")
        number = entry["pr_number"]
        line_index = entry["line_index"]
        lines[line_index] = (
            f"{entry['bullet']}{translations[number]} by "
            f"{entry['author']} in {entry['pr_url']}"
        )
    rendered = "\n".join(lines)
    if body.endswith("\n"):
        rendered += "\n"
    if {entry["pr_number"] for entry in parse_change_entries(rendered)} != set(
        translations
    ):
        raise ReleaseContentError("rendered release notes changed the PR set")
    return rendered


def render_command(args: argparse.Namespace) -> None:
    source = read_json(args.source)
    curated = read_json(args.curated)
    rendered = render_notes(source, curated)
    atomic_write_text(args.output, rendered)
    print(json.dumps({"output": str(args.output), "bytes": len(rendered.encode())}))


def apply_command(args: argparse.Namespace) -> None:
    source = read_json(args.source)
    curated = read_json(args.curated)
    rendered = render_notes(source, curated)
    notes = args.notes.read_text(encoding="utf-8")
    if notes != rendered:
        raise ReleaseContentError(
            "notes file does not match validated rendered content"
        )
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
    if release.get("tagName") != args.version or release.get("isDraft") is not True:
        raise ReleaseContentError("release must be the expected Draft before curation")
    source_release = source.get("release") or {}
    if (
        release.get("body") != source.get("source_body")
        or release.get("name") != source_release.get("name")
    ):
        raise ReleaseContentError("Draft changed after content capture")
    plan = {
        "version": args.version,
        "release_title": curated["release_title"],
        "notes": str(args.notes),
        "execute": args.execute,
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
            curated["release_title"],
            "--notes-file",
            str(args.notes),
        ],
        check=True,
    )
    updated = run_json(
        [
            "gh",
            "release",
            "view",
            args.version,
            "--repo",
            args.repo,
            "--json",
            "body,name,isDraft,tagName,url",
        ]
    )
    if (
        updated.get("name") != curated["release_title"]
        or updated.get("body") != rendered
        or updated.get("isDraft") is not True
    ):
        raise ReleaseContentError("updated Draft content failed remote verification")
    print(json.dumps({**plan, "url": updated.get("url")}, ensure_ascii=False, indent=2))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    capture = subparsers.add_parser("capture", help="capture generated release notes")
    capture.add_argument("--repo", required=True)
    capture.add_argument("--version", required=True)
    capture.add_argument("--output", type=Path, required=True)
    capture.add_argument("--input-json", type=Path)
    capture.set_defaults(handler=capture_command)

    render = subparsers.add_parser("render", help="validate and render curated notes")
    render.add_argument("--source", type=Path, required=True)
    render.add_argument("--curated", type=Path, required=True)
    render.add_argument("--output", type=Path, required=True)
    render.set_defaults(handler=render_command)

    apply = subparsers.add_parser("apply", help="apply curated content to a Draft")
    apply.add_argument("--repo", required=True)
    apply.add_argument("--version", required=True)
    apply.add_argument("--source", type=Path, required=True)
    apply.add_argument("--curated", type=Path, required=True)
    apply.add_argument("--notes", type=Path, required=True)
    apply.add_argument("--execute", action="store_true")
    apply.set_defaults(handler=apply_command)
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        args.handler(args)
    except (ReleaseContentError, OSError, subprocess.SubprocessError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
