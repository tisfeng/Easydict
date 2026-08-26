#!/usr/bin/env python3
"""Validate the deterministic structure of an Easydict commit message."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


ALLOWED_TYPES = {
    "build",
    "ci",
    "chore",
    "docs",
    "feat",
    "fix",
    "perf",
    "refactor",
    "revert",
    "style",
    "test",
}
SEPARATOR = "-" * 70
DIVIDER_PATTERN = re.compile(r"-{3,}")
FOOTER_LIKE_PATTERN = re.compile(
    r"^(?:BREAKING[ -]CHANGE|[A-Za-z][A-Za-z0-9-]*)(?::| #)"
)
BREAKING_FOOTER_PATTERN = re.compile(r"^BREAKING CHANGE: \S")
HEADER_PATTERN = re.compile(
    r"^(?P<type>[a-z]+)(?:\((?P<scope>[^()\s]+)\))?(?P<breaking>!)?: "
    r"(?P<subject>\S(?:.*\S)?)$"
)


class ValidationError(RuntimeError):
    """Describe one or more invalid commit-message properties."""


@dataclass(frozen=True)
class Header:
    """Store the comparable Angular header fields for one language block."""

    commit_type: str
    scope: str | None
    breaking: bool
    has_breaking_footer: bool = False


def normalize_message(text: str) -> str:
    """Normalize line endings and terminal newlines without changing content."""

    normalized = text.replace("\r\n", "\n").replace("\r", "\n")
    return normalized.rstrip("\n") + "\n"


def read_message(path: Path) -> str:
    """Read one UTF-8 commit-message file."""

    try:
        return normalize_message(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError) as error:
        raise ValidationError(f"cannot read {path}: {error}") from error


def read_commit_message(revision: str) -> str:
    """Resolve a commit and return its full message."""

    try:
        resolved = subprocess.run(
            [
                "git",
                "rev-parse",
                "--verify",
                "--end-of-options",
                f"{revision}^{{commit}}",
            ],
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        ).stdout.strip()
        message = subprocess.run(
            ["git", "show", "-s", "--format=%B", resolved],
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        ).stdout
    except subprocess.CalledProcessError as error:
        detail = error.stderr.strip() or "Git command failed"
        raise ValidationError(detail) from error
    return normalize_message(message)


def split_paragraphs(block: str) -> list[str]:
    """Split a language block on blank lines while preserving multiline text."""

    return [paragraph for paragraph in re.split(r"\n[ \t]*\n+", block) if paragraph]


def validate_header(text: str, block_name: str) -> Header:
    """Validate one Angular header and return its comparable signature."""

    if "\n" in text:
        raise ValidationError(f"{block_name}: subject must occupy exactly one line")
    if len(text) > 80:
        raise ValidationError(
            f"{block_name}: subject line is {len(text)} characters; maximum is 80"
        )
    match = HEADER_PATTERN.fullmatch(text)
    if match is None:
        raise ValidationError(
            f"{block_name}: subject must use 'type(scope): subject' syntax"
        )
    commit_type = match.group("type")
    if commit_type not in ALLOWED_TYPES:
        allowed = ", ".join(sorted(ALLOWED_TYPES))
        raise ValidationError(
            f"{block_name}: unsupported type '{commit_type}'; expected one of {allowed}"
        )
    return Header(
        commit_type=commit_type,
        scope=match.group("scope"),
        breaking=match.group("breaking") == "!",
    )


def validate_block(block: str, block_name: str) -> Header:
    """Validate one subject, three body paragraphs, and an optional footer."""

    paragraphs = split_paragraphs(block)
    if not paragraphs:
        raise ValidationError(f"{block_name}: block is empty")

    header = validate_header(paragraphs[0], block_name)
    content = paragraphs[1:]
    has_breaking_footer = False
    for index, paragraph in enumerate(content):
        is_breaking_footer = BREAKING_FOOTER_PATTERN.match(paragraph) is not None
        if is_breaking_footer:
            if index != len(content) - 1:
                raise ValidationError(
                    f"{block_name}: BREAKING CHANGE footer must be the final paragraph"
                )
            has_breaking_footer = True
            continue
        if FOOTER_LIKE_PATTERN.match(paragraph):
            raise ValidationError(
                f"{block_name}: unsupported or malformed footer paragraph"
            )

    body = content[:-1] if has_breaking_footer else content
    if len(body) != 3:
        raise ValidationError(
            f"{block_name}: expected exactly 3 body paragraphs, found {len(body)}"
        )
    return Header(
        commit_type=header.commit_type,
        scope=header.scope,
        breaking=header.breaking,
        has_breaking_footer=has_breaking_footer,
    )


def split_bilingual_message(message: str) -> list[str]:
    """Validate separator placement and return both language blocks."""

    lines = message.rstrip("\n").split("\n")
    divider_lines = [line for line in lines if DIVIDER_PATTERN.fullmatch(line)]
    malformed = [line for line in divider_lines if line != SEPARATOR]
    if malformed:
        raise ValidationError("bilingual separator must contain exactly 70 hyphens")
    positions = [index for index, line in enumerate(lines) if line == SEPARATOR]
    if len(positions) != 1:
        raise ValidationError(
            f"bilingual message requires exactly 1 separator, found {len(positions)}"
        )

    index = positions[0]
    spacing_is_exact = (
        index >= 2
        and index + 2 < len(lines)
        and lines[index - 1] == ""
        and lines[index + 1] == ""
        and lines[index - 2] != ""
        and lines[index + 2] != ""
    )
    if not spacing_is_exact:
        raise ValidationError(
            "bilingual separator must have exactly one blank line before and after it"
        )
    return ["\n".join(lines[: index - 1]), "\n".join(lines[index + 2 :])]


def validate_message(message: str, mode: str) -> None:
    """Validate one normalized message in the requested language mode."""

    if re.match(r"^[ \t]*\n", message):
        raise ValidationError("subject must be the first line of the message")
    if "```" in message:
        raise ValidationError("commit message must not contain Markdown code fences")

    if mode == "english":
        if any(DIVIDER_PATTERN.fullmatch(line) for line in message.splitlines()):
            raise ValidationError(
                "english message must not contain a language separator"
            )
        validate_block(message.rstrip("\n"), "English block")
        return

    blocks = split_bilingual_message(message)
    headers: list[Header | None] = []
    errors: list[str] = []
    for block, block_name in zip(
        blocks,
        ("Local-language block", "English block"),
    ):
        try:
            headers.append(validate_block(block, block_name))
        except ValidationError as error:
            headers.append(None)
            errors.append(str(error))
    if errors:
        raise ValidationError("; ".join(errors))

    local_header, english_header = headers
    if local_header != english_header:
        raise ValidationError(
            "language blocks must use matching type, scope, breaking marker, "
            "and BREAKING CHANGE footer presence"
        )


def parse_arguments() -> argparse.Namespace:
    """Parse a file or commit validation request."""

    parser = argparse.ArgumentParser(
        description="Validate the Easydict commit-message structure."
    )
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--file", type=Path, help="UTF-8 message file to validate")
    source.add_argument("--commit", help="Git commit revision to validate")
    parser.add_argument(
        "--mode",
        required=True,
        choices=("english", "bilingual"),
        help="expected language-block layout",
    )
    parser.add_argument(
        "--expected-file",
        type=Path,
        help="require a commit message to match this message file",
    )
    arguments = parser.parse_args()
    if arguments.expected_file is not None and arguments.commit is None:
        parser.error("--expected-file requires --commit")
    return arguments


def main() -> int:
    """Validate the selected input and report a concise result."""

    arguments = parse_arguments()
    try:
        message = (
            read_message(arguments.file)
            if arguments.file is not None
            else read_commit_message(arguments.commit)
        )
        validate_message(message, arguments.mode)
        if arguments.expected_file is not None:
            expected = read_message(arguments.expected_file)
            if message != expected:
                raise ValidationError(
                    "commit message does not match the expected message file"
                )
    except ValidationError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    block_summary = "1 block" if arguments.mode == "english" else "2 blocks"
    print(f"ok: valid {arguments.mode} commit message ({block_summary})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
