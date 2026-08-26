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


def block(
    subject: str = "fix(agent): enforce commit message validation",
    body_count: int = 3,
    multiline: bool = False,
    footer: str | None = None,
) -> str:
    """Build one language block with a controlled paragraph count."""

    bodies = []
    for index in range(body_count):
        paragraph = f"Body paragraph {index + 1}."
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
        (local or block("fix(agent): 强制校验提交信息"))
        + before
        + separator
        + after
        + (english or block())
        + "\n"
    )


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

    def test_accepts_multiline_body_crlf_and_trailing_newlines(self) -> None:
        message = bilingual(
            local=block("fix(agent): 强制校验提交信息", multiline=True),
            english=block(multiline=True),
        ).replace("\n", "\r\n")
        self.assert_valid(message + "\r\n")

    def test_rejects_two_or_four_body_paragraphs(self) -> None:
        self.assert_invalid(
            bilingual(local=block("fix(agent): 强制校验提交信息", 2)),
            "Local-language block: expected exactly 3 body paragraphs, found 2",
        )
        self.assert_invalid(
            bilingual(english=block(body_count=4)),
            "English block: expected exactly 3 body paragraphs, found 4",
        )

    def test_reports_both_blocks_from_the_historical_bad_message(self) -> None:
        message = bilingual(
            local=block("feat(agent): 新增安全提交 PR 的本地技能", 2),
            english=block("feat(agent): add a safe local PR submission skill", 2),
        )
        result = self.run_validator(message)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Local-language block", result.stderr)
        self.assertIn("English block", result.stderr)
        self.assertIn("found 2", result.stderr)

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

    def test_rejects_incorrect_separator_spacing(self) -> None:
        self.assert_invalid(
            bilingual(before="\n", after="\n\n"),
            "exactly one blank line before and after",
        )
        self.assert_invalid(
            bilingual(before="\n\n\n", after="\n\n"),
            "exactly one blank line before and after",
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
        )
        english = block(
            "feat(agent)!: enforce commit message validation",
            footer="BREAKING CHANGE: The old commit flow is unsupported.",
        )
        self.assert_valid(bilingual(local=local, english=english))

        misplaced = "\n\n".join(
            [
                "fix(agent): enforce commit message validation",
                "Body paragraph 1.",
                "BREAKING CHANGE: misplaced.",
                "Body paragraph 2.",
                "Body paragraph 3.",
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
                        "Body paragraph 1.",
                        "Body paragraph 2.",
                        footer_like,
                    ]
                )
                self.assert_invalid(
                    message + "\n",
                    "unsupported or malformed footer paragraph",
                    "english",
                )

    def test_requires_matching_breaking_footer_presence(self) -> None:
        local = block(
            "feat(agent)!: 强制校验提交信息",
            footer="BREAKING CHANGE: 旧提交方式不再受支持。",
        )
        english = block("feat(agent)!: enforce commit message validation")

        self.assert_invalid(
            bilingual(local=local, english=english),
            "BREAKING CHANGE footer presence",
        )

    def test_commit_validation_matches_expected_file(self) -> None:
        self.git("init", "--quiet")
        self.git("config", "user.name", "Easydict Tests")
        self.git("config", "user.email", "tests@example.com")
        self.git("config", "commit.gpgsign", "false")
        message_path = self.root / "expected.txt"
        message_path.write_text(bilingual(), encoding="utf-8")
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

    def test_file_failure_does_not_change_git_state(self) -> None:
        self.git("init", "--quiet")
        self.git("config", "user.name", "Easydict Tests")
        self.git("config", "user.email", "tests@example.com")
        self.git("config", "commit.gpgsign", "false")
        self.git("commit", "--quiet", "--allow-empty", "-m", "base")
        before_head = self.git("rev-parse", "HEAD")
        before_index = self.git("write-tree")

        result = self.run_validator(block(body_count=2) + "\n", "english")

        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.git("rev-parse", "HEAD"), before_head)
        self.assertEqual(self.git("write-tree"), before_index)

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
