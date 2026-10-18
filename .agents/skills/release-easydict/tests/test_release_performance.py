"""Focused tests for release timing and build-cache safety helpers."""

from __future__ import annotations

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[4]
COMMON = ROOT / ".agents/skills/release-easydict/scripts/release-common.sh"
BUILD_SCRIPT = ROOT / ".agents/skills/release-easydict/scripts/release-build.sh"


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


class ReleasePerformanceTests(unittest.TestCase):
    version = "7.8.9"

    def make_environment(self, directory: Path) -> tuple[dict[str, str], Path]:
        repository = directory / "repository"
        run(["git", "init", "-b", "dev", str(repository)])
        run(["git", "config", "user.name", "Release Test"], cwd=repository)
        run(
            ["git", "config", "user.email", "release@example.com"],
            cwd=repository,
        )
        (repository / ".agents/skills/release-easydict/scripts").mkdir(
            parents=True
        )
        (repository / ".agents/skills/release-easydict/assets").mkdir()
        (repository / "Easydict.xcodeproj").mkdir()
        (repository / "Easydict.xcworkspace/xcshareddata/swiftpm").mkdir(
            parents=True
        )
        (repository / "Easydict.xcodeproj/project.pbxproj").write_text(
            "MARKETING_VERSION = 1.0.0;\nCURRENT_PROJECT_VERSION = 1;\n",
            encoding="utf-8",
        )
        (repository / "Easydict.xcworkspace/xcshareddata/swiftpm/Package.resolved").write_text(
            "{\"pins\": []}\n", encoding="utf-8"
        )
        (repository / ".agents/skills/release-easydict/scripts/asc-workflow.json").write_text(
            "{}\n", encoding="utf-8"
        )
        for name in ("release-build.sh", "release-common.sh"):
            (repository / f".agents/skills/release-easydict/scripts/{name}").write_text(
                f"# {name}\n", encoding="utf-8"
            )
        (repository / ".agents/skills/release-easydict/assets/export-options.plist").write_text(
            "plist\n", encoding="utf-8"
        )
        run(["git", "add", "."], cwd=repository)
        run(["git", "commit", "-m", "base"], cwd=repository)
        env = os.environ.copy()
        env.update(
            {
                "RELEASE_SOURCE_ROOT": str(repository),
                "VERSION": self.version,
                "CHANNEL": "beta",
            }
        )
        return env, repository

    def invoke(self, script: str, *, cwd: Path, env: dict[str, str]):
        return run(
            ["bash", "-c", 'source "$1"; ' + script, "bash", str(COMMON)],
            cwd=cwd,
            env=env,
            check=False,
        )

    def test_timing_finish_writes_atomic_event(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            env, repository = self.make_environment(Path(directory))
            state = repository / f".tmp/release/{self.version}/state"
            result = self.invoke(
                "ensure_release_layout; release_set_step test_step; release_timing_finish 0",
                cwd=repository,
                env=env,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            timings = state / "timings.json"
            self.assertTrue(timings.is_file())
            payload = json.loads(timings.read_text(encoding="utf-8"))
            self.assertEqual(payload["schema_version"], 1)
            self.assertEqual(payload["events"][-1]["step"], "test_step")
            self.assertEqual(payload["events"][-1]["status"], "ok")

    def test_build_lock_rejects_second_owner(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            env, repository = self.make_environment(Path(directory))
            lock_dir = repository / ".tmp/release/cache/build.lock"
            lock_dir.mkdir(parents=True)
            (lock_dir / "owner").write_text("pid=123\nversion=other\n", encoding="utf-8")
            result = self.invoke(
                "ensure_release_layout; acquire_release_build_lock",
                cwd=repository,
                env=env,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("release build cache is locked", result.stderr)

    def test_read_project_value_passes_json_flag_to_asc(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            temporary = Path(directory)
            asc_dir = temporary / "bin"
            asc_dir.mkdir()
            args_log = temporary / "asc-args.log"
            asc = asc_dir / "asc"
            asc.write_text(
                "#!/usr/bin/env bash\n"
                "printf '%s\\n' \"$@\" >> \"$ASC_ARGS_LOG\"\n"
                "printf '%s\\n' '' >> \"$ASC_ARGS_LOG\"\n"
                "printf '%s\\n' '{\"version\":\"1.2.3\",\"buildNumber\":\"42\"}'\n",
                encoding="utf-8",
            )
            asc.chmod(0o755)
            worktree = temporary / "release-worktree"
            worktree.mkdir()
            env = os.environ.copy()
            env.update(
                {
                    "PATH": f"{asc_dir}:{env['PATH']}",
                    "ASC_ARGS_LOG": str(args_log),
                    "RELEASE_SOURCE_ROOT": str(temporary),
                    "VERSION": "1.2.3",
                    "CHANNEL": "beta",
                }
            )
            result = run(
                [
                    "bash",
                    "-c",
                    'source "$1"; source "$2"; '
                    'RELEASE_WORKTREE="$3"; '
                    'printf "%s %s\\n" "$(read_project_value version)" '
                    '"$(read_project_value buildNumber)"',
                    "bash",
                    str(COMMON),
                    str(BUILD_SCRIPT),
                    str(worktree),
                ],
                cwd=temporary,
                env=env,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout, "1.2.3 42\n")

            calls = [
                line
                for line in args_log.read_text(encoding="utf-8").splitlines()
                if line
            ]
            self.assertEqual(len(calls), 22)
            for offset in (0, 11):
                self.assertEqual(
                    calls[offset : offset + 11],
                    [
                        "xcode",
                        "version",
                        "view",
                        "--project",
                        str(worktree / "Easydict.xcodeproj"),
                        "--target",
                        "Easydict",
                        "--configuration",
                        "Release",
                        "--output",
                        "json",
                    ],
                )

    def test_derived_data_reset_rejects_untrusted_path(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            env, repository = self.make_environment(Path(directory))
            result = self.invoke(
                "ensure_release_layout; safe_reset_release_derived_data /tmp/not-release-cache",
                cwd=repository,
                env=env,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("outside release cache", result.stderr)

    def test_force_clean_must_be_explicitly_validated(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            env, repository = self.make_environment(Path(directory))
            env["FORCE_CLEAN"] = "2"
            result = self.invoke(
                "require_release_version",
                cwd=repository,
                env=env,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("FORCE_CLEAN must be 0 or 1", result.stderr)


if __name__ == "__main__":
    unittest.main()
