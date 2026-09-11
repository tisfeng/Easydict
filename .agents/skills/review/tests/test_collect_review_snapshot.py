"""Behavior tests for the review snapshot collector CLI.

Every repository in this module is created below a temporary directory.  The
tests deliberately invoke Git with a blank global/system configuration so that
aliases, hooks, attributes, and user settings on the developer machine cannot
affect the snapshot evidence being asserted.
"""

from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = (
    Path(__file__).resolve().parents[1] / "scripts" / "collect_review_snapshot.py"
)
EMPTY_TREE_SHA = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"


class CollectReviewSnapshotTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.root = Path(self.temporary_directory.name)
        self.repository = self.root / "repo"
        self._git("init", "--initial-branch=main", self.repository)
        self._git("config", "user.name", "Snapshot Test", cwd=self.repository)
        self._git("config", "user.email", "snapshot-test@example.invalid", cwd=self.repository)
        self._git("config", "core.hooksPath", str(self.root / "no-hooks"), cwd=self.repository)

    def git_environment(self) -> dict[str, str]:
        environment = os.environ.copy()
        environment.update(
            {
                "GIT_CONFIG_GLOBAL": os.devnull,
                "GIT_CONFIG_NOSYSTEM": "1",
                "GIT_TERMINAL_PROMPT": "0",
            }
        )
        return environment

    def _git(self, *arguments: str, cwd: Path | None = None) -> str:
        completed = subprocess.run(
            ["git", *arguments],
            cwd=cwd,
            env=self.git_environment(),
            text=True,
            encoding="utf-8",
            errors="surrogateescape",
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)
        return completed.stdout

    def git_metadata(self) -> tuple[bytes, dict[str, bytes]]:
        git_directory = self.repository / ".git"
        files = {"HEAD": (git_directory / "HEAD").read_bytes()}
        for candidate in (git_directory / "refs").rglob("*"):
            if candidate.is_file():
                files[str(candidate.relative_to(git_directory))] = candidate.read_bytes()
        packed_refs = git_directory / "packed-refs"
        if packed_refs.exists():
            files["packed-refs"] = packed_refs.read_bytes()
        return (git_directory / "index").read_bytes(), files

    def write(self, relative_path: str, content: str | bytes) -> Path:
        destination = self.repository / relative_path
        destination.parent.mkdir(parents=True, exist_ok=True)
        if isinstance(content, bytes):
            destination.write_bytes(content)
        else:
            destination.write_text(content, encoding="utf-8", errors="surrogateescape")
        return destination

    def commit(self, message: str) -> str:
        self._git("add", "--all", cwd=self.repository)
        self._git("commit", "-m", message, cwd=self.repository)
        return self._git("rev-parse", "HEAD", cwd=self.repository).strip()

    def collect(
        self, *arguments: str, repository: Path | None = None
    ) -> tuple[subprocess.CompletedProcess[str], dict[str, object]]:
        completed = subprocess.run(
            [sys.executable, str(SCRIPT), "--repo", str(repository or self.repository), *arguments],
            cwd=self.root,
            env=self.git_environment(),
            text=True,
            encoding="utf-8",
            errors="surrogateescape",
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        self.assertEqual(completed.stderr, "", completed.stderr)
        try:
            payload = json.loads(completed.stdout)
        except json.JSONDecodeError as error:
            self.fail(f"stdout must be one JSON value: {error}: {completed.stdout!r}")
        self.assertIsInstance(payload, dict)
        return completed, payload

    def success(self, *arguments: str, repository: Path | None = None) -> dict[str, object]:
        completed, payload = self.collect(*arguments, repository=repository)
        self.assertEqual(completed.returncode, 0, payload)
        self.assertNotIn("error", payload)
        self.assertEqual(payload["schema_version"], 1)
        return payload

    def failure(self, *arguments: str, repository: Path | None = None) -> dict[str, object]:
        completed, payload = self.collect(*arguments, repository=repository)
        self.assertNotEqual(completed.returncode, 0)
        self.assertIsInstance(payload.get("error"), str)
        return payload

    def actual_patch(self, base: str, target: str, *paths: str) -> str:
        return self._git(
            "-c",
            "core.quotePath=true",
            "diff",
            "--no-ext-diff",
            "--no-textconv",
            "--no-color",
            "--no-relative",
            "--find-renames=50%",
            "--ignore-submodules=none",
            "--diff-algorithm=myers",
            "--no-indent-heuristic",
            "--patch",
            "--binary",
            "--full-index",
            "--unified=5",
            "--src-prefix=a/",
            "--dst-prefix=b/",
            base,
            target,
            "--",
            *paths,
            cwd=self.repository,
        )

    def assert_patch_matches_git(self, payload: dict[str, object], base: str, target: str) -> None:
        patch = payload["patch"]
        self.assertIsInstance(patch, dict)
        expected = self.actual_patch(base, target)
        self.assertEqual(patch["text"], expected)
        self.assertEqual(patch["total_chars"], len(expected))
        self.assertEqual(patch["total_bytes"], len(expected.encode("utf-8", "surrogateescape")))
        self.assertEqual(
            patch["sha256"],
            hashlib.sha256(expected.encode("utf-8", "surrogateescape")).hexdigest(),
        )

    def test_root_commit_uses_the_empty_tree_and_normal_commit_uses_parent_one(self) -> None:
        self.write("root.txt", "root\n")
        root = self.commit("root")
        root_payload = self.success("--commit", root)
        root_snapshot = root_payload["snapshot"]
        self.assertEqual(root_snapshot["kind"], "commit")
        self.assertEqual(root_snapshot["base_sha"], EMPTY_TREE_SHA)
        self.assertEqual(root_snapshot["target_sha"], root)
        self.assertIsNone(root_snapshot["parent"])
        self.assert_patch_matches_git(root_payload, EMPTY_TREE_SHA, root)

        self.write("root.txt", "normal\n")
        normal = self.commit("normal")
        payload = self.success("--commit", normal)
        snapshot = payload["snapshot"]
        self.assertEqual(snapshot["parent"], 1)
        self.assertEqual(snapshot["base_sha"], root)
        self.assertEqual(snapshot["target_sha"], normal)
        self.assert_patch_matches_git(payload, root, normal)

    def test_merge_requires_explicit_parent_and_selected_parent_changes_evidence(self) -> None:
        self.write("base.txt", "base\n")
        self.commit("base")
        self._git("switch", "-c", "side", cwd=self.repository)
        self.write("side.txt", "side\n")
        side = self.commit("side")
        self._git("switch", "main", cwd=self.repository)
        self.write("main.txt", "main\n")
        first_parent = self.commit("main")
        self._git("merge", "--no-ff", "side", "-m", "merge side", cwd=self.repository)
        merge = self._git("rev-parse", "HEAD", cwd=self.repository).strip()

        self.failure("--commit", merge)
        parent_one = self.success("--commit", merge, "--parent", "1")
        parent_two = self.success("--commit", merge, "--parent", "2")
        self.assertEqual(parent_one["snapshot"]["base_sha"], first_parent)
        self.assertEqual(parent_two["snapshot"]["base_sha"], side)
        self.assert_patch_matches_git(parent_one, first_parent, merge)
        self.assert_patch_matches_git(parent_two, side, merge)
        self.assertNotEqual(parent_one["patch"]["sha256"], parent_two["patch"]["sha256"])
        self.failure("--commit", merge, "--parent", "3")

    def test_double_dot_and_triple_dot_ranges_freeze_different_bases(self) -> None:
        self.write("base.txt", "base\n")
        root = self.commit("base")
        self._git("switch", "-c", "feature", cwd=self.repository)
        self.write("feature.txt", "feature\n")
        target = self.commit("feature")
        self._git("switch", "main", cwd=self.repository)
        self.write("main.txt", "main\n")
        left = self.commit("main")

        endpoints = self.success("--range", f"{left}..{target}")
        merge_base = self.success("--range", f"{left}...{target}")
        endpoint_snapshot = endpoints["snapshot"]
        merge_base_snapshot = merge_base["snapshot"]
        self.assertEqual(endpoint_snapshot["range_mode"], "endpoints")
        self.assertEqual(endpoint_snapshot["left_sha"], left)
        self.assertEqual(endpoint_snapshot["base_sha"], left)
        self.assertEqual(endpoint_snapshot["target_sha"], target)
        self.assertEqual(merge_base_snapshot["range_mode"], "merge-base")
        self.assertEqual(merge_base_snapshot["left_sha"], left)
        self.assertEqual(merge_base_snapshot["base_sha"], root)
        self.assertEqual(merge_base_snapshot["target_sha"], target)
        self.assert_patch_matches_git(endpoints, left, target)
        self.assert_patch_matches_git(merge_base, root, target)
        self.assertNotEqual(endpoints["patch"]["sha256"], merge_base["patch"]["sha256"])

    def test_triple_dot_rejects_criss_cross_multiple_merge_bases(self) -> None:
        self.write("base.txt", "base\n")
        self.commit("base")
        self._git("switch", "-c", "left", cwd=self.repository)
        self.write("left.txt", "left\n")
        left_tip = self.commit("left")
        self._git("switch", "-c", "right", "main", cwd=self.repository)
        self.write("right.txt", "right\n")
        right_tip = self.commit("right")

        self._git("switch", "left", cwd=self.repository)
        self._git("merge", "--no-ff", "right", "-m", "left merges right", cwd=self.repository)
        left_merge = self._git("rev-parse", "HEAD", cwd=self.repository).strip()
        self._git("switch", "right", cwd=self.repository)
        self._git("merge", "--no-ff", left_tip, "-m", "right merges left", cwd=self.repository)
        right_merge = self._git("rev-parse", "HEAD", cwd=self.repository).strip()

        merge_bases = self._git("merge-base", "--all", left_merge, right_merge, cwd=self.repository)
        self.assertEqual(set(merge_bases.splitlines()), {left_tip, right_tip})
        self.failure("--range", f"{left_merge}...{right_merge}")

    def test_invalid_refs_ranges_and_unsafe_pathspecs_are_json_errors(self) -> None:
        self.write("tracked.txt", "tracked\n")
        commit = self.commit("tracked")
        self.failure("--commit", "does-not-exist")
        self.failure("--range", "not-a-range")
        self.failure("--range", f"{commit}....{commit}")
        self.failure("--commit", commit, "--path", "../outside")
        self.failure("--commit", commit, "--path", "/absolute")
        literal_magic = self.success("--commit", commit, "--path", ":(top)tracked.txt")
        self.assertEqual(literal_magic["snapshot"]["paths"], [":(top)tracked.txt"])
        self.assertEqual(literal_magic["changes"], [])
        self.assertEqual(literal_magic["patch"]["text"], "")
        self.failure("--commit", commit, "--patch-offset", "-1")
        self.failure("--commit", commit, "--patch-chars", "0")

    def test_dirty_staged_and_untracked_workspace_state_never_enters_commit_patch(self) -> None:
        self.write("tracked.txt", "before\n")
        base = self.commit("base")
        self.write("tracked.txt", "committed\n")
        target = self.commit("target")
        expected = self.actual_patch(base, target)

        self.write("tracked.txt", "unstaged only\n")
        self.write("staged.txt", "staged only\n")
        self._git("add", "staged.txt", cwd=self.repository)
        self.write("untracked.txt", "untracked only\n")
        before_index, before_metadata = self.git_metadata()
        before_staged = self._git("diff", "--cached", "--binary", cwd=self.repository)
        before_unstaged = self._git("diff", "--binary", cwd=self.repository)
        before_untracked = self._git(
            "ls-files", "--others", "--exclude-standard", "-z", cwd=self.repository
        )
        before_contents = {
            path: (self.repository / path).read_bytes()
            for path in ("tracked.txt", "staged.txt", "untracked.txt")
        }
        payload = self.success("--commit", target)
        self.assert_patch_matches_git(payload, base, target)
        self.assertEqual(payload["patch"]["text"], expected)
        self.assertTrue(payload["checkout"]["dirty"])
        self.assertIsInstance(payload["checkout"]["head_sha"], str)
        self.assertIsInstance(payload["checkout"]["status_sha256"], str)
        self.assertEqual(self.git_metadata(), (before_index, before_metadata))
        self.assertEqual(
            self._git("diff", "--cached", "--binary", cwd=self.repository), before_staged
        )
        self.assertEqual(self._git("diff", "--binary", cwd=self.repository), before_unstaged)
        self.assertEqual(
            self._git("ls-files", "--others", "--exclude-standard", "-z", cwd=self.repository),
            before_untracked,
        )
        self.assertEqual(
            {path: (self.repository / path).read_bytes() for path in before_contents},
            before_contents,
        )

    def test_literal_special_path_rename_delete_mode_binary_and_unicode_paginate_losslessly(self) -> None:
        special = "literal [*] ? name.txt"
        shared = "".join(f"shared line {index}\n" for index in range(20))
        self.write(special, shared + "before\n")
        self.write("deleted.txt", "delete\n")
        executable = self.write("script.sh", "#!/bin/sh\necho one\n")
        executable.chmod(0o644)
        self.write("binary.bin", b"\x00first\xff\n")
        self.write("raw-text.txt", b"before \xff\n")
        unusual_name = "tab\tand\nnewline.txt"
        self.write(unusual_name, "before\n")
        link_name = "link\tand\nnewline"
        os.symlink("initial-link-target", self.repository / link_name)
        base = self.commit("base")

        self._git("mv", special, "renamed [*] ? name.txt", cwd=self.repository)
        self.write("renamed [*] ? name.txt", shared + "after \u96ea\n")
        (self.repository / "deleted.txt").unlink()
        executable.chmod(0o755)
        self.write("binary.bin", b"\x00second\xfe\n")
        self.write("raw-text.txt", b"after \xfe\n")
        self.write(unusual_name, "after\n")
        (self.repository / link_name).unlink()
        os.symlink("updated-link-target", self.repository / link_name)
        target = self.commit("rename delete mode binary")

        completed, full = self.collect("--commit", target)
        self.assertEqual(completed.returncode, 0, full)
        self.assertIn("\\udcfe", completed.stdout)
        self.assert_patch_matches_git(full, base, target)
        changes = full["changes"]
        self.assertEqual({change["status"][0] for change in changes}, {"R", "D", "M"})
        renamed = next(change for change in changes if change["status"].startswith("R"))
        self.assertEqual(renamed["old_path"], special)
        self.assertEqual(renamed["path"], "renamed [*] ? name.txt")
        mode_change = next(change for change in changes if change["path"] == "script.sh")
        self.assertEqual(mode_change["old_mode"], "100644")
        self.assertEqual(mode_change["new_mode"], "100755")
        unusual_change = next(change for change in changes if change["path"] == unusual_name)
        self.assertEqual(unusual_change["old_mode"], "100644")
        self.assertEqual(unusual_change["new_mode"], "100644")
        symlink_change = next(change for change in changes if change["path"] == link_name)
        self.assertEqual(symlink_change["old_mode"], "120000")
        self.assertEqual(symlink_change["new_mode"], "120000")

        chunks: list[str] = []
        offset = 0
        while True:
            page = self.success("--commit", target, "--patch-offset", str(offset), "--patch-chars", "257")
            patch = page["patch"]
            self.assertEqual(patch["offset"], offset)
            chunks.append(patch["text"])
            next_offset = patch["next_offset"]
            if next_offset is None:
                self.assertFalse(patch["complete"])
                self.assertEqual(patch["end"], patch["total_chars"])
                break
            self.assertFalse(patch["complete"])
            self.assertEqual(next_offset, patch["end"])
            self.assertGreater(next_offset, offset)
            offset = next_offset
        self.assertEqual("".join(chunks), full["patch"]["text"])

        filtered = self.success("--commit", target, "--path", "renamed [*] ? name.txt")
        self.assertEqual(filtered["snapshot"]["paths"], ["renamed [*] ? name.txt"])
        self.assertEqual(len(filtered["changes"]), 1)
        self.assertEqual(filtered["changes"][0]["path"], "renamed [*] ? name.txt")
        self.assertEqual(
            filtered["patch"]["text"],
            self.actual_patch(base, target, "renamed [*] ? name.txt"),
        )

    def test_pr_range_checks_committed_whitespace_even_with_a_clean_checkout(self) -> None:
        self.write("file.txt", "base\n")
        base = self.commit("base")
        self.write("file.txt", "trailing spaces   \n")
        head = self.commit("PR change")
        snapshot = self.success("--range", f"{base}...{head}")
        self.assertEqual(snapshot["snapshot"]["base_sha"], base)
        self.assertFalse(snapshot["checkout"]["dirty"])
        self.assertEqual(self._git("diff", "--check", cwd=self.repository), "")
        check = subprocess.run(
            ["git", "diff", "--check", snapshot["snapshot"]["base_sha"],
             snapshot["snapshot"]["target_sha"]], cwd=self.repository,
            env=self.git_environment(), capture_output=True, text=True, check=False,
        )
        self.assertNotEqual(check.returncode, 0)
        self.assertIn("trailing whitespace", check.stdout)
        self.assertIn("file.txt:1", check.stdout)

    def test_shallow_commit_with_an_unavailable_parent_is_an_error(self) -> None:
        self.write("tracked.txt", "base\n")
        self.commit("base")
        self.write("tracked.txt", "target\n")
        target = self.commit("target")
        shallow = self.root / "shallow"
        self._git("clone", "--depth=1", f"file://{self.repository}", shallow, cwd=self.root)
        self.assertEqual(self._git("rev-parse", "HEAD", cwd=shallow).strip(), target)
        self.failure("--commit", target, repository=shallow)

    def test_verification_is_stable_across_ref_spelling_and_workspace_changes_but_detects_ref_move(self) -> None:
        self.write("tracked.txt", "base\n")
        self.commit("base")
        self.write("tracked.txt", "target\n")
        target = self.commit("target")
        self._git("branch", "review-target", target, cwd=self.repository)
        collected = self.success("--commit", "review-target")
        fingerprint = collected["snapshot"]["fingerprint"]

        verified_sha = self.success("--commit", target, "--expected-fingerprint", fingerprint)
        self.assertEqual(verified_sha["mode"], "verify")
        self.assertEqual(verified_sha["state"], "unchanged")
        self.assertEqual(verified_sha["snapshot"]["fingerprint"], fingerprint)
        self.assertNotIn("changes", verified_sha)
        self.assertNotIn("patch", verified_sha)

        self.write("tracked.txt", "dirty workspace\n")
        unchanged = self.success("--commit", "review-target", "--expected-fingerprint", fingerprint)
        self.assertEqual(unchanged["state"], "unchanged")
        self.assertTrue(unchanged["checkout"]["dirty"])

        self.write("next.txt", "next\n")
        moved = self.commit("next")
        self._git("branch", "-f", "review-target", moved, cwd=self.repository)
        changed = self.success("--commit", "review-target", "--expected-fingerprint", fingerprint)
        self.assertEqual(changed["mode"], "verify")
        self.assertEqual(changed["state"], "changed")
        self.assertNotEqual(changed["snapshot"]["fingerprint"], fingerprint)
        self.assertIn("changes", changed)
        self.assertIn("patch", changed)


if __name__ == "__main__":
    unittest.main()
