from __future__ import annotations

import os
from pathlib import Path
import re
import subprocess
import tempfile
import textwrap
import unittest
from typing import Optional


SKILL_ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = SKILL_ROOT / "scripts" / "prepare-pr-branch.sh"


def run(
    command: list[str],
    *,
    cwd: Path,
    env: Optional[dict[str, str]] = None,
    check: bool = True,
) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        command,
        cwd=cwd,
        env=env,
        check=False,
        capture_output=True,
        text=True,
    )
    if check and result.returncode != 0:
        raise AssertionError(
            f"command failed: {command!r}\n"
            f"stdout:\n{result.stdout}\n"
            f"stderr:\n{result.stderr}"
        )
    return result


class PreparePRBranchTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.base_remote = self.root / "base.git"
        self.fork_remote = self.root / "fork.git"
        self.seed = self.root / "seed"
        self.head_source = self.root / "head-source"
        self.checkout = self.root / f"checkout-{self.root.name}"
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.worktree_paths: list[Path] = []
        self.conflict = self._testMethodName == "test_local_latest_base_stops_on_conflict"
        self._write_fake_gh()
        self._create_fixture()

    def tearDown(self) -> None:
        for worktree_path in reversed(self.worktree_paths):
            run(
                ["git", "worktree", "remove", "--force", str(worktree_path)],
                cwd=self.checkout,
                check=False,
            )
        run(["git", "worktree", "prune"], cwd=self.checkout, check=False)
        self.temporary.cleanup()

    def _git(
        self,
        *args: str,
        cwd: Optional[Path] = None,
        check: bool = True,
    ) -> subprocess.CompletedProcess[str]:
        return run(["git", *args], cwd=cwd or self.checkout, check=check)

    def _commit(self, repository: Path, message: str) -> None:
        run(["git", "add", "-A"], cwd=repository)
        run(
            [
                "git",
                "-c",
                "commit.gpgsign=false",
                "commit",
                "-m",
                message,
            ],
            cwd=repository,
        )

    def _write_fake_gh(self) -> None:
        fake_gh = self.bin / "gh"
        fake_gh.write_text(
            textwrap.dedent(
                """\
                #!/bin/sh
                if [ "$#" -lt 4 ] || [ "$1" != "pr" ] || [ "$2" != "view" ]; then
                  exit 64
                fi
                if [ "$3" != "$GH_EXPECTED_VIEW_REF" ]; then
                  exit 65
                fi
                shift 3
                if [ -n "${GH_EXPECTED_REPO:-}" ]; then
                  if [ "$1" != "--repo" ] || [ "$2" != "$GH_EXPECTED_REPO" ]; then
                    exit 66
                  fi
                  shift 2
                elif [ "$1" = "--repo" ]; then
                  exit 67
                fi
                if [ "$1" != "--json" ]; then
                  exit 68
                fi
                printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \\
                  "$GH_HEAD_OWNER" "$GH_HEAD_REPO" "$GH_HEAD_BRANCH" \\
                  "$GH_HEAD_OID" "$GH_BASE_BRANCH" "$GH_PR_NUMBER" "$GH_PR_URL"
                """
            ),
            encoding="utf-8",
        )
        fake_gh.chmod(0o755)

    def _create_fixture(self) -> None:
        run(["git", "init", "--bare", str(self.base_remote)], cwd=self.root)
        run(["git", "init", "--bare", str(self.fork_remote)], cwd=self.root)
        run(["git", "init", "-b", "dev", str(self.seed)], cwd=self.root)

        self._git_config(self.seed, "user.name", "review-pr test")
        self._git_config(self.seed, "user.email", "review-pr@example.com")
        (self.seed / "shared.txt").write_text("base\n", encoding="utf-8")
        self._commit(self.seed, "chore: seed review fixture")
        run(["git", "remote", "add", "origin", str(self.base_remote)], cwd=self.seed)
        run(["git", "push", "origin", "dev"], cwd=self.seed)

        run(
            ["git", "clone", "--branch", "dev", str(self.base_remote), str(self.head_source)],
            cwd=self.root,
        )
        self._git_config(self.head_source, "user.name", "review-pr test")
        self._git_config(self.head_source, "user.email", "review-pr@example.com")
        run(["git", "remote", "set-url", "origin", str(self.fork_remote)], cwd=self.head_source)
        run(["git", "switch", "--create", "feat/review-fixture"], cwd=self.head_source)
        if self.conflict:
            (self.head_source / "shared.txt").write_text("head\n", encoding="utf-8")
        else:
            (self.head_source / "feature.txt").write_text("feature\n", encoding="utf-8")
        self._commit(self.head_source, "feat(review): add review fixture")
        run(["git", "push", "origin", "feat/review-fixture"], cwd=self.head_source)
        self.head_sha = run(
            ["git", "rev-parse", "HEAD"], cwd=self.head_source
        ).stdout.strip()

        if self.conflict:
            (self.seed / "shared.txt").write_text("base-latest\n", encoding="utf-8")
        else:
            (self.seed / "base-after.txt").write_text("base-after\n", encoding="utf-8")
        self._commit(self.seed, "chore: advance base branch")
        run(["git", "push", "origin", "dev"], cwd=self.seed)
        self.base_sha = run(["git", "rev-parse", "HEAD"], cwd=self.seed).stdout.strip()

        run(
            ["git", "clone", "--branch", "dev", str(self.base_remote), str(self.checkout)],
            cwd=self.root,
        )
        self._git_config(self.checkout, "user.name", "review-pr test")
        self._git_config(self.checkout, "user.email", "review-pr@example.com")
        self._git_config(self.checkout, "commit.gpgsign", "false")
        run(
            [
                "git",
                "remote",
                "set-url",
                "origin",
                "https://github.com/iftechio/Scoco.git",
            ],
            cwd=self.checkout,
        )
        self._git_config(
            self.checkout,
            "url." + str(self.base_remote) + ".insteadOf",
            "https://github.com/iftechio/Scoco.git",
        )
        self._git_config(
            self.checkout,
            "url." + str(self.fork_remote) + ".insteadOf",
            "https://github.com/contributor/Scoco.git",
        )

    def _git_config(self, repository: Path, key: str, value: str) -> None:
        run(["git", "config", key, value], cwd=repository)

    def _environment(self) -> dict[str, str]:
        environment = os.environ.copy()
        environment["PATH"] = f"{self.bin}{os.pathsep}{environment['PATH']}"
        environment.update(
            {
                "GH_HEAD_OWNER": "contributor",
                "GH_HEAD_REPO": "Scoco",
                "GH_HEAD_BRANCH": "feat/review-fixture",
                "GH_HEAD_OID": self.head_sha,
                "GH_BASE_BRANCH": "dev",
                "GH_PR_NUMBER": "42",
                "GH_PR_URL": "https://github.com/iftechio/Scoco/pull/42",
                "GIT_TERMINAL_PROMPT": "0",
            }
        )
        return environment

    def _prepare(
        self,
        *arguments: str,
        pr_ref: Optional[str] = None,
        expected_repo: Optional[str] = None,
    ) -> subprocess.CompletedProcess[str]:
        environment = self._environment()
        pr_number = environment["GH_PR_NUMBER"]
        environment["GH_EXPECTED_VIEW_REF"] = pr_number
        if expected_repo is not None:
            environment["GH_EXPECTED_REPO"] = expected_repo
        return run(
            ["bash", str(SCRIPT_PATH), *arguments, pr_ref or pr_number],
            cwd=self.checkout,
            env=environment,
            check=False,
        )

    def _assert_clean_status(self) -> None:
        self.assertEqual(self._git("status", "--porcelain").stdout, "")

    def test_local_review_keeps_available_head_branch_name(self) -> None:
        result = self._prepare()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Branch: feat/review-fixture", result.stdout)
        self.assertEqual(self._git("branch", "--show-current").stdout.strip(), "feat/review-fixture")
        self.assertEqual(self._git("rev-parse", "HEAD").stdout.strip(), self.head_sha)
        self.assertEqual(
            self._git("for-each-ref", "--format=%(upstream:short)", "refs/heads/feat/review-fixture").stdout.strip(),
            "contributor/feat/review-fixture",
        )
        self._assert_clean_status()

    def test_github_url_reference_passes_base_repo_to_gh(self) -> None:
        pr_url = self._environment()["GH_PR_URL"]
        base_repo = pr_url.removeprefix("https://github.com/").split("/pull/", 1)[0]

        result = self._prepare(pr_ref=pr_url, expected_repo=base_repo)

        self.assertEqual(result.returncode, 0, result.stderr)
        self._assert_clean_status()

    def test_shorthand_reference_passes_base_repo_to_gh(self) -> None:
        environment = self._environment()
        pr_url = environment["GH_PR_URL"]
        base_repo = pr_url.removeprefix("https://github.com/").split("/pull/", 1)[0]

        result = self._prepare(
            pr_ref=f"{base_repo}#{environment['GH_PR_NUMBER']}",
            expected_repo=base_repo,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self._assert_clean_status()

    def test_local_latest_base_keeps_head_branch_name(self) -> None:
        result = self._prepare("--merge-latest")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Review branch: feat/review-fixture", result.stdout)
        self.assertNotIn("review/pr-42-merge-", result.stdout)
        merged_head = self._git("rev-parse", "HEAD").stdout.strip()
        self.assertNotEqual(merged_head, self.head_sha)
        self.assertTrue(
            self._git("merge-base", "--is-ancestor", self.head_sha, merged_head, check=False).returncode == 0
        )
        self.assertTrue(
            self._git("merge-base", "--is-ancestor", self.base_sha, merged_head, check=False).returncode == 0
        )
        self._assert_clean_status()

    def test_local_latest_base_uses_head_fallback_without_merge_suffix(self) -> None:
        self._git("branch", "feat/review-fixture")
        self._git("branch", "--set-upstream-to=origin/dev", "feat/review-fixture")

        result = self._prepare("--merge-latest")

        expected_branch = "review/pr-42-" + self.head_sha[:10]
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(f"Review branch: {expected_branch}", result.stdout)
        self.assertNotIn("review/pr-42-merge-", result.stdout)
        self.assertEqual(self._git("branch", "--show-current").stdout.strip(), expected_branch)
        self.assertNotEqual(self._git("rev-parse", "HEAD").stdout.strip(), self.head_sha)
        self.assertEqual(
            self._git("rev-parse", "refs/heads/feat/review-fixture").stdout.strip(),
            self.base_sha,
        )
        self._assert_clean_status()

    def test_local_latest_base_stops_on_conflict(self) -> None:
        result = self._prepare("--merge-latest")

        self.assertEqual(result.returncode, 2)
        self.assertIn("Merge stopped with conflicts", result.stderr)
        self.assertIn("Review branch: feat/review-fixture", result.stderr)
        self.assertEqual(self._git("branch", "--show-current").stdout.strip(), "feat/review-fixture")
        self.assertIn("UU shared.txt", self._git("status", "--short").stdout)

    def test_local_review_falls_back_when_head_branch_is_checked_out_elsewhere(self) -> None:
        self._git(
            "fetch",
            str(self.fork_remote),
            "refs/heads/feat/review-fixture:refs/remotes/contributor/feat/review-fixture",
        )
        self._git("branch", "feat/review-fixture", self.head_sha)
        occupied_path = self.root / "occupied"
        self._git("worktree", "add", str(occupied_path), "feat/review-fixture")
        self.worktree_paths.append(occupied_path)

        result = self._prepare()

        expected_branch = "review/pr-42-" + self.head_sha[:10]
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(f"Review branch: {expected_branch}", result.stdout)
        self.assertIn("checked out in another worktree", result.stdout)
        self.assertEqual(self._git("branch", "--show-current").stdout.strip(), expected_branch)
        self.assertEqual(
            run(
                ["git", "-C", str(occupied_path), "branch", "--show-current"],
                cwd=self.checkout,
            ).stdout.strip(),
            "feat/review-fixture",
        )
        self.assertEqual(
            run(
                ["git", "-C", str(occupied_path), "rev-parse", "HEAD"],
                cwd=self.checkout,
            ).stdout.strip(),
            self.head_sha,
        )
        self._assert_clean_status()

    def test_worktree_latest_base_keeps_source_checkout_unchanged(self) -> None:
        source_branch = self._git("branch", "--show-current").stdout.strip()
        source_head = self._git("rev-parse", "HEAD").stdout.strip()

        result = self._prepare("--worktree", "--merge-latest")

        self.assertEqual(result.returncode, 0, result.stderr)
        match = re.search(r"^Worktree: (.+)$", result.stdout, re.MULTILINE)
        self.assertIsNotNone(match, result.stdout)
        assert match is not None
        worktree_path = Path(match.group(1))
        self.worktree_paths.append(worktree_path)
        self.assertTrue(worktree_path.is_dir())
        self.assertIn("review/pr-42-merge-", result.stdout)
        self.assertEqual(self._git("branch", "--show-current").stdout.strip(), source_branch)
        self.assertEqual(self._git("rev-parse", "HEAD").stdout.strip(), source_head)
        self._assert_clean_status()

        worktree_branch = run(
            ["git", "-C", str(worktree_path), "branch", "--show-current"],
            cwd=self.checkout,
        ).stdout.strip()
        self.assertTrue(worktree_branch.startswith("review/pr-42-merge-"))

    def test_script_has_no_push_command(self) -> None:
        self.assertNotRegex(SCRIPT_PATH.read_text(encoding="utf-8"), r"\bgit\s+push\b")


if __name__ == "__main__":
    unittest.main()
