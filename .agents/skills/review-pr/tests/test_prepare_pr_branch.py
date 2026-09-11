from __future__ import annotations

import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import textwrap
import unittest
from typing import Optional


SKILL_ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = SKILL_ROOT / "scripts" / "prepare-pr-branch.sh"
SCRIPTS_ROOT = SCRIPT_PATH.parent
sys.path.insert(0, str(SCRIPTS_ROOT))
import snapshot_transport  # noqa: E402


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
        self.fetch_log = self.root / "git-fetches.log"
        self.gh_log = self.root / "gh-views.log"
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
                if [ -n "${GH_VIEW_LOG:-}" ]; then
                  printf '%s\\n' "$*" >> "$GH_VIEW_LOG"
                fi
                if [ "${GH_MUST_NOT_BE_CALLED:-}" = "1" ]; then
                  printf '%s\\n' 'unexpected gh pr view' >&2
                  exit 96
                fi
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

        real_git = shutil.which("git")
        assert real_git is not None
        fake_git = self.bin / "git"
        fake_git.write_text(
            textwrap.dedent(
                f"""\\
                #!/bin/sh
                if [ \"$1\" = \"fetch\" ] && [ -n \"${{GIT_FETCH_LOG:-}}\" ]; then
                  printf '%s\\n' \"$*\" >> \"$GIT_FETCH_LOG\"
                fi
                exec {real_git!s} \"$@\"
                """
            ),
            encoding="utf-8",
        )
        fake_git.chmod(0o755)

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
                "GIT_FETCH_LOG": str(self.fetch_log),
                "GH_VIEW_LOG": str(self.gh_log),
            }
        )
        return environment

    def _prepare(
        self,
        *arguments: str,
        pr_ref: Optional[str] = None,
        expected_repo: Optional[str] = None,
        metadata_head: Optional[str] = None,
        reject_gh: bool = False,
    ) -> subprocess.CompletedProcess[str]:
        environment = self._environment()
        self.fetch_log.write_text("", encoding="utf-8")
        self.gh_log.write_text("", encoding="utf-8")
        pr_number = environment["GH_PR_NUMBER"]
        environment["GH_EXPECTED_VIEW_REF"] = pr_number
        if metadata_head is not None:
            environment["GH_HEAD_OID"] = metadata_head
        if reject_gh:
            environment["GH_MUST_NOT_BE_CALLED"] = "1"
        if expected_repo is not None:
            environment["GH_EXPECTED_REPO"] = expected_repo
        return run(
            ["bash", str(SCRIPT_PATH), *arguments, pr_ref or pr_number],
            cwd=self.checkout,
            env=environment,
            check=False,
        )

    def _fetch_calls(self) -> list[str]:
        return self.fetch_log.read_text(encoding="utf-8").splitlines()

    def _gh_calls(self) -> list[str]:
        return self.gh_log.read_text(encoding="utf-8").splitlines()

    def _write_saved_snapshot(
        self,
        *,
        repo: str = "iftechio/Scoco",
        number: int = 42,
        head_sha: Optional[str] = None,
        pr_head_sha: Optional[str] = None,
        url: Optional[str] = None,
        path_suffix: str = "",
    ) -> tuple[Path, str]:
        frozen_head = head_sha or self.head_sha
        snapshot = {
            "schema_version": 1,
            "repo": repo,
            "number": number,
            "headRefOid": frozen_head,
            "pr": {
                "number": number,
                "url": url or f"https://github.com/{repo}/pull/{number}",
                "headRefOid": pr_head_sha or frozen_head,
                "headRefName": "feat/review-fixture",
                "headRepositoryOwner": {"login": "contributor"},
                "headRepository": {"name": "Scoco"},
                "baseRefName": "dev",
                "baseRefOid": self.base_sha,
            },
        }
        path = self.root / f"saved-snapshot-{self._testMethodName}{path_suffix}.json"
        return path, snapshot_transport.save(path, snapshot, {"mode": "full"})

    def _assert_source_not_prepared(self, branch: str, head: str) -> None:
        self.assertEqual(self._git("branch", "--show-current").stdout.strip(), branch)
        self.assertEqual(self._git("rev-parse", "HEAD").stdout.strip(), head)
        self.assertNotIn("contributor", self._git("remote").stdout.splitlines())
        self._assert_clean_status()

    def _assert_fetches_once_per_remote(self) -> None:
        fetches = self._fetch_calls()
        self.assertEqual(
            sum(call.startswith("fetch contributor ") for call in fetches),
            1,
            fetches,
        )
        self.assertEqual(
            sum(call.startswith("fetch origin ") for call in fetches),
            1,
            fetches,
        )

    def _json_receipt(self, result: subprocess.CompletedProcess[str]) -> dict[str, object]:
        self.assertEqual(result.returncode, 0, result.stderr)
        try:
            receipt = json.loads(result.stdout)
        except json.JSONDecodeError as error:
            self.fail(f"stdout is not one JSON receipt: {error}\nstdout:\n{result.stdout}")
        self.assertIsInstance(receipt, dict)
        return receipt

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

    def test_json_receipt_freezes_normal_review_identity_and_fetches_each_ref_once(self) -> None:
        result = self._prepare("--json", "--expected-head", self.head_sha)
        receipt = self._json_receipt(result)

        self.assertEqual(receipt["schema_version"], 1)
        self.assertEqual(receipt["status"], "prepared")
        self.assertEqual(receipt["repo"], "iftechio/Scoco")
        self.assertEqual(receipt["number"], 42)
        self.assertEqual(receipt["head_sha"], self.head_sha)
        self.assertEqual(receipt["base_sha"], self.base_sha)
        self.assertEqual(receipt["base_branch"], "dev")
        self.assertEqual(
            self._git("merge-base", self.base_sha, self.head_sha).stdout.strip(),
            receipt["merge_base_sha"],
        )
        self.assertEqual(receipt["collision_reason"], None)
        self.assertEqual(receipt["source_unchanged"], None)
        self.assertFalse(receipt["integration"])
        self.assertEqual(receipt["actions"], {"head_fetches": 1, "base_fetches": 1})
        checkout = receipt["checkout"]
        self.assertIsInstance(checkout, dict)
        self.assertEqual(Path(checkout["path"]).resolve(), self.checkout.resolve())
        self.assertEqual(
            {key: value for key, value in checkout.items() if key != "path"},
            {
                "branch": "feat/review-fixture",
                "head_sha": self.head_sha,
                "upstream": "contributor/feat/review-fixture",
                "dirty": False,
            },
        )
        self._assert_fetches_once_per_remote()
        self._assert_clean_status()

    def test_expected_head_mismatch_fails_before_fetch_or_git_writes(self) -> None:
        source_branch = self._git("branch", "--show-current").stdout.strip()
        source_head = self._git("rev-parse", "HEAD").stdout.strip()

        result = self._prepare(
            "--json",
            "--expected-head",
            self.head_sha,
            metadata_head=self.base_sha,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("expected", result.stderr.lower())
        self.assertNotRegex(result.stdout, r'"status"\s*:\s*"prepared"')
        self.assertEqual(self._fetch_calls(), [])
        self.assertNotIn("contributor", self._git("remote").stdout.splitlines())
        self.assertEqual(self._git("branch", "--show-current").stdout.strip(), source_branch)
        self.assertEqual(self._git("rev-parse", "HEAD").stdout.strip(), source_head)
        self._assert_clean_status()

    def test_saved_snapshot_reuses_frozen_metadata_without_calling_gh(self) -> None:
        snapshot_path, snapshot_hash = self._write_saved_snapshot()

        result = self._prepare(
            "--json",
            "--snapshot-file",
            str(snapshot_path),
            "--snapshot-sha256",
            snapshot_hash,
            "--expected-head",
            self.head_sha,
            pr_ref="iftechio/Scoco#42",
            reject_gh=True,
        )
        receipt = self._json_receipt(result)

        self.assertEqual(receipt["status"], "prepared")
        self.assertEqual(receipt["head_sha"], self.head_sha)
        self.assertEqual(receipt["base_sha"], self.base_sha)
        self.assertEqual(self._gh_calls(), [])
        self._assert_fetches_once_per_remote()
        self._assert_clean_status()

    def test_saved_snapshot_reuses_mixed_case_github_identity_without_calling_gh(self) -> None:
        snapshot_path, snapshot_hash = self._write_saved_snapshot(
            repo="IFTECHIO/sCoCo",
            url="https://github.com/iftechio/Scoco/pull/42",
        )

        result = self._prepare(
            "--json",
            "--snapshot-file",
            str(snapshot_path),
            "--snapshot-sha256",
            snapshot_hash,
            "--expected-head",
            self.head_sha,
            pr_ref="iftechio/SCOCO#42",
            reject_gh=True,
        )
        receipt = self._json_receipt(result)

        self.assertEqual(receipt["status"], "prepared")
        self.assertEqual(receipt["head_sha"], self.head_sha)
        self.assertEqual(self._gh_calls(), [])
        self._assert_fetches_once_per_remote()
        self._assert_clean_status()

    def test_saved_snapshot_rejects_tampered_hash_before_preparation(self) -> None:
        snapshot_path, snapshot_hash = self._write_saved_snapshot()
        snapshot_path.write_bytes(snapshot_path.read_bytes() + b" ")
        source_branch = self._git("branch", "--show-current").stdout.strip()
        source_head = self._git("rev-parse", "HEAD").stdout.strip()

        result = self._prepare(
            "--json",
            "--snapshot-file",
            str(snapshot_path),
            "--snapshot-sha256",
            snapshot_hash,
            "--expected-head",
            self.head_sha,
            pr_ref="iftechio/Scoco#42",
            reject_gh=True,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("hash", result.stderr.lower())
        self.assertEqual(self._gh_calls(), [])
        self.assertEqual(self._fetch_calls(), [])
        self._assert_source_not_prepared(source_branch, source_head)

    def test_saved_snapshot_rejects_external_pr_identity_before_preparation(self) -> None:
        snapshot_path, snapshot_hash = self._write_saved_snapshot(repo="external/Scoco")
        source_branch = self._git("branch", "--show-current").stdout.strip()
        source_head = self._git("rev-parse", "HEAD").stdout.strip()

        result = self._prepare(
            "--json",
            "--snapshot-file",
            str(snapshot_path),
            "--snapshot-sha256",
            snapshot_hash,
            "--expected-head",
            self.head_sha,
            pr_ref="iftechio/Scoco#42",
            reject_gh=True,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("identity", result.stderr.lower())
        self.assertEqual(self._gh_calls(), [])
        self.assertEqual(self._fetch_calls(), [])
        self._assert_source_not_prepared(source_branch, source_head)

    def test_saved_snapshot_rejects_wrong_url_or_nested_head_before_preparation(self) -> None:
        cases = (
            (
                "non-GitHub URL",
                {"url": "https://example.test/iftechio/Scoco/pull/42"},
            ),
            (
                "wrong PR number in URL",
                {"url": "https://github.com/iftechio/Scoco/pull/43"},
            ),
            ("PR head differs from frozen head", {"pr_head_sha": self.base_sha}),
        )
        for index, (name, options) in enumerate(cases):
            with self.subTest(case=name):
                snapshot_path, snapshot_hash = self._write_saved_snapshot(
                    **options,
                    path_suffix=f"-{index}",
                )
                source_branch = self._git("branch", "--show-current").stdout.strip()
                source_head = self._git("rev-parse", "HEAD").stdout.strip()

                result = self._prepare(
                    "--json",
                    "--snapshot-file",
                    str(snapshot_path),
                    "--snapshot-sha256",
                    snapshot_hash,
                    "--expected-head",
                    self.head_sha,
                    pr_ref="iftechio/Scoco#42",
                    reject_gh=True,
                )

                self.assertNotEqual(result.returncode, 0)
                self.assertIn("identity", result.stderr.lower())
                self.assertEqual(self._gh_calls(), [])
                self.assertEqual(self._fetch_calls(), [])
                self._assert_source_not_prepared(source_branch, source_head)

    def test_saved_snapshot_requires_explicit_reference_and_expected_head(self) -> None:
        snapshot_path, snapshot_hash = self._write_saved_snapshot()
        source_branch = self._git("branch", "--show-current").stdout.strip()
        source_head = self._git("rev-parse", "HEAD").stdout.strip()

        without_explicit_repo = self._prepare(
            "--json",
            "--snapshot-file",
            str(snapshot_path),
            "--snapshot-sha256",
            snapshot_hash,
            "--expected-head",
            self.head_sha,
            reject_gh=True,
        )
        self.assertNotEqual(without_explicit_repo.returncode, 0)
        self.assertIn("explicit", without_explicit_repo.stderr.lower())
        self.assertEqual(self._gh_calls(), [])
        self.assertEqual(self._fetch_calls(), [])
        self._assert_source_not_prepared(source_branch, source_head)

        without_expected_head = self._prepare(
            "--json",
            "--snapshot-file",
            str(snapshot_path),
            "--snapshot-sha256",
            snapshot_hash,
            pr_ref="iftechio/Scoco#42",
            reject_gh=True,
        )
        self.assertNotEqual(without_expected_head.returncode, 0)
        self.assertIn("expected-head", without_expected_head.stderr)
        self.assertEqual(self._gh_calls(), [])
        self.assertEqual(self._fetch_calls(), [])
        self._assert_source_not_prepared(source_branch, source_head)

    def test_saved_snapshot_expected_head_mismatch_fails_before_preparation(self) -> None:
        snapshot_path, snapshot_hash = self._write_saved_snapshot()
        source_branch = self._git("branch", "--show-current").stdout.strip()
        source_head = self._git("rev-parse", "HEAD").stdout.strip()

        result = self._prepare(
            "--json",
            "--snapshot-file",
            str(snapshot_path),
            "--snapshot-sha256",
            snapshot_hash,
            "--expected-head",
            self.base_sha,
            pr_ref="iftechio/Scoco#42",
            reject_gh=True,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("expected", result.stderr.lower())
        self.assertEqual(self._gh_calls(), [])
        self.assertEqual(self._fetch_calls(), [])
        self._assert_source_not_prepared(source_branch, source_head)

    def test_saved_snapshot_rechecks_fetched_head_before_switching_checkout(self) -> None:
        snapshot_path, snapshot_hash = self._write_saved_snapshot()
        (self.head_source / "head-moved.txt").write_text("moved\n", encoding="utf-8")
        self._commit(self.head_source, "feat(review): move fixture head")
        run(["git", "push", "origin", "feat/review-fixture"], cwd=self.head_source)
        source_branch = self._git("branch", "--show-current").stdout.strip()
        source_head = self._git("rev-parse", "HEAD").stdout.strip()

        result = self._prepare(
            "--json",
            "--snapshot-file",
            str(snapshot_path),
            "--snapshot-sha256",
            snapshot_hash,
            "--expected-head",
            self.head_sha,
            pr_ref="iftechio/Scoco#42",
            reject_gh=True,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("head moved", result.stderr.lower())
        self.assertEqual(self._gh_calls(), [])
        self.assertEqual(
            sum(call.startswith("fetch contributor ") for call in self._fetch_calls()),
            1,
        )
        self.assertEqual(self._git("branch", "--show-current").stdout.strip(), source_branch)
        self.assertEqual(self._git("rev-parse", "HEAD").stdout.strip(), source_head)
        self._assert_clean_status()

    def test_duplicate_json_option_emits_only_one_failed_receipt(self) -> None:
        source_branch = self._git("branch", "--show-current").stdout.strip()
        source_head = self._git("rev-parse", "HEAD").stdout.strip()

        result = self._prepare("--json", "--json", "--expected-head", self.head_sha)

        self.assertNotEqual(result.returncode, 0)
        receipt = json.loads(result.stdout)
        self.assertEqual(receipt["status"], "failed")
        self.assertNotIn("\n", result.stdout.strip())
        self.assertEqual(self._fetch_calls(), [])
        self._assert_source_not_prepared(source_branch, source_head)

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

    def test_json_merged_receipt_fetches_head_and_base_once(self) -> None:
        result = self._prepare("--json", "--merge-latest", "--expected-head", self.head_sha)
        receipt = self._json_receipt(result)

        self.assertTrue(receipt["integration"])
        self.assertEqual(receipt["head_sha"], self.head_sha)
        self.assertEqual(receipt["base_sha"], self.base_sha)
        self.assertEqual(receipt["actions"], {"head_fetches": 1, "base_fetches": 1})
        checkout = receipt["checkout"]
        self.assertIsInstance(checkout, dict)
        self.assertNotEqual(checkout["head_sha"], self.head_sha)
        self._assert_fetches_once_per_remote()
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
        result = self._prepare("--json", "--merge-latest", "--expected-head", self.head_sha)

        self.assertEqual(result.returncode, 2)
        self.assertIn("Merge stopped with conflicts", result.stderr)
        self.assertIn("Review branch: feat/review-fixture", result.stderr)
        self.assertNotRegex(result.stdout, r'"status"\s*:\s*"prepared"')
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

    def test_json_receipt_preserves_collision_reason(self) -> None:
        self._git(
            "fetch",
            str(self.fork_remote),
            "refs/heads/feat/review-fixture:refs/remotes/contributor/feat/review-fixture",
        )
        self._git("branch", "feat/review-fixture", self.head_sha)
        occupied_path = self.root / "occupied-json"
        self._git("worktree", "add", str(occupied_path), "feat/review-fixture")
        self.worktree_paths.append(occupied_path)

        result = self._prepare("--json", "--expected-head", self.head_sha)
        receipt = self._json_receipt(result)

        expected_branch = "review/pr-42-" + self.head_sha[:10]
        self.assertIn("checked out in another worktree", receipt["collision_reason"])
        self.assertEqual(receipt["checkout"]["branch"], expected_branch)
        self.assertFalse(receipt["integration"])
        self._assert_fetches_once_per_remote()
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

    def test_json_worktree_receipt_proves_source_unchanged(self) -> None:
        source_branch = self._git("branch", "--show-current").stdout.strip()
        source_head = self._git("rev-parse", "HEAD").stdout.strip()

        result = self._prepare("--json", "--worktree", "--merge-latest", "--expected-head", self.head_sha)
        receipt = self._json_receipt(result)

        checkout = receipt["checkout"]
        self.assertIsInstance(checkout, dict)
        worktree_path = Path(checkout["path"])
        self.worktree_paths.append(worktree_path)
        self.assertTrue(worktree_path.is_dir())
        self.assertTrue(receipt["source_unchanged"])
        self.assertTrue(receipt["integration"])
        self.assertEqual(self._git("branch", "--show-current").stdout.strip(), source_branch)
        self.assertEqual(self._git("rev-parse", "HEAD").stdout.strip(), source_head)
        self._assert_fetches_once_per_remote()
        self._assert_clean_status()

    def test_json_worktree_without_merge_proves_source_unchanged(self) -> None:
        source_branch = self._git("branch", "--show-current").stdout.strip()
        source_head = self._git("rev-parse", "HEAD").stdout.strip()

        result = self._prepare("--json", "--worktree", "--expected-head", self.head_sha)
        receipt = self._json_receipt(result)

        checkout = receipt["checkout"]
        self.assertIsInstance(checkout, dict)
        worktree_path = Path(checkout["path"])
        self.worktree_paths.append(worktree_path)
        self.assertTrue(worktree_path.is_dir())
        self.assertTrue(receipt["source_unchanged"])
        self.assertFalse(receipt["integration"])
        self.assertEqual(checkout["head_sha"], self.head_sha)
        self.assertEqual(checkout["upstream"], "contributor/feat/review-fixture")
        self.assertEqual(self._git("branch", "--show-current").stdout.strip(), source_branch)
        self.assertEqual(self._git("rev-parse", "HEAD").stdout.strip(), source_head)
        self._assert_fetches_once_per_remote()
        self._assert_clean_status()

    def test_script_has_no_push_command(self) -> None:
        self.assertNotRegex(SCRIPT_PATH.read_text(encoding="utf-8"), r"\bgit\s+push\b")


if __name__ == "__main__":
    unittest.main()
