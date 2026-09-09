#!/usr/bin/env python3
"""Behavior tests for canonical notes in GitHub Draft creation."""

from __future__ import annotations

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[3]
GITHUB = ROOT / "scripts/release/release-github.sh"
NOTES = ROOT / "scripts/release/release_notes.py"


class ReleaseGitHubNotesTests(unittest.TestCase):
    def test_draft_uses_only_frozen_changelog(self) -> None:
        version = "7.8.9"
        with tempfile.TemporaryDirectory() as directory:
            temporary = Path(directory)
            repository = temporary / "repository"
            tools = temporary / "tools"
            release_dir = repository / f".tmp/release/{version}"
            worktree = release_dir / "worktree"
            state = release_dir / "state"
            artifacts = release_dir / "artifacts"
            notes = worktree / f"changelog/{version}.md"
            for path in (tools, state, artifacts, notes.parent):
                path.mkdir(parents=True, exist_ok=True)
            notes.write_text("## What's Changed\n\n* One change\n", encoding="utf-8")
            subprocess.run(
                ["git", "init", "-b", "release", str(worktree)],
                check=True,
                capture_output=True,
                text=True,
            )
            subprocess.run(
                ["git", "config", "user.name", "Release Test"],
                cwd=worktree,
                check=True,
            )
            subprocess.run(
                ["git", "config", "user.email", "release@example.com"],
                cwd=worktree,
                check=True,
            )
            subprocess.run(
                ["git", "add", str(notes.relative_to(worktree))],
                cwd=worktree,
                check=True,
            )
            subprocess.run(
                ["git", "commit", "-m", "release notes"],
                cwd=worktree,
                check=True,
                capture_output=True,
                text=True,
            )
            for name in ("Easydict.zip", "Easydict.dmg", "SHA256SUMS.txt"):
                (artifacts / name).write_text(name, encoding="utf-8")
            (state / "release.env").write_text(
                "\n".join(
                    [
                        f"RELEASE_SAVED_VERSION={version}",
                        "RELEASE_SAVED_BUILD=42",
                        "RELEASE_SAVED_CHANNEL=beta",
                        f"RELEASE_VERSION_COMMIT={'1' * 40}",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )
            snapshot = subprocess.run(
                [
                    "python3",
                    str(NOTES),
                    "snapshot",
                    "--file",
                    str(notes),
                    "--version",
                    version,
                    "--state",
                    str(state / "release-notes.json"),
                ],
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertEqual(snapshot.returncode, 0, snapshot.stderr)

            calls = temporary / "gh-calls.log"
            existing_release = temporary / "existing-release"
            fake_gh = tools / "gh"
            fake_gh.write_text(
                """#!/bin/sh
printf '%s\\n' "$*" >> "$GH_CALLS"
if [ "$1 $2" = "release view" ]; then
    if [ -f "$EXISTING_RELEASE" ]; then
        case "$*" in
            *"--json isDraft"*) printf 'true\\n' ;;
            *"--json body,tagName,url"*)
                printf '{"tagName":"7.8.9","body":"drifted","url":"https://example.invalid"}\\n'
                ;;
        esac
        exit 0
    fi
    exit 1
fi
if [ "$1 $2" = "release create" ]; then
    exit 0
fi
exit 2
""",
                encoding="utf-8",
            )
            fake_gh.chmod(0o755)
            env = os.environ.copy()
            env.update(
                {
                    "PATH": f"{tools}:{env['PATH']}",
                    "GH_CALLS": str(calls),
                    "EXISTING_RELEASE": str(existing_release),
                    "RELEASE_SOURCE_ROOT": str(repository),
                    "RELEASE_REPOSITORY": "example/repository",
                    "VERSION": version,
                    "CHANNEL": "beta",
                    "DRAFT_MODE": "normal",
                }
            )
            result = subprocess.run(
                [str(GITHUB), "draft"],
                cwd=repository,
                env=env,
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            logged = calls.read_text(encoding="utf-8")
            self.assertIn(f"--notes-file {notes}", logged)
            self.assertNotIn("--generate-notes", logged)

            existing_release.touch()
            calls.write_text("", encoding="utf-8")
            remote_drift = subprocess.run(
                [str(GITHUB), "draft"],
                cwd=repository,
                env=env,
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertNotEqual(remote_drift.returncode, 0)
            self.assertIn(
                "GitHub Release body differs from canonical changelog",
                remote_drift.stderr,
            )
            remote_drift_calls = calls.read_text(encoding="utf-8")
            self.assertNotIn("release upload", remote_drift_calls)

            calls.write_text("", encoding="utf-8")
            notes.write_text("## Drifted\n", encoding="utf-8")
            drifted = subprocess.run(
                [str(GITHUB), "draft"],
                cwd=repository,
                env=env,
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertNotEqual(drifted.returncode, 0)
            self.assertIn(
                "unstaged release notes differ from the frozen release commit",
                drifted.stderr,
            )
            self.assertEqual(calls.read_text(encoding="utf-8"), "")


if __name__ == "__main__":
    unittest.main()
