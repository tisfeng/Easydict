#!/usr/bin/env python3
"""Validate and render canonical Easydict release-note Markdown files."""

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
import xml.etree.ElementTree as ET
from typing import Any

try:
    import markdown
    from markdown.extensions import Extension
    from markdown.inlinepatterns import InlineProcessor
except ImportError:
    markdown = None
    Extension = object  # type: ignore[assignment,misc]
    InlineProcessor = object  # type: ignore[assignment,misc]


SCHEMA_VERSION = 1
EXPECTED_MARKDOWN_VERSION = "3.6"
VERSION_PATTERN = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")
BARE_URL_PATTERN = r"(?<![\w\"'=])(https?://[^\s<>]+)"
TRAILING_URL_PUNCTUATION = ".,;:!?]}"
RAW_EXCLUDED_TAG_PATTERN = re.compile(
    r"<(?P<closing>/)?(?P<tag>a|code|pre)\b[^>]*>",
    re.IGNORECASE,
)


class ReleaseNotesError(RuntimeError):
    """Raised when canonical release notes are missing or inconsistent."""


class BareUrlInlineProcessor(InlineProcessor):
    """Link a bare URL while operating only on Markdown text nodes."""

    ANCESTOR_EXCLUDES = ("a", "code", "pre")

    @staticmethod
    def is_inside_raw_excluded_tag(data: str, index: int) -> bool:
        depths = {"a": 0, "code": 0, "pre": 0}
        for token in RAW_EXCLUDED_TAG_PATTERN.finditer(data, 0, index):
            tag = token.group("tag").lower()
            if token.group("closing"):
                depths[tag] = max(0, depths[tag] - 1)
            else:
                depths[tag] += 1
        return any(depths.values())

    def handleMatch(  # noqa: N802 - Python-Markdown public API
        self,
        match: re.Match[str],
        data: str,
    ) -> tuple[ET.Element | None, int | None, int | None]:
        original = match.group(1)
        if self.is_inside_raw_excluded_tag(data, match.start(1)):
            return None, None, None
        url = original.rstrip(TRAILING_URL_PUNCTUATION)
        while url.endswith(")") and url.count(")") > url.count("("):
            url = url[:-1]
        if not url:
            return None, None, None
        element = ET.Element("a", {"href": url})
        element.text = url
        return element, match.start(1), match.start(1) + len(url)


class BareUrlExtension(Extension):
    """Register safe bare-URL handling after Markdown link/image parsing."""

    def extendMarkdown(self, md: Any) -> None:  # noqa: N802
        md.inlinePatterns.register(
            BareUrlInlineProcessor(BARE_URL_PATTERN, md),
            "easydict_bare_url",
            120,
        )


def require_renderer() -> None:
    """Require the pinned renderer so HTML is stable across release machines."""
    if markdown is None:
        raise ReleaseNotesError(
            "Python-Markdown is required; install scripts/release/requirements.txt"
        )
    installed = getattr(markdown, "__version__", "unknown")
    if installed != EXPECTED_MARKDOWN_VERSION:
        raise ReleaseNotesError(
            "Python-Markdown version mismatch: "
            f"expected {EXPECTED_MARKDOWN_VERSION}, found {installed}"
        )


def normalize_body(text: str) -> str:
    """Normalize GitHub line endings and one conventional terminal newline."""
    normalized = text.replace("\r\n", "\n").replace("\r", "\n")
    if normalized.endswith("\n"):
        normalized = normalized[:-1]
    return normalized


def read_notes(path: Path, version: str) -> str:
    """Read and strictly validate one canonical version Markdown file."""
    if not VERSION_PATTERN.fullmatch(version):
        raise ReleaseNotesError("version must use x.y.z format")
    if path.name != f"{version}.md":
        raise ReleaseNotesError(
            f"release notes filename must be {version}.md: {path}"
        )
    try:
        raw = path.read_bytes()
    except OSError as error:
        raise ReleaseNotesError(f"cannot read release notes: {path}") from error
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError as error:
        raise ReleaseNotesError(f"release notes are not valid UTF-8: {path}") from error
    if text.startswith("\ufeff"):
        raise ReleaseNotesError("release notes must not contain a UTF-8 BOM")
    if "\r" in text:
        raise ReleaseNotesError("release notes must use LF line endings")
    if "\x00" in text:
        raise ReleaseNotesError("release notes must not contain NUL bytes")
    if not normalize_body(text).strip():
        raise ReleaseNotesError("release notes must not be empty")
    if text.startswith("---\n"):
        raise ReleaseNotesError("release notes must not contain YAML front matter")
    return text


def notes_sha256(text: str) -> str:
    """Hash canonical Markdown with transport-only normalization."""
    return hashlib.sha256(normalize_body(text).encode("utf-8")).hexdigest()


def renderer_identity() -> str:
    require_renderer()
    return f"Python-Markdown/{EXPECTED_MARKDOWN_VERSION}:extra,sane_lists,easydict_bare_url"


def render_markdown(text: str) -> str:
    """Render canonical Markdown to HTML for a Sparkle description."""
    require_renderer()
    assert markdown is not None
    return markdown.markdown(
        normalize_body(text),
        extensions=["extra", "sane_lists", BareUrlExtension()],
        output_format="html5",
    )


def notes_metadata(path: Path, version: str) -> dict[str, Any]:
    text = read_notes(path, version)
    html = render_markdown(text)
    return {
        "schema_version": SCHEMA_VERSION,
        "version": version,
        "path": f"changelog/{version}.md",
        "markdown_sha256": notes_sha256(text),
        "renderer": renderer_identity(),
        "html_sha256": hashlib.sha256(html.encode("utf-8")).hexdigest(),
    }


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


def read_json(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ReleaseNotesError(f"cannot read JSON file: {path}") from error
    if not isinstance(payload, dict):
        raise ReleaseNotesError(f"expected a JSON object: {path}")
    return payload


def validate_state(path: Path, version: str, state_path: Path) -> dict[str, Any]:
    expected = notes_metadata(path, version)
    state = read_json(state_path)
    for key, value in expected.items():
        if state.get(key) != value:
            raise ReleaseNotesError(
                f"release notes changed after snapshot: {key} differs"
            )
    return expected


def release_payload(args: argparse.Namespace) -> dict[str, Any]:
    if args.input_json is not None:
        return read_json(args.input_json)
    result = subprocess.run(
        [
            "gh",
            "release",
            "view",
            args.version,
            "--repo",
            args.repo,
            "--json",
            "body,tagName,url",
        ],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise ReleaseNotesError(f"cannot read GitHub Release: {detail}")
    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise ReleaseNotesError("GitHub Release response is not valid JSON") from error
    if not isinstance(payload, dict):
        raise ReleaseNotesError("GitHub Release response is not an object")
    return payload


def verify_release(path: Path, version: str, payload: dict[str, Any]) -> str:
    notes = read_notes(path, version)
    if payload.get("tagName") != version:
        raise ReleaseNotesError("GitHub Release tag does not match the notes version")
    body = payload.get("body")
    if not isinstance(body, str):
        raise ReleaseNotesError("GitHub Release body is missing")
    if normalize_body(body) != normalize_body(notes):
        raise ReleaseNotesError(
            "GitHub Release body differs from canonical changelog Markdown"
        )
    return notes_sha256(notes)


def command_validate(args: argparse.Namespace) -> None:
    print(json.dumps(notes_metadata(args.file, args.version), sort_keys=True))


def command_render(args: argparse.Namespace) -> None:
    rendered = render_markdown(read_notes(args.file, args.version))
    if args.output is None:
        print(rendered)
    else:
        args.output.write_text(rendered, encoding="utf-8")


def command_snapshot(args: argparse.Namespace) -> None:
    metadata = notes_metadata(args.file, args.version)
    if args.state.exists():
        validate_state(args.file, args.version, args.state)
    else:
        atomic_write_json(args.state, metadata)
    print(json.dumps(metadata, sort_keys=True))


def command_verify_state(args: argparse.Namespace) -> None:
    print(
        json.dumps(
            validate_state(args.file, args.version, args.state),
            sort_keys=True,
        )
    )


def command_verify_release(args: argparse.Namespace) -> None:
    payload = release_payload(args)
    digest = verify_release(args.file, args.version, payload)
    print(json.dumps({"markdown_sha256": digest, "url": payload.get("url")}))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    validate = subparsers.add_parser("validate")
    validate.add_argument("--file", type=Path, required=True)
    validate.add_argument("--version", required=True)
    validate.set_defaults(handler=command_validate)

    render = subparsers.add_parser("render")
    render.add_argument("--file", type=Path, required=True)
    render.add_argument("--version", required=True)
    render.add_argument("--output", type=Path)
    render.set_defaults(handler=command_render)

    snapshot = subparsers.add_parser("snapshot")
    snapshot.add_argument("--file", type=Path, required=True)
    snapshot.add_argument("--version", required=True)
    snapshot.add_argument("--state", type=Path, required=True)
    snapshot.set_defaults(handler=command_snapshot)

    verify_state = subparsers.add_parser("verify-state")
    verify_state.add_argument("--file", type=Path, required=True)
    verify_state.add_argument("--version", required=True)
    verify_state.add_argument("--state", type=Path, required=True)
    verify_state.set_defaults(handler=command_verify_state)

    verify_release_parser = subparsers.add_parser("verify-release")
    verify_release_parser.add_argument("--file", type=Path, required=True)
    verify_release_parser.add_argument("--version", required=True)
    verify_release_parser.add_argument("--repo")
    verify_release_parser.add_argument("--input-json", type=Path)
    verify_release_parser.set_defaults(handler=command_verify_release)
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    if args.command == "verify-release" and not (args.repo or args.input_json):
        parser.error("verify-release requires --repo or --input-json")
    try:
        args.handler(args)
    except (ReleaseNotesError, OSError, subprocess.SubprocessError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
