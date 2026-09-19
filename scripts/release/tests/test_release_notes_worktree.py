#!/usr/bin/env python3
"""Behavior tests for release-worktree changelog freezing."""

from __future__ import annotations

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[3]
COMMON = ROOT / "scripts/release/release-common.sh"


def run(command, *, cwd=None, env=None, check=True):
    result = subprocess.run(
        command,
        cwd=cwd,
        env=env,
        check=False,
        text=True,
        capture_output=True,
    )
    if check and result.returncode != 0:
        raise AssertionError(
            f"command failed: {command}\nstdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return result


class ReleaseNotesWorktreeTests(unittest.TestCase):
    version = "7.8.9"
    original_notes = "## What's Changed\n\n* Test release\n"

    def make_environment(self, directory: Path, *, tracked: bool) -> tuple[dict[str, str], Path]:
        repository = directory / "repository"
        worktree = repository / f".tmp/release/{self.version}/worktree"
        notes = worktree / f"changelog/{self.version}.md"
        notes.parent.mkdir(parents=True)
        run(["git", "init", "-b", "release", str(worktree)])
        run(["git", "config", "user.name", "Release Test"], cwd=worktree)
        run(["git", "config", "user.email", "release@example.com"], cwd=worktree)
        notes.write_text(self.original_notes, encoding="utf-8")
        if tracked:
            run(["git", "add", str(notes.relative_to(worktree))], cwd=worktree)
            run(["git", "commit", "-m", "release notes"], cwd=worktree)
        env = os.environ.copy()
        env.update(
            {
                "RELEASE_SOURCE_ROOT": str(repository),
                "VERSION": self.version,
                "CHANNEL": "beta",
            }
        )
        return env, notes

    def invoke(self, action: str, *, cwd: Path, env: dict[str, str]):
        return run(
            ["bash", "-c", f'source "$1"; {action}', "bash", str(COMMON)],
            cwd=cwd,
            env=env,
            check=False,
        )

    def test_snapshot_rejects_untracked_notes(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            temporary = Path(directory)
            env, _ = self.make_environment(temporary, tracked=False)
            result = self.invoke("snapshot_release_notes", cwd=temporary, env=env)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("release notes are not tracked", result.stderr)

    def test_snapshot_rejects_staged_and_unstaged_drift(self) -> None:
        for staged in (False, True):
            with self.subTest(staged=staged), tempfile.TemporaryDirectory() as directory:
                temporary = Path(directory)
                env, notes = self.make_environment(temporary, tracked=True)
                clean = self.invoke("snapshot_release_notes", cwd=temporary, env=env)
                self.assertEqual(clean.returncode, 0, clean.stderr)

                notes.write_text("## Drifted\n", encoding="utf-8")
                if staged:
                    run(["git", "add", str(notes)], cwd=notes.parents[1])
                result = self.invoke(
                    "verify_release_notes_snapshot", cwd=temporary, env=env
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("release notes differ", result.stderr)

    def test_snapshot_rejects_staged_drift_hidden_by_worktree(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            temporary = Path(directory)
            env, notes = self.make_environment(temporary, tracked=True)
            notes.write_text("## Staged drift\n", encoding="utf-8")
            run(["git", "add", str(notes)], cwd=notes.parents[1])
            notes.write_text(self.original_notes, encoding="utf-8")

            result = self.invoke("snapshot_release_notes", cwd=temporary, env=env)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn(
                "staged release notes differ from the frozen release commit",
                result.stderr,
            )


if __name__ == "__main__":
    unittest.main()
