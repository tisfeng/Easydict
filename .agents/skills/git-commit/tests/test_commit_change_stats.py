#!/usr/bin/env python3
"""Exercise commit change statistics against temporary Git repositories."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "commit-change-stats.py"


class TemporaryRepository:
    """Create commits used to validate the Git-facing statistics contract."""

    def __init__(self, root: Path) -> None:
        self.root = root
        self.git("init", "--quiet")
        self.git("config", "user.name", "Git Commit Tests")
        self.git("config", "user.email", "tests@example.com")
        self.git("config", "commit.gpgsign", "false")

    def git(self, *arguments: str) -> str:
        """Run Git in the temporary repository and return stdout."""

        result = subprocess.run(
            ["git", *arguments],
            cwd=self.root,
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        return result.stdout.strip()

    def write_text(self, relative_path: str, content: str) -> None:
        """Write a UTF-8 fixture file."""

        path = self.root / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")

    def write_bytes(self, relative_path: str, content: bytes) -> None:
        """Write a binary fixture file."""

        path = self.root / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)

    def commit(self, message: str, allow_empty: bool = False) -> str:
        """Commit all fixture changes and return the full object ID."""

        self.git("add", "--all")
        arguments = ["commit", "--quiet", "-m", message]
        if allow_empty:
            arguments.insert(1, "--allow-empty")
        self.git(*arguments)
        return self.git("rev-parse", "HEAD")

    def stats(
        self,
        revision: str = "HEAD",
        revision_range: str | None = None,
    ) -> subprocess.CompletedProcess[str]:
        """Run the statistics helper against this repository."""

        arguments = [sys.executable, str(SCRIPT)]
        if revision_range is not None:
            arguments.extend(["--range", revision_range])
        else:
            arguments.append(revision)
        return subprocess.run(
            arguments,
            cwd=self.root,
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )


class CommitChangeStatsTests(unittest.TestCase):
    """Verify observable statistics and failure behavior."""

    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.repository = TemporaryRepository(Path(self.temporary_directory.name))

    def payload(self, result: subprocess.CompletedProcess[str]) -> dict[str, object]:
        """Require success and decode one JSON report."""

        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def test_mixed_commit_ignores_binary_files(self) -> None:
        self.repository.commit("base", allow_empty=True)
        self.repository.write_text("Sources/App.swift", "one\ntwo\nthree\n")
        self.repository.write_text("docs/guide.md", "one\ntwo\n")
        self.repository.write_bytes("Assets/image.bin", b"\x00\x01\x02")
        commit = self.repository.commit("mixed")

        payload = self.payload(self.repository.stats(commit))

        self.assertEqual(payload["total"], self.counts(2, 5, 0))
        self.assertEqual(payload["code"], self.counts(1, 3, 0))
        self.assertEqual(payload["docs"], self.counts(1, 2, 0))
        self.assertNotIn("binaryFiles", payload)

    def test_classifies_document_names_and_directories(self) -> None:
        self.repository.commit("base", allow_empty=True)
        self.repository.write_text("README.md", "readme\n")
        self.repository.write_text("nested/SKILL.md", "skill\n")
        self.repository.write_text("Documentation/openapi.json", "{}\n")
        self.repository.write_text("Config/settings.json", "{}\n")
        self.repository.write_text("tools/helper.py", "pass\n")
        commit = self.repository.commit("classification")

        payload = self.payload(self.repository.stats(commit))

        self.assertEqual(payload["total"], self.counts(5, 5, 0))
        self.assertEqual(payload["code"], self.counts(2, 2, 0))
        self.assertEqual(payload["docs"], self.counts(3, 3, 0))

    def test_handles_rename_unicode_space_and_deletion(self) -> None:
        self.repository.write_text(
            "Sources/Old.swift",
            "swift-one\nswift-two\nswift-three\n",
        )
        self.repository.write_text("notes/设计 文档.md", "documentation-one\n")
        self.repository.commit("fixtures")

        (self.repository.root / "docs").mkdir()
        self.repository.git("mv", "notes/设计 文档.md", "docs/设计 新文档.md")
        self.repository.write_text(
            "docs/设计 新文档.md",
            "documentation-one\ndocumentation-two\n",
        )
        (self.repository.root / "Sources/Old.swift").unlink()
        commit = self.repository.commit("rename and delete")

        payload = self.payload(self.repository.stats(commit))

        self.assertEqual(payload["total"], self.counts(2, 1, 3))
        self.assertEqual(payload["code"], self.counts(1, 0, 3))
        self.assertEqual(payload["docs"], self.counts(1, 1, 0))

    def test_aggregates_a_three_dot_range(self) -> None:
        base = self.repository.commit("base", allow_empty=True)
        self.repository.write_text("Sources/App.swift", "code\n")
        self.repository.commit("code")
        self.repository.write_text("docs/guide.md", "one\ntwo\n")
        source = self.repository.commit("docs")

        payload = self.payload(
            self.repository.stats(revision_range=f"{base}...{source}")
        )

        self.assertEqual(payload["scope"], "range")
        self.assertEqual(payload["total"], self.counts(2, 3, 0))
        self.assertEqual(payload["code"], self.counts(1, 1, 0))
        self.assertEqual(payload["docs"], self.counts(1, 2, 0))

    def test_reports_zero_for_an_empty_commit(self) -> None:
        commit = self.repository.commit("empty", allow_empty=True)

        payload = self.payload(self.repository.stats(commit))

        self.assertEqual(payload["total"], self.counts(0, 0, 0))
        self.assertEqual(payload["code"], self.counts(0, 0, 0))
        self.assertEqual(payload["docs"], self.counts(0, 0, 0))

    def test_rejects_an_invalid_revision(self) -> None:
        self.repository.commit("base", allow_empty=True)

        result = self.repository.stats("missing-commit")

        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertIn("error:", result.stderr)

    @staticmethod
    def counts(files: int, insertions: int, deletions: int) -> dict[str, int]:
        """Build the expected category payload."""

        return {
            "deletions": deletions,
            "files": files,
            "insertions": insertions,
            "net": insertions - deletions,
        }


if __name__ == "__main__":
    unittest.main()
