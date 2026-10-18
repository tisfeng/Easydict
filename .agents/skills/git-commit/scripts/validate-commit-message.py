#!/usr/bin/env python3
"""Validate the deterministic structure of a commit message."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from urllib.parse import urlsplit


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
ENGLISH_BODY_LABELS = ("context: ", "change: ", "impact: ")
CHINESE_BODY_LABELS = ("背景：", "变更：", "影响：")
BODY_LABEL_LIKE_PATTERN = re.compile(
    r"^(?:context|change|impact|result):",
    re.I,
)
REFERENCES_HEADER = "References:"
REFERENCES_HEADER_LIKE_PATTERN = re.compile(r"^[ \t]*references?[ \t]*:", re.I)
REFERENCE_ITEM_PATTERN = re.compile(
    r"^- (?:(?P<label>\S(?:.*\S)?): )?(?P<url>https?://\S+)$"
)
HEADER_PATTERN = re.compile(
    r"^(?P<type>[a-z]+)(?:\((?P<scope>[^()\s]+)\))?(?P<breaking>!)?: "
    r"(?P<subject>\S(?:.*\S)?)$"
)
HAN_CHARACTER_PATTERN = re.compile(r"[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]")
ASCII_LETTER_PATTERN = re.compile(r"[A-Za-z]")


class ValidationError(RuntimeError):
    """Describe one or more invalid commit-message properties."""


@dataclass(frozen=True)
class Header:
    """Store comparable Angular fields and language-specific subject metadata."""

    commit_type: str
    scope: str | None
    breaking: bool
    has_breaking_footer: bool = False
    subject: str = field(default="", compare=False)
    body_labels: tuple[str, str, str] = field(default=(), compare=False)


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


def strip_and_validate_references(message: str) -> str:
    """Remove one final global references section after validating its entries."""

    lines = message.rstrip("\n").split("\n")
    malformed_headings = [
        line
        for line in lines
        if REFERENCES_HEADER_LIKE_PATTERN.match(line) and line != REFERENCES_HEADER
    ]
    if malformed_headings:
        raise ValidationError("References section heading must be exactly 'References:'")

    positions = [index for index, line in enumerate(lines) if line == REFERENCES_HEADER]
    if not positions:
        return message.rstrip("\n")
    if len(positions) != 1:
        raise ValidationError(
            f"commit message allows at most 1 References section, found {len(positions)}"
        )

    index = positions[0]
    spacing_is_exact = (
        index >= 2 and lines[index - 1] == "" and lines[index - 2] != ""
    )
    if not spacing_is_exact:
        raise ValidationError(
            "References section must have exactly one blank line before it"
        )

    entries = lines[index + 1 :]
    if not entries:
        raise ValidationError("References section requires at least 1 entry")

    urls: set[str] = set()
    for entry in entries:
        match = REFERENCE_ITEM_PATTERN.fullmatch(entry)
        if match is None:
            raise ValidationError(
                "References entries must use '- [label: ]http(s)://...' on one line"
            )
        url = match.group("url")
        try:
            parsed = urlsplit(url)
        except ValueError as error:
            raise ValidationError(
                "References entries must end with an absolute HTTP(S) URL"
            ) from error
        if parsed.scheme not in {"http", "https"} or not parsed.netloc:
            raise ValidationError(
                "References entries must end with an absolute HTTP(S) URL"
            )
        if url in urls:
            raise ValidationError(f"References section contains duplicate URL '{url}'")
        urls.add(url)

    return "\n".join(lines[: index - 1])


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
        subject=match.group("subject"),
    )


def validate_body_labels(
    body: list[str],
    block_name: str,
    allowed_label_sets: tuple[tuple[str, str, str], ...],
) -> tuple[str, str, str]:
    """Require one complete, ordered body-label set with non-empty content."""

    selected_labels = next(
        (
            labels
            for labels in allowed_label_sets
            if body[0].startswith(labels[0])
        ),
        None,
    )
    if selected_labels is None:
        expected = " or ".join(repr(labels[0]) for labels in allowed_label_sets)
        raise ValidationError(
            f"{block_name}: body paragraph 1 must start with {expected}"
        )

    for index, (paragraph, label) in enumerate(zip(body, selected_labels), start=1):
        if not paragraph.startswith(label):
            raise ValidationError(
                f"{block_name}: body paragraph {index} must start with {label!r}"
            )
        content = paragraph[len(label) :]
        if not content or content[0].isspace():
            raise ValidationError(
                f"{block_name}: body paragraph {index} must include content "
                f"immediately after {label!r}"
            )
    return selected_labels


def validate_block(
    block: str,
    block_name: str,
    allowed_label_sets: tuple[tuple[str, str, str], ...],
) -> Header:
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
        is_footer_like = FOOTER_LIKE_PATTERN.match(paragraph) is not None
        is_body_label = BODY_LABEL_LIKE_PATTERN.match(paragraph) is not None
        if is_footer_like and not is_body_label:
            raise ValidationError(
                f"{block_name}: unsupported or malformed footer paragraph"
            )

    body = content[:-1] if has_breaking_footer else content
    if len(body) != 3:
        raise ValidationError(
            f"{block_name}: expected exactly 3 body paragraphs, found {len(body)}"
        )
    body_labels = validate_body_labels(body, block_name, allowed_label_sets)
    return Header(
        commit_type=header.commit_type,
        scope=header.scope,
        breaking=header.breaking,
        has_breaking_footer=has_breaking_footer,
        subject=header.subject,
        body_labels=body_labels,
    )


def validate_bilingual_subject_languages(
    local_header: Header,
    english_header: Header,
) -> None:
    """Keep local and English subjects distinct and language-appropriate."""

    if local_header.subject == english_header.subject:
        raise ValidationError(
            "language blocks must use distinct local-language and English subjects"
        )
    if HAN_CHARACTER_PATTERN.search(english_header.subject):
        raise ValidationError(
            "English block: subject must not contain Han characters"
        )
    if ASCII_LETTER_PATTERN.search(english_header.subject) is None:
        raise ValidationError(
            "English block: subject must contain English text"
        )
    if (
        local_header.body_labels == CHINESE_BODY_LABELS
        and HAN_CHARACTER_PATTERN.search(local_header.subject) is None
    ):
        raise ValidationError(
            "Local-language block: Chinese subject must contain Han characters"
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

    message_without_references = strip_and_validate_references(message)

    if mode == "english":
        if any(
            DIVIDER_PATTERN.fullmatch(line)
            for line in message_without_references.splitlines()
        ):
            raise ValidationError(
                "english message must not contain a language separator"
            )
        validate_block(
            message_without_references,
            "English block",
            (ENGLISH_BODY_LABELS,),
        )
        return

    blocks = split_bilingual_message(message_without_references)
    headers: list[Header | None] = []
    errors: list[str] = []
    block_specs = (
        ("Local-language block", (CHINESE_BODY_LABELS, ENGLISH_BODY_LABELS)),
        ("English block", (ENGLISH_BODY_LABELS,)),
    )
    for block, (block_name, allowed_label_sets) in zip(
        blocks,
        block_specs,
    ):
        try:
            headers.append(validate_block(block, block_name, allowed_label_sets))
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
    validate_bilingual_subject_languages(local_header, english_header)


def parse_arguments() -> argparse.Namespace:
    """Parse a file or commit validation request."""

    parser = argparse.ArgumentParser(
        description="Validate the commit-message structure."
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
