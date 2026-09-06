from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import textwrap
import unittest


SKILL_ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = SKILL_ROOT / "scripts" / "submit_pr.py"
SPEC = importlib.util.spec_from_file_location("submit_pr", SCRIPT_PATH)
assert SPEC is not None and SPEC.loader is not None
submit_pr = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = submit_pr
SPEC.loader.exec_module(submit_pr)


def run(
    command: list[str],
    *,
    cwd: Path,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        command,
        cwd=cwd,
        env=env,
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise AssertionError(
            f"command failed: {command!r}\nstdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return result


class RenderTests(unittest.TestCase):
    def content(self, **overrides: object) -> submit_pr.PRContent:
        values: dict[str, object] = {
            "title": "feat(cli): add deterministic PR submission",
            "summary": "Add deterministic PR planning and submission.",
            "verification": "- Unit tests passed.",
            "issues": ("#123",),
            "ui_change": False,
            "draft": False,
        }
        values.update(overrides)
        return submit_pr.PRContent(**values)

    def test_template_fixture_still_renders_canonical_sections(self) -> None:
        template = textwrap.dedent(
            """\
            ## Summary

            ## Linked Issues

            ## Verification

            ## Screenshots
            """
        )
        body = submit_pr.render_pr_body(
            template,
            self.content(),
        )

        for heading in submit_pr.CANONICAL_HEADINGS:
            self.assertEqual(body.count(heading), 1)
        self.assertIn("- #123", body)
        self.assertIn("## 截图 / Screenshots\n\nN/A", body)
        self.assertNotIn("<!--", body)

    def test_english_template_is_canonicalized_and_preserves_requirements(self) -> None:
        template = textwrap.dedent(
            """\
            <!-- repository guidance -->
            ## Summary

            ## Related Issues

            ## Testing

            - [ ] I ran the focused test suite.

            ## Screenshots

            ## Maintainer Checklist

            - [ ] Documentation is updated.
            """
        )

        body = submit_pr.render_pr_body(template, self.content())

        for heading in submit_pr.CANONICAL_HEADINGS:
            self.assertEqual(body.count(heading), 1)
        self.assertIn("- [ ] I ran the focused test suite.", body)
        self.assertIn("## Maintainer Checklist", body)
        self.assertIn("- [ ] Documentation is updated.", body)

    def test_missing_template_sections_use_fixed_four_section_contract(self) -> None:
        body = submit_pr.render_pr_body("", self.content(issues=()))

        self.assertEqual(
            [line for line in body.splitlines() if line.startswith("## ")],
            list(submit_pr.CANONICAL_HEADINGS),
        )
        linked = body.split(submit_pr.CANONICAL_HEADINGS[1], 1)[1]
        linked = linked.split(submit_pr.CANONICAL_HEADINGS[2], 1)[0]
        self.assertEqual(linked.strip(), "")

    def test_missing_template_discovery_returns_builtin_contract(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            template, path = submit_pr.discover_template(Path(directory), None)

        self.assertIsNone(path)
        self.assertEqual(
            [line for line in template.splitlines() if line.startswith("## ")],
            list(submit_pr.CANONICAL_HEADINGS),
        )

    def test_supported_single_template_locations_are_discovered(self) -> None:
        locations = (
            "pull_request_template.md",
            "PULL_REQUEST_TEMPLATE.md",
            "Pull_Request_Template.TXT",
            "docs/pUlL_rEqUeSt_TeMpLaTe.TxT",
            ".github/PULL_REQUEST_TEMPLATE.md",
            ".github/pull_request_template/feature.TXT",
        )
        for location in locations:
            with self.subTest(location=location):
                with tempfile.TemporaryDirectory() as directory:
                    root = Path(directory)
                    expected = root / location
                    expected.parent.mkdir(parents=True, exist_ok=True)
                    expected.write_text("## Summary\n", encoding="utf-8")

                    template, path = submit_pr.discover_template(root, None)

                self.assertEqual(template, "## Summary\n")
                self.assertEqual(path, str(expected))

    def test_template_discovery_deduplicates_hard_links(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "pull_request_template.md"
            duplicate = root / ".github" / "PULL_REQUEST_TEMPLATE.md"
            duplicate.parent.mkdir()
            source.write_text("## Summary\n", encoding="utf-8")
            os.link(source, duplicate)

            template, path = submit_pr.discover_template(root, None)

        self.assertEqual(template, "## Summary\n")
        self.assertEqual(path, str(source))

    def test_ui_change_requests_screenshots_without_stopping(self) -> None:
        body = submit_pr.render_pr_body("", self.content(ui_change=True))

        self.assertIn(submit_pr.UI_SCREENSHOT_NOTICE, body)

    def test_issue_policy_forbid_rejects_auto_close_but_neutral_allows_it(self) -> None:
        neutral = submit_pr.render_pr_body(
            "",
            self.content(summary="Fixes #123", issue_policy="neutral"),
        )
        self.assertIn("Fixes #123", neutral)

        with self.assertRaisesRegex(submit_pr.SubmitPRError, "auto-closing"):
            submit_pr.render_pr_body(
                "",
                self.content(summary="Fixes #123", issue_policy="forbid"),
            )

    def test_extra_body_cannot_repeat_canonical_section(self) -> None:
        with self.assertRaisesRegex(submit_pr.SubmitPRError, "repeats"):
            submit_pr.render_pr_body(
                "",
                self.content(extra_body="## Testing\n\nDuplicate"),
            )

    def test_non_angular_title_is_rejected(self) -> None:
        with self.assertRaisesRegex(submit_pr.SubmitPRError, "Angular-style"):
            submit_pr.render_pr_body(
                "",
                self.content(title="Add PR submission workflow"),
            )

    def test_template_discovery_requires_selection_when_multiple_exist(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / ".github" / "PULL_REQUEST_TEMPLATE").mkdir(parents=True)
            (root / ".github" / "pull_request_template.md").write_text("## Summary")
            (root / ".github" / "PULL_REQUEST_TEMPLATE" / "bug.md").write_text(
                "## Summary"
            )

            with self.assertRaisesRegex(submit_pr.SubmitPRError, "multiple"):
                submit_pr.discover_template(root, None)

    def test_status_parser_preserves_staging_boundaries(self) -> None:
        state = submit_pr.parse_status(
            " M README.md\nM  staged.md\n?? untracked.md\n"
        )

        self.assertEqual(state["staged"], ["staged.md"])
        self.assertEqual(state["unstaged"], ["README.md"])
        self.assertEqual(state["untracked"], ["untracked.md"])


class WorkflowIntegrationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.base_remote = self.root / "base.git"
        self.fork_remote = self.root / "fork.git"
        self.repo = self.root / "checkout"
        self.bin = self.root / "bin"
        self.state_path = self.root / "gh-state.json"
        self.remote_map_path = self.root / "remote-map.json"
        self.bin.mkdir()
        self.write_fake_ssh()
        self.write_fake_gh()
        run(["git", "init", "--bare", str(self.base_remote)], cwd=self.root)
        run(["git", "init", "--bare", str(self.fork_remote)], cwd=self.root)
        run(["git", "init", "-b", "main", str(self.repo)], cwd=self.root)
        run(["git", "config", "user.name", "Submit PR Test"], cwd=self.repo)
        run(["git", "config", "user.email", "submit-pr@example.com"], cwd=self.repo)

        (self.repo / "base.txt").write_text("base\n", encoding="utf-8")
        run(["git", "add", "base.txt"], cwd=self.repo)
        run(
            [
                "git",
                "-c",
                "commit.gpgsign=false",
                "commit",
                "-m",
                "chore: seed repository",
            ],
            cwd=self.repo,
        )
        run(
            ["git", "remote", "add", "upstream", "git@github.com:acme/project.git"],
            cwd=self.repo,
        )
        self.write_remote_map()
        run(
            ["git", "push", "-u", "upstream", "main"],
            cwd=self.repo,
            env=self.git_environment(),
        )
        self.base_sha = run(["git", "rev-parse", "HEAD"], cwd=self.repo).stdout.strip()

        (self.repo / "feature.txt").write_text("feature\n", encoding="utf-8")
        run(["git", "add", "feature.txt"], cwd=self.repo)
        run(
            [
                "git",
                "-c",
                "commit.gpgsign=false",
                "commit",
                "-m",
                "feat(cli): add deterministic PR submission",
            ],
            cwd=self.repo,
        )
        self.head_sha = run(["git", "rev-parse", "HEAD"], cwd=self.repo).stdout.strip()
        self.write_state()

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def write_state(self) -> None:
        payload = {
            "repos": {
                "acme/project": {
                    "nameWithOwner": "acme/project",
                    "defaultBranchRef": {"name": "main"},
                    "isFork": False,
                    "parent": None,
                },
                "contrib/project": {
                    "nameWithOwner": "contrib/project",
                    "defaultBranchRef": {"name": "main"},
                    "isFork": True,
                    "parent": {"nameWithOwner": "acme/project"},
                },
            }
        }
        self.state_path.write_text(json.dumps(payload), encoding="utf-8")

    def write_remote_map(self) -> None:
        self.remote_map_path.write_text(
            json.dumps(
                {
                    "acme/project.git": str(self.base_remote),
                    "contrib/project.git": str(self.fork_remote),
                }
            ),
            encoding="utf-8",
        )

    def write_fake_ssh(self) -> None:
        fake = self.bin / "fake-ssh"
        fake.write_text(
            textwrap.dedent(
                """\
                #!/usr/bin/env python3
                import json
                import os
                import shlex
                import sys

                command = shlex.split(sys.argv[-1])
                if not command or command[0] not in {"git-upload-pack", "git-receive-pack"}:
                    raise SystemExit(2)
                repository = command[1].strip("'").lstrip("/")
                mapping = json.loads(open(os.environ["FAKE_GIT_REMOTE_MAP"]).read())
                os.execvp(command[0], [command[0], mapping[repository]])
                """
            ),
            encoding="utf-8",
        )
        fake.chmod(0o755)

    def write_fake_gh(self) -> None:
        fake = self.bin / "gh"
        fake.write_text(
            textwrap.dedent(
                """\
                #!/usr/bin/env python3
                import json
                import os
                from pathlib import Path
                import sys

                args = sys.argv[1:]
                state_path = Path(os.environ["FAKE_GH_STATE"])
                state = json.loads(state_path.read_text())

                def value(flag):
                    return args[args.index(flag) + 1]

                if args[:2] == ["auth", "status"]:
                    print("Logged in to github.com")
                elif args[:2] == ["repo", "view"]:
                    print(json.dumps(state["repos"][args[2]]))
                elif args[:2] == ["pr", "list"]:
                    print(json.dumps([state["pr"]] if "pr" in state else []))
                elif args[:2] == ["pr", "create"]:
                    base_repo = value("--repo")
                    head = value("--head")
                    if ":" in head:
                        owner, branch = head.split(":", 1)
                        head_repo = f"{owner}/{base_repo.split('/', 1)[1]}"
                    else:
                        branch = head
                        head_repo = base_repo
                    body = Path(value("--body-file")).read_text()
                    pr = {
                        "number": 42,
                        "title": value("--title"),
                        "url": f"https://github.com/{base_repo}/pull/42",
                        "body": body,
                        "baseRefName": value("--base"),
                        "headRefName": branch,
                        "headRefOid": os.environ["FAKE_HEAD_SHA"],
                        "headRepository": {"name": head_repo.split('/', 1)[1]},
                        "headRepositoryOwner": {"login": head_repo.split('/', 1)[0]},
                        "isCrossRepository": head_repo != base_repo,
                        "isDraft": "--draft" in args,
                        "state": "OPEN",
                        "closingIssuesReferences": [],
                    }
                    state["pr"] = pr
                    state["create_count"] = state.get("create_count", 0) + 1
                    state_path.write_text(json.dumps(state))
                    print(pr["url"])
                elif args[:2] == ["pr", "view"]:
                    print(json.dumps(state["pr"]))
                else:
                    print(f"unexpected fake gh command: {args}", file=sys.stderr)
                    raise SystemExit(2)
                """
            ),
            encoding="utf-8",
        )
        fake.chmod(0o755)

    def git_environment(self) -> dict[str, str]:
        environment = os.environ.copy()
        environment["GIT_SSH_COMMAND"] = str(self.bin / "fake-ssh")
        environment["GIT_SSH_VARIANT"] = "ssh"
        environment["FAKE_GIT_REMOTE_MAP"] = str(self.remote_map_path)
        return environment

    def environment(self) -> dict[str, str]:
        environment = self.git_environment()
        environment["PATH"] = f"{self.bin}{os.pathsep}{environment['PATH']}"
        environment["FAKE_GH_STATE"] = str(self.state_path)
        environment["FAKE_HEAD_SHA"] = self.head_sha
        environment["PYTHONPYCACHEPREFIX"] = str(self.root / "pycache")
        return environment

    def command(self, action: str, *extra: str) -> list[str]:
        return [
            sys.executable,
            str(SCRIPT_PATH),
            action,
            "--repo-root",
            str(self.repo),
            "--title",
            "feat(cli): add deterministic PR submission",
            "--summary",
            "Add deterministic PR submission.",
            "--verification",
            "- Unit tests passed.",
            "--head-branch",
            "feat/deterministic-pr-submission",
            *extra,
        ]

    def test_plan_discovers_non_origin_default_branch_and_is_read_only(self) -> None:
        refs_before = run(["git", "show-ref"], cwd=self.repo).stdout
        status_before = run(["git", "status", "--porcelain=v1"], cwd=self.repo).stdout
        fetch_head = self.repo / ".git" / "FETCH_HEAD"
        fetch_before = fetch_head.read_bytes() if fetch_head.exists() else None

        result = run(self.command("plan", "--ui-change"), cwd=self.repo, env=self.environment())
        payload = json.loads(result.stdout)

        self.assertEqual(payload["repository"], "acme/project")
        self.assertEqual(payload["base_remote"], "upstream")
        self.assertEqual(payload["base"], "main")
        self.assertEqual(payload["head_remote"], "upstream")
        self.assertEqual(payload["planned_branch_action"], "would-create")
        self.assertIsNone(payload["template"])
        self.assertTrue(payload["needs_screenshots"])
        self.assertEqual(
            [line for line in payload["body"].splitlines() if line.startswith("## ")],
            list(submit_pr.CANONICAL_HEADINGS),
        )
        self.assertEqual(run(["git", "show-ref"], cwd=self.repo).stdout, refs_before)
        self.assertEqual(
            run(["git", "status", "--porcelain=v1"], cwd=self.repo).stdout,
            status_before,
        )
        fetch_after = fetch_head.read_bytes() if fetch_head.exists() else None
        self.assertEqual(fetch_after, fetch_before)
        self.assertFalse((self.repo / ".tmp" / "submit-pr").exists())

    def test_apply_pushes_same_repo_branch_and_reuses_pr(self) -> None:
        environment = self.environment()
        first = json.loads(
            run(self.command("apply"), cwd=self.repo, env=environment).stdout
        )

        self.assertEqual(first["push_action"], "created")
        self.assertEqual(first["pr_action"], "created")
        self.assertFalse(first["is_cross_repository"])
        state = json.loads(self.state_path.read_text(encoding="utf-8"))
        self.assertEqual(
            [
                line
                for line in state["pr"]["body"].splitlines()
                if line.startswith("## ")
            ],
            list(submit_pr.CANONICAL_HEADINGS),
        )
        self.assertEqual(
            run(["git", "branch", "--show-current"], cwd=self.repo).stdout.strip(),
            "main",
        )
        remote_main = run(
            ["git", "--git-dir", str(self.base_remote), "rev-parse", "refs/heads/main"],
            cwd=self.root,
        ).stdout.strip()
        remote_head = run(
            [
                "git",
                "--git-dir",
                str(self.base_remote),
                "rev-parse",
                "refs/heads/feat/deterministic-pr-submission",
            ],
            cwd=self.root,
        ).stdout.strip()
        self.assertEqual(remote_main, self.base_sha)
        self.assertEqual(remote_head, self.head_sha)

        second = json.loads(
            run(self.command("apply"), cwd=self.repo, env=environment).stdout
        )
        state = json.loads(self.state_path.read_text(encoding="utf-8"))
        self.assertEqual(second["pr_action"], "reused")
        self.assertEqual(state["create_count"], 1)

    def test_apply_discovers_fork_push_remote(self) -> None:
        run(
            ["git", "remote", "add", "fork", "git@github.com:contrib/project.git"],
            cwd=self.repo,
        )
        run(["git", "config", "remote.pushDefault", "fork"], cwd=self.repo)

        payload = json.loads(
            run(self.command("apply"), cwd=self.repo, env=self.environment()).stdout
        )
        state = json.loads(self.state_path.read_text(encoding="utf-8"))

        self.assertEqual(payload["repository"], "acme/project")
        self.assertEqual(payload["head_repository"], "contrib/project")
        self.assertEqual(payload["head_remote"], "fork")
        self.assertTrue(payload["is_cross_repository"])
        self.assertTrue(state["pr"]["isCrossRepository"])
        remote_head = run(
            [
                "git",
                "--git-dir",
                str(self.fork_remote),
                "rev-parse",
                "refs/heads/feat/deterministic-pr-submission",
            ],
            cwd=self.root,
        ).stdout.strip()
        self.assertEqual(remote_head, self.head_sha)

    def test_apply_uses_fork_pushurl_on_base_remote(self) -> None:
        run(
            [
                "git",
                "remote",
                "set-url",
                "--push",
                "upstream",
                "git@github.com:contrib/project.git",
            ],
            cwd=self.repo,
        )

        payload = json.loads(
            run(self.command("apply"), cwd=self.repo, env=self.environment()).stdout
        )

        self.assertEqual(payload["base_remote"], "upstream")
        self.assertEqual(payload["head_remote"], "upstream")
        self.assertEqual(payload["head_repository"], "contrib/project")
        self.assertTrue(payload["is_cross_repository"])
        remote_head = run(
            [
                "git",
                "--git-dir",
                str(self.fork_remote),
                "rev-parse",
                "refs/heads/feat/deterministic-pr-submission",
            ],
            cwd=self.root,
        ).stdout.strip()
        self.assertEqual(remote_head, self.head_sha)

    def test_apply_rejects_dirty_worktree_before_remote_writes(self) -> None:
        (self.repo / "feature.txt").write_text("dirty\n", encoding="utf-8")

        result = subprocess.run(
            self.command("apply"),
            cwd=self.repo,
            env=self.environment(),
            check=False,
            capture_output=True,
            text=True,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("clean working tree", result.stderr)
        self.assertNotIn("pr", json.loads(self.state_path.read_text(encoding="utf-8")))

    def test_forbid_policy_rejects_auto_closing_commit_message(self) -> None:
        run(
            [
                "git",
                "-c",
                "commit.gpgsign=false",
                "commit",
                "--amend",
                "-m",
                "feat(cli): add deterministic PR submission",
                "-m",
                "Fixes #123",
            ],
            cwd=self.repo,
        )

        result = subprocess.run(
            self.command("plan", "--issue-policy", "forbid"),
            cwd=self.repo,
            env=self.environment(),
            check=False,
            capture_output=True,
            text=True,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("auto-closing", result.stderr)

    def test_draft_and_existing_body_are_verified(self) -> None:
        environment = self.environment()
        payload = json.loads(
            run(self.command("apply", "--draft"), cwd=self.repo, env=environment).stdout
        )
        self.assertTrue(payload["draft"])

        state = json.loads(self.state_path.read_text(encoding="utf-8"))
        state["pr"]["body"] = "Maintainer-edited body"
        self.state_path.write_text(json.dumps(state), encoding="utf-8")
        result = subprocess.run(
            self.command("apply", "--draft"),
            cwd=self.repo,
            env=environment,
            check=False,
            capture_output=True,
            text=True,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("body differs", result.stderr)

    def test_ambiguous_base_remotes_require_explicit_selection(self) -> None:
        run(
            ["git", "remote", "add", "mirror", "git@github.com:acme/project.git"],
            cwd=self.repo,
        )

        ambiguous = subprocess.run(
            self.command("plan"),
            cwd=self.repo,
            env=self.environment(),
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertNotEqual(ambiguous.returncode, 0)
        self.assertIn("--base-remote", ambiguous.stderr)

        resolved = json.loads(
            run(
                self.command("plan", "--base-remote", "upstream"),
                cwd=self.repo,
                env=self.environment(),
            ).stdout
        )
        self.assertEqual(resolved["base_remote"], "upstream")


if __name__ == "__main__":
    unittest.main()
