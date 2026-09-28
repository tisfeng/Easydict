#!/usr/bin/env python3
"""Exercise deterministic commit-message validation."""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "validate-commit-message.py"
SEPARATOR = "-" * 70
ENGLISH_BODY_LABELS = ("context: ", "change: ", "impact: ")
CHINESE_BODY_LABELS = ("背景：", "变更：", "影响：")


def block(
    subject: str = "fix(agent): enforce commit message validation",
    body_count: int = 3,
    multiline: bool = False,
    footer: str | None = None,
    labels: tuple[str, str, str] = ENGLISH_BODY_LABELS,
) -> str:
    """Build one language block with a controlled paragraph count."""

    bodies = []
    for index in range(body_count):
        label = labels[index] if index < len(labels) else ""
        paragraph = f"{label}Body paragraph {index + 1}."
        if multiline and index == 1:
            paragraph += "\nThis remains part of the same paragraph."
        bodies.append(paragraph)
    paragraphs = [subject, *bodies]
    if footer is not None:
        paragraphs.append(footer)
    return "\n\n".join(paragraphs)


def bilingual(
    local: str | None = None,
    english: str | None = None,
    separator: str = SEPARATOR,
    before: str = "\n\n",
    after: str = "\n\n",
) -> str:
    """Build one bilingual message with configurable separator spacing."""

    return (
        (
            local
            or block(
                "fix(agent): 强制校验提交信息",
                labels=CHINESE_BODY_LABELS,
            )
        )
        + before
        + separator
        + after
        + (english or block())
        + "\n"
    )


def references(*entries: str) -> str:
    """Build one global references section."""

    return "References:\n" + "\n".join(f"- {entry}" for entry in entries)


class CommitMessageValidatorTests(unittest.TestCase):
    """Verify accepted forms, diagnostics, and Git-facing behavior."""

    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.root = Path(self.temporary_directory.name)

    def run_validator(
        self,
        message: str,
        mode: str = "bilingual",
    ) -> subprocess.CompletedProcess[str]:
        """Validate one fixture file and return its process result."""

        path = self.root / "message.txt"
        path.write_bytes(message.encode("utf-8"))
        return subprocess.run(
            [sys.executable, str(SCRIPT), "--file", str(path), "--mode", mode],
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

    def assert_valid(self, message: str, mode: str = "bilingual") -> None:
        """Require one fixture to pass validation."""

        result = self.run_validator(message, mode)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("ok: valid", result.stdout)

    def assert_invalid(
        self,
        message: str,
        expected_error: str,
        mode: str = "bilingual",
    ) -> None:
        """Require one fixture to fail with an actionable diagnostic."""

        result = self.run_validator(message, mode)
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertEqual(result.stdout, "")
        self.assertIn(expected_error, result.stderr)

    def test_accepts_english_and_bilingual_messages(self) -> None:
        self.assert_valid(block() + "\n", "english")
        self.assert_valid(bilingual())
        self.assert_valid(
            bilingual(local=block("fix(agent): corriger la validation"))
        )

    def test_accepts_one_global_references_section(self) -> None:
        section = references(
            "Apple TN3212: https://developer.apple.com/documentation/technotes/tn3212",
            "https://github.com/example/project/issues/123",
        )
        self.assert_valid(block() + "\n\n" + section + "\n", "english")
        self.assert_valid(bilingual().rstrip("\n") + "\n\n" + section + "\n")

    def test_accepts_references_after_breaking_change_footers(self) -> None:
        local = block(
            "feat(agent)!: 强制校验提交信息",
            footer="BREAKING CHANGE: 旧提交方式不再受支持。",
            labels=CHINESE_BODY_LABELS,
        )
        english = block(
            "feat(agent)!: enforce commit message validation",
            footer="BREAKING CHANGE: The old commit flow is unsupported.",
        )
        message = bilingual(local=local, english=english).rstrip("\n")
        message += (
            "\n\n"
            + references("Migration: https://example.com/migration")
            + "\n"
        )
        self.assert_valid(message)

    def test_rejects_two_or_four_body_paragraphs(self) -> None:
        self.assert_invalid(
            bilingual(
                local=block(
                    "fix(agent): 强制校验提交信息",
                    2,
                    labels=CHINESE_BODY_LABELS,
                )
            ),
            "Local-language block: expected exactly 3 body paragraphs, found 2",
        )
        self.assert_invalid(
            bilingual(english=block(body_count=4)),
            "English block: expected exactly 3 body paragraphs, found 4",
        )

    def test_rejects_missing_duplicate_and_malformed_separators(self) -> None:
        self.assert_invalid(block() + "\n", "requires exactly 1 separator")
        self.assert_invalid(
            bilingual() + "\n" + SEPARATOR + "\n",
            "requires exactly 1 separator",
        )
        self.assert_invalid(
            bilingual(separator="-" * 69),
            "separator must contain exactly 70 hyphens",
        )

    def test_rejects_malformed_or_overlong_subjects(self) -> None:
        self.assert_invalid(
            "\n\n" + block() + "\n",
            "subject must be the first line",
            "english",
        )
        self.assert_invalid(
            block("missing Angular header") + "\n",
            "type(scope): subject",
            "english",
        )
        long_subject = "fix(agent): " + "x" * 70
        self.assert_invalid(
            block(long_subject) + "\n",
            "maximum is 80",
            "english",
        )

    def test_requires_matching_bilingual_header_signatures(self) -> None:
        self.assert_invalid(
            bilingual(english=block("feat(agent): enforce commit message validation")),
            "matching type, scope, breaking marker",
        )

    def test_accepts_only_a_final_breaking_change_footer(self) -> None:
        local = block(
            "feat(agent)!: 强制校验提交信息",
            footer="BREAKING CHANGE: 旧提交方式不再受支持。",
            labels=CHINESE_BODY_LABELS,
        )
        english = block(
            "feat(agent)!: enforce commit message validation",
            footer="BREAKING CHANGE: The old commit flow is unsupported.",
        )
        self.assert_valid(bilingual(local=local, english=english))

        misplaced = "\n\n".join(
            [
                "fix(agent): enforce commit message validation",
                "context: Body paragraph 1.",
                "BREAKING CHANGE: misplaced.",
                "change: Body paragraph 2.",
                "impact: Body paragraph 3.",
            ]
        )
        self.assert_invalid(
            misplaced + "\n",
            "footer must be the final paragraph",
            "english",
        )

    def test_rejects_footer_like_paragraphs_and_malformed_breaking_footer(self) -> None:
        for footer_like in (
            "Refs: #123",
            "BREAKING-CHANGE: unsupported spelling.",
            "BREAKING CHANGE:",
            "BREAKING CHANGE:missing space.",
        ):
            with self.subTest(footer_like=footer_like):
                message = "\n\n".join(
                    [
                        "fix(agent): enforce commit message validation",
                        "context: Body paragraph 1.",
                        "change: Body paragraph 2.",
                        footer_like,
                    ]
                )
                self.assert_invalid(
                    message + "\n",
                    "unsupported or malformed footer paragraph",
                    "english",
                )

    def test_rejects_malformed_references_sections(self) -> None:
        valid_section = references("Issue: https://github.com/example/project/issues/1")
        cases = (
            (
                block() + "\n\nReferences:\n",
                "requires at least 1 entry",
            ),
            (
                block() + "\n" + valid_section + "\n",
                "exactly one blank line before it",
            ),
            (
                block() + "\n\nreferences:\n- https://example.com/reference\n",
                "heading must be exactly 'References:'",
            ),
            (
                block() + "\nReferences: https://example.com/reference\n",
                "heading must be exactly 'References:'",
            ),
            (
                block() + "\n\nReferences:\nIssue #1\n",
                "must use '- [label: ]http(s)://...'",
            ),
            (
                block() + "\n\nReferences:\n- Issue: example/project#1\n",
                "must use '- [label: ]http(s)://...'",
            ),
            (
                block() + "\n\nReferences:\n- Invalid: https://?missing-host\n",
                "must end with an absolute HTTP(S) URL",
            ),
            (
                block() + "\n\nReferences:\n- Invalid: https://[invalid\n",
                "must end with an absolute HTTP(S) URL",
            ),
            (
                block()
                + "\n\n"
                + references(
                    "https://example.com/reference",
                    "https://example.com/reference",
                )
                + "\n",
                "contains duplicate URL",
            ),
            (
                block()
                + "\n\n"
                + valid_section
                + "\n\n"
                + references("https://example.com/second")
                + "\n",
                "allows at most 1 References section",
            ),
        )
        for message, expected_error in cases:
            with self.subTest(expected_error=expected_error):
                self.assert_invalid(message, expected_error, "english")

    def test_rejects_references_before_the_final_body_paragraph(self) -> None:
        message = "\n\n".join(
            [
                "fix(agent): enforce commit message validation",
                "context: Body paragraph 1.",
                "change: Body paragraph 2.",
                references("https://example.com/reference"),
                "impact: Body paragraph 3.",
            ]
        )
        self.assert_invalid(
            message + "\n",
            "must use '- [label: ]http(s)://...'",
            "english",
        )

    def test_rejects_references_between_bilingual_blocks(self) -> None:
        local = block(
            "fix(agent): 强制校验提交信息",
            labels=CHINESE_BODY_LABELS,
        )
        message = (
            local
            + "\n\n"
            + references("https://example.com/reference")
            + "\n\n"
            + SEPARATOR
            + "\n\n"
            + block()
            + "\n"
        )
        self.assert_invalid(
            message,
            "must use '- [label: ]http(s)://...'",
        )

    def test_requires_ordered_language_appropriate_body_labels(self) -> None:
        legacy = "\n\n".join(
            [
                "fix(agent): enforce commit message validation",
                "Body paragraph 1.",
                "Body paragraph 2.",
                "Body paragraph 3.",
            ]
        )
        cases = (
            (
                legacy + "\n",
                "body paragraph 1 must start with 'context: '",
                "english",
            ),
            (
                block(labels=("change: ", "context: ", "impact: ")) + "\n",
                "body paragraph 1 must start with 'context: '",
                "english",
            ),
            (
                block(labels=("Context: ", "Change: ", "Impact: ")) + "\n",
                "body paragraph 1 must start with 'context: '",
                "english",
            ),
            (
                block(labels=("context: ", "change: ", "result: ")) + "\n",
                "body paragraph 3 must start with 'impact: '",
                "english",
            ),
            (
                block().replace("context: Body paragraph 1.", "context: ") + "\n",
                "must include content immediately after 'context: '",
                "english",
            ),
            (
                block().replace(
                    "context: Body paragraph 1.",
                    "context:  Body paragraph 1.",
                )
                + "\n",
                "must include content immediately after 'context: '",
                "english",
            ),
            (
                bilingual(
                    local=block(
                        "fix(agent): 强制校验提交信息",
                        labels=("背景：", "change: ", "影响："),
                    )
                ),
                "body paragraph 2 must start with '变更：'",
                "bilingual",
            ),
            (
                bilingual(english=block(labels=CHINESE_BODY_LABELS)),
                "English block: body paragraph 1 must start with 'context: '",
                "bilingual",
            ),
            (
                bilingual().replace(
                    "背景：Body paragraph 1.",
                    "背景： Body paragraph 1.",
                ),
                "must include content immediately after '背景：'",
                "bilingual",
            ),
        )
        for message, expected_error, mode in cases:
            with self.subTest(expected_error=expected_error):
                self.assert_invalid(message, expected_error, mode)

    def test_commit_validation_matches_expected_file(self) -> None:
        self.git("init", "--quiet")
        self.git("config", "user.name", "Git Commit Tests")
        self.git("config", "user.email", "tests@example.com")
        self.git("config", "commit.gpgsign", "false")
        message_path = self.root / "expected.txt"
        expected = bilingual().rstrip("\n")
        expected += (
            "\n\n"
            + references("Issue: https://example.com/issues/123")
            + "\n"
        )
        message_path.write_text(expected, encoding="utf-8")
        self.git("commit", "--quiet", "--allow-empty", "-F", str(message_path))

        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT),
                "--commit",
                "HEAD",
                "--expected-file",
                str(message_path),
                "--mode",
                "bilingual",
            ],
            cwd=self.root,
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

        self.assertEqual(result.returncode, 0, result.stderr)

        changed_message = bilingual().replace("Body paragraph 3.", "Changed.")
        message_path.write_text(changed_message, encoding="utf-8")
        mismatch = subprocess.run(
            [
                sys.executable,
                str(SCRIPT),
                "--commit",
                "HEAD",
                "--expected-file",
                str(message_path),
                "--mode",
                "bilingual",
            ],
            cwd=self.root,
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        self.assertNotEqual(mismatch.returncode, 0)
        self.assertIn("does not match", mismatch.stderr)

    def git(self, *arguments: str) -> str:
        """Run Git in the isolated fixture repository."""

        return subprocess.run(
            ["git", *arguments],
            cwd=self.root,
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        ).stdout.strip()


if __name__ == "__main__":
    unittest.main()
