#!/usr/bin/env python3
"""Exercise compact integration facts against temporary Git repositories."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = (
    Path(__file__).resolve().parents[1]
    / "scripts"
    / "collect-integration-facts.py"
)
SPEC = importlib.util.spec_from_file_location("collect_integration_facts", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
collect_integration_facts = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = collect_integration_facts
SPEC.loader.exec_module(collect_integration_facts)


class TemporaryRepository:
    """Create source and target checkouts for observable behavior tests."""

    def __init__(self, root: Path) -> None:
        self.root = root
        self.repo = root / "source"
        self.git(root, "init", "--quiet", "--initial-branch=main", str(self.repo))
        self.git(self.repo, "config", "user.name", "Integration Facts Tests")
        self.git(self.repo, "config", "user.email", "tests@example.com")
        self.git(self.repo, "config", "commit.gpgsign", "false")
        hooks = root / "empty-hooks"
        hooks.mkdir()
        self.git(self.repo, "config", "core.hooksPath", str(hooks))
        self.write("base.txt", "base\n")
        self.write("old.txt", "old\n")
        self.write("shared.txt", "base\n")
        self.commit("chore: seed repository")
        self.git(self.repo, "switch", "--quiet", "-c", "feature")

    @staticmethod
    def git(path: Path, *arguments: str, check: bool = True) -> str:
        """Run Git and return stdout."""

        result = subprocess.run(
            ["git", "-C", str(path), *arguments],
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        if check and result.returncode:
            raise AssertionError(
                f"git failed: {arguments!r}\nstdout:\n{result.stdout}\nstderr:\n{result.stderr}"
            )
        return result.stdout.strip()

    def write(self, name: str, content: str, path: Path | None = None) -> Path:
        """Write one UTF-8 fixture file."""

        destination = (path or self.repo) / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(content, encoding="utf-8")
        return destination

    def commit(self, message: str, path: Path | None = None) -> str:
        """Commit all fixture changes and return the full OID."""

        repository = path or self.repo
        self.git(repository, "add", "--all")
        self.git(repository, "commit", "--quiet", "-m", message)
        return self.git(repository, "rev-parse", "HEAD")

    def feature_commit(self, name: str = "feature.txt") -> str:
        """Create one source-only commit."""

        self.write(name, "feature\n")
        return self.commit("feat: add feature evidence")

    def add_target_worktree(self, name: str = "target") -> Path:
        """Checkout main into another worktree."""

        target = self.root / name
        self.git(self.repo, "worktree", "add", "--quiet", str(target), "main")
        return target

    def inspect(
        self,
        *,
        target: str | None = "main",
        source_branch: str | None = None,
    ) -> tuple[subprocess.CompletedProcess[str], dict[str, object]]:
        """Run the helper and decode its single JSON object."""

        arguments = [sys.executable, str(SCRIPT), "--source", str(self.repo)]
        if target is not None:
            arguments.extend(["--target", target])
        if source_branch is not None:
            arguments.extend(["--source-branch", source_branch])
        result = subprocess.run(
            arguments,
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        raw = result.stdout if result.stdout else result.stderr
        try:
            payload = json.loads(raw)
        except json.JSONDecodeError as error:
            raise AssertionError(
                f"helper did not emit JSON\nstdout:\n{result.stdout}\nstderr:\n{result.stderr}"
            ) from error
        return result, payload


class CollectIntegrationFactsTests(unittest.TestCase):
    """Verify read-only, compact, exact integration evidence."""

    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.fixture = TemporaryRepository(Path(self.temporary.name))

    def assert_success(
        self, result: subprocess.CompletedProcess[str], payload: dict[str, object]
    ) -> None:
        """Require one stable versioned snapshot."""

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(payload["schema_version"], 1)
        self.assertTrue(payload["stable"])
        self.assertEqual(payload["changed_fields"], [])

    def test_explicit_target_reports_only_exact_target_checkout_and_is_read_only(self) -> None:
        source_commit = self.fixture.feature_commit()
        target = self.fixture.add_target_worktree()
        other = self.fixture.root / "other"
        self.fixture.git(self.fixture.repo, "branch", "other")
        self.fixture.git(
            self.fixture.repo, "worktree", "add", "--quiet", str(other), "other"
        )
        before = {
            "head": self.fixture.git(self.fixture.repo, "rev-parse", "HEAD"),
            "status": self.fixture.git(
                self.fixture.repo, "status", "--porcelain=v1", "-z"
            ),
            "worktrees": self.fixture.git(
                self.fixture.repo, "worktree", "list", "--porcelain"
            ),
        }

        result, payload = self.fixture.inspect()

        self.assert_success(result, payload)
        self.assertEqual(payload["target_resolution"], {"kind": "explicit"})
        self.assertEqual(payload["target"]["selected"], str(target.resolve()))
        self.assertEqual(len(payload["target"]["checkouts"]), 1)
        self.assertNotIn(str(other), result.stdout)
        self.assertEqual(payload["range"]["commits"], [source_commit])
        self.assertEqual(
            self.fixture.git(self.fixture.repo, "rev-parse", "HEAD"), before["head"]
        )
        self.assertEqual(
            self.fixture.git(self.fixture.repo, "status", "--porcelain=v1", "-z"),
            before["status"],
        )
        self.assertEqual(
            self.fixture.git(self.fixture.repo, "worktree", "list", "--porcelain"),
            before["worktrees"],
        )

    def test_same_source_and_target_does_not_duplicate_source_status(self) -> None:
        self.fixture.git(self.fixture.repo, "switch", "--quiet", "main")
        self.fixture.write("untracked.txt", "content\n")

        result, payload = self.fixture.inspect()

        self.assert_success(result, payload)
        self.assertEqual(payload["mode"], "direct-commit")
        self.assertTrue(payload["target"]["source_is_target"])
        self.assertNotIn("checkouts", payload["target"])
        self.assertNotIn("range", payload)
        self.assertEqual(len(payload["source"]["status"]), 1)
        self.assertEqual(result.stdout.count("untracked.txt"), 1)

        first_fingerprint = payload["source"]["content_fingerprint"]
        self.fixture.write("untracked.txt", "changed with the same status\n")
        result, payload = self.fixture.inspect()
        self.assert_success(result, payload)
        self.assertNotEqual(
            payload["source"]["content_fingerprint"], first_fingerprint
        )

    def test_fingerprint_detects_raw_tracked_bytes_hidden_by_clean_filter(self) -> None:
        filter_script = self.fixture.root / "normalize.py"
        filter_script.write_text(
            "import sys\n"
            "data = sys.stdin.buffer.read()\n"
            "sys.stdout.buffer.write(data.replace(b'raw-one', b'normalized').replace(b'raw-two', b'normalized'))\n",
            encoding="utf-8",
        )
        self.fixture.git(
            self.fixture.repo,
            "config",
            "filter.normalize.clean",
            f"{sys.executable} {filter_script}",
        )
        self.fixture.write(".gitattributes", "filtered.txt filter=normalize\n")
        self.fixture.write("filtered.txt", "raw-one\n")
        self.fixture.commit("test: add filtered fixture")
        self.fixture.write("filtered.txt", "raw-one changed\n")

        result, first = self.fixture.inspect()
        self.assert_success(result, first)
        first_status = first["source"]["status"]
        first_fingerprint = first["source"]["content_fingerprint"]

        self.fixture.write("filtered.txt", "raw-two changed\n")
        result, second = self.fixture.inspect()
        self.assert_success(result, second)
        self.assertEqual(second["source"]["status"], first_status)
        self.assertNotEqual(
            second["source"]["content_fingerprint"], first_fingerprint
        )

    def test_dirty_source_and_targets_preserve_untracked_and_rename_records(self) -> None:
        self.fixture.feature_commit()
        target = self.fixture.add_target_worktree()
        self.fixture.write("source-untracked.txt", "source\n")
        self.fixture.git(self.fixture.repo, "mv", "old.txt", "renamed.txt")
        self.fixture.write("target-untracked.txt", "target\n", path=target)

        result, payload = self.fixture.inspect()

        self.assert_success(result, payload)
        source_status = payload["source"]["status"]
        self.assertIn(
            {"index": "?", "worktree": "?", "path": "source-untracked.txt"},
            source_status,
        )
        rename = next(item for item in source_status if item["index"] == "R")
        self.assertEqual(rename["path"], "renamed.txt")
        self.assertEqual(rename["original_path"], "old.txt")
        target_status = payload["target"]["checkouts"][0]["status"]
        self.assertIn(
            {"index": "?", "worktree": "?", "path": "target-untracked.txt"},
            target_status,
        )
        self.assertIsNone(payload["target"]["selected"])

    def test_range_includes_reverted_renamed_and_newline_paths(self) -> None:
        first = self.fixture.feature_commit("reverted.txt")
        (self.fixture.repo / "reverted.txt").unlink()
        second = self.fixture.commit("fix: remove intermediate file")
        self.fixture.git(self.fixture.repo, "mv", "old.txt", "renamed.txt")
        third = self.fixture.commit("refactor: rename evidence file")
        self.fixture.write("odd\nname.txt", "newline\n")
        fourth = self.fixture.commit("test: add newline path")

        result, payload = self.fixture.inspect()

        self.assert_success(result, payload)
        self.assertEqual(
            payload["range"]["commits"], [first, second, third, fourth]
        )
        self.assertEqual(
            payload["range"]["paths"],
            sorted(["old.txt", "odd\nname.txt", "renamed.txt", "reverted.txt"]),
        )

    def test_merge_operation_is_reported_without_mutating_conflict_state(self) -> None:
        self.fixture.write("shared.txt", "feature\n")
        self.fixture.commit("feat: edit shared file")
        target = self.fixture.add_target_worktree()
        self.fixture.write("shared.txt", "main\n", path=target)
        self.fixture.commit("fix: edit shared file", path=target)
        merge = subprocess.run(
            ["git", "-C", str(self.fixture.repo), "merge", "main"],
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        self.assertNotEqual(merge.returncode, 0)

        result, payload = self.fixture.inspect()

        self.assert_success(result, payload)
        self.assertIn("MERGE_HEAD", payload["source"]["operations"])
        self.assertTrue(
            any(item["index"] == "U" for item in payload["source"]["status"])
        )


if __name__ == "__main__":
    unittest.main()
