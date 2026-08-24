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
REPOSITORY_ROOT = SKILL_ROOT.parents[2]
SCRIPT_PATH = SKILL_ROOT / "scripts" / "submit_pr.py"
TEMPLATE_PATH = REPOSITORY_ROOT / ".github" / "pull_request_template.md"
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
    def setUp(self) -> None:
        self.template = TEMPLATE_PATH.read_text(encoding="utf-8")

    def content(self, **overrides: object) -> submit_pr.PRContent:
        values: dict[str, object] = {
            "title": "feat(agent): add PR submission workflow",
            "summary": "Add deterministic PR planning and submission.",
            "verification": "- Unit tests passed.",
            "issues": ("#123",),
            "ui_change": False,
            "draft": False,
        }
        values.update(overrides)
        return submit_pr.PRContent(**values)

    def test_render_uses_live_template_sections(self) -> None:
        body = submit_pr.render_pr_body(self.template, self.content())

        for heading in submit_pr.REQUIRED_HEADINGS:
            self.assertEqual(body.count(heading), 1)
        self.assertIn("- #123", body)
        self.assertIn("## 截图 / Screenshots\n\nN/A", body)
        self.assertNotIn("<!--", body)

    def test_ui_change_requests_screenshots_without_rejecting_body(self) -> None:
        body = submit_pr.render_pr_body(
            self.template,
            self.content(ui_change=True),
        )

        self.assertIn(submit_pr.UI_SCREENSHOT_NOTICE, body)

    def test_empty_linked_issues_section_has_no_placeholder(self) -> None:
        body = submit_pr.render_pr_body(
            self.template,
            self.content(issues=()),
        )

        linked = body.split("## 关联 Issue / Linked Issues", 1)[1]
        linked = linked.split("## 验证 / Verification", 1)[0]
        self.assertEqual(linked.strip(), "")

    def test_supported_issue_reference_forms(self) -> None:
        issues = (
            "#123",
            "https://github.com/tisfeng/Easydict/issues/456",
            "owner/repo#789",
        )

        body = submit_pr.render_pr_body(
            self.template,
            self.content(issues=issues),
        )

        for issue in issues:
            self.assertIn(f"- {issue}", body)

    def test_auto_closing_reference_is_rejected(self) -> None:
        with self.assertRaisesRegex(
            submit_pr.SubmitPRError,
            "auto-closing",
        ):
            submit_pr.render_pr_body(
                self.template,
                self.content(summary="Fixes #123"),
            )

    def test_non_angular_title_is_rejected(self) -> None:
        with self.assertRaisesRegex(
            submit_pr.SubmitPRError,
            "Angular-style",
        ):
            submit_pr.render_pr_body(
                self.template,
                self.content(title="Add PR submission workflow"),
            )

    def test_status_parser_preserves_unstaged_first_line(self) -> None:
        state = submit_pr.parse_status(
            " M AGENTS.md\nM  staged.md\n?? untracked.md\n"
        )

        self.assertEqual(state["staged"], ["staged.md"])
        self.assertEqual(state["unstaged"], ["AGENTS.md"])
        self.assertEqual(state["untracked"], ["untracked.md"])


class WorkflowIntegrationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.remote = self.root / "origin.git"
        self.repo = self.root / "repo"
        self.bin = self.root / "bin"
        self.state_path = self.root / "gh-state.json"
        self.bin.mkdir()
        self.write_fake_ssh()
        run(["git", "init", "--bare", str(self.remote)], cwd=self.root)
        run(["git", "init", "-b", "dev", str(self.repo)], cwd=self.root)
        run(["git", "config", "user.name", "Submit PR Test"], cwd=self.repo)
        run(
            ["git", "config", "user.email", "submit-pr@example.com"],
            cwd=self.repo,
        )
        (self.repo / ".github").mkdir()
        (self.repo / ".github" / "pull_request_template.md").write_text(
            TEMPLATE_PATH.read_text(encoding="utf-8"),
            encoding="utf-8",
        )
        (self.repo / ".gitignore").write_text(".tmp/\n", encoding="utf-8")
        (self.repo / "base.txt").write_text("base\n", encoding="utf-8")
        run(
            [
                "git",
                "add",
                ".gitignore",
                ".github/pull_request_template.md",
                "base.txt",
            ],
            cwd=self.repo,
        )
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
            ["git", "remote", "add", "origin", "git@github.com:test/Easydict.git"],
            cwd=self.repo,
        )
        run(
            ["git", "push", "-u", "origin", "dev"],
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
                "feat(agent): add submit PR workflow",
            ],
            cwd=self.repo,
        )
        self.head_sha = run(["git", "rev-parse", "HEAD"], cwd=self.repo).stdout.strip()
        self.write_fake_gh()

    def tearDown(self) -> None:
        self.temporary.cleanup()

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
                state = json.loads(state_path.read_text()) if state_path.exists() else {}

                def value(flag):
                    return args[args.index(flag) + 1]

                if args[:2] == ["auth", "status"]:
                    print("Logged in to github.com")
                elif args[:2] == ["pr", "list"]:
                    print(json.dumps([state["pr"]] if "pr" in state else []))
                elif args[:2] == ["pr", "create"]:
                    body = Path(value("--body-file")).read_text()
                    pr = {
                        "number": 42,
                        "title": value("--title"),
                        "url": "https://github.com/test/Easydict/pull/42",
                        "body": body,
                        "baseRefName": value("--base"),
                        "headRefName": value("--head"),
                        "headRefOid": os.environ["FAKE_HEAD_SHA"],
                        "headRepository": {"name": "Easydict"},
                        "headRepositoryOwner": {"login": "test"},
                        "isCrossRepository": False,
                        "isDraft": "--draft" in args,
                        "state": "OPEN",
                        "closingIssuesReferences": [],
                    }
                    state = {"pr": pr, "create_count": state.get("create_count", 0) + 1}
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

    def write_fake_ssh(self) -> None:
        fake = self.bin / "fake-ssh"
        fake.write_text(
            textwrap.dedent(
                """\
                #!/usr/bin/env python3
                import os
                import shlex
                import sys

                command = shlex.split(sys.argv[-1])
                if not command or command[0] not in {"git-upload-pack", "git-receive-pack"}:
                    raise SystemExit(2)
                os.execvp(command[0], [command[0], os.environ["FAKE_GIT_REMOTE"]])
                """
            ),
            encoding="utf-8",
        )
        fake.chmod(0o755)

    def git_environment(self) -> dict[str, str]:
        environment = os.environ.copy()
        environment["GIT_SSH_COMMAND"] = str(self.bin / "fake-ssh")
        environment["GIT_SSH_VARIANT"] = "ssh"
        environment["FAKE_GIT_REMOTE"] = str(self.remote)
        return environment

    def environment(self) -> dict[str, str]:
        environment = self.git_environment()
        environment["PATH"] = f"{self.bin}{os.pathsep}{environment['PATH']}"
        environment["FAKE_GH_STATE"] = str(self.state_path)
        environment["FAKE_HEAD_SHA"] = self.head_sha
        return environment

    def command(self, action: str, *extra: str) -> list[str]:
        return [
            sys.executable,
            str(SCRIPT_PATH),
            action,
            "--repo-root",
            str(self.repo),
            "--repo",
            "test/Easydict",
            "--title",
            "feat(agent): add PR submission workflow",
            "--summary",
            "Add deterministic PR submission.",
            "--verification",
            "- Unit tests passed.",
            "--head-branch",
            "feat/add-pr-submission",
            *extra,
        ]

    def test_plan_is_read_only(self) -> None:
        refs_before = run(
            ["git", "show-ref"],
            cwd=self.repo,
        ).stdout
        status_before = run(
            ["git", "status", "--porcelain=v1"],
            cwd=self.repo,
        ).stdout

        result = run(
            self.command("plan", "--ui-change"),
            cwd=self.repo,
            env=self.environment(),
        )
        payload = json.loads(result.stdout)

        self.assertTrue(payload["needs_screenshots"])
        self.assertEqual(payload["planned_branch_action"], "would-create")
        self.assertNotIn("branch_action", payload)
        self.assertIn(submit_pr.UI_SCREENSHOT_NOTICE, payload["body"])
        self.assertEqual(
            run(["git", "show-ref"], cwd=self.repo).stdout,
            refs_before,
        )
        self.assertEqual(
            run(["git", "status", "--porcelain=v1"], cwd=self.repo).stdout,
            status_before,
        )
        self.assertFalse((self.repo / ".tmp" / "submit-pr").exists())

    def test_apply_pushes_task_branch_creates_pr_and_is_idempotent(self) -> None:
        environment = self.environment()

        first = run(
            self.command("apply", "--ui-change"),
            cwd=self.repo,
            env=environment,
        )
        first_payload = json.loads(first.stdout)

        self.assertEqual(first_payload["push_action"], "created")
        self.assertEqual(first_payload["pr_action"], "created")
        self.assertTrue(first_payload["needs_screenshots"])
        self.assertEqual(
            run(["git", "branch", "--show-current"], cwd=self.repo).stdout.strip(),
            "dev",
        )
        remote_dev = run(
            ["git", "--git-dir", str(self.remote), "rev-parse", "refs/heads/dev"],
            cwd=self.root,
        ).stdout.strip()
        remote_head = run(
            [
                "git",
                "--git-dir",
                str(self.remote),
                "rev-parse",
                "refs/heads/feat/add-pr-submission",
            ],
            cwd=self.root,
        ).stdout.strip()
        self.assertEqual(remote_dev, self.base_sha)
        self.assertEqual(remote_head, self.head_sha)

        second = run(
            self.command("apply", "--ui-change"),
            cwd=self.repo,
            env=environment,
        )
        second_payload = json.loads(second.stdout)
        state = json.loads(self.state_path.read_text(encoding="utf-8"))

        self.assertEqual(second_payload["pr_action"], "reused")
        self.assertEqual(state["create_count"], 1)

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
        self.assertFalse(self.state_path.exists())
        remote_heads = run(
            ["git", "--git-dir", str(self.remote), "for-each-ref", "refs/heads"],
            cwd=self.root,
        ).stdout
        self.assertNotIn("feat/add-pr-submission", remote_heads)

    def test_plan_rejects_auto_closing_commit_message(self) -> None:
        run(
            [
                "git",
                "-c",
                "commit.gpgsign=false",
                "commit",
                "--amend",
                "-m",
                "feat(agent): add submit PR workflow",
                "-m",
                "Fixes #123",
            ],
            cwd=self.repo,
        )

        result = subprocess.run(
            self.command("plan"),
            cwd=self.repo,
            env=self.environment(),
            check=False,
            capture_output=True,
            text=True,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("auto-closing", result.stderr)
        self.assertFalse(self.state_path.exists())

    def test_apply_rejects_wrong_origin_before_github_or_fetch(self) -> None:
        run(
            ["git", "remote", "set-url", "origin", "git@github.com:wrong/Repo.git"],
            cwd=self.repo,
        )
        fetch_head = self.repo / ".git" / "FETCH_HEAD"
        before = fetch_head.read_bytes() if fetch_head.exists() else None

        result = subprocess.run(
            self.command("apply"),
            cwd=self.repo,
            env=self.environment(),
            check=False,
            capture_output=True,
            text=True,
        )

        after = fetch_head.read_bytes() if fetch_head.exists() else None
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("not 'test/Easydict'", result.stderr)
        self.assertEqual(after, before)
        self.assertFalse(self.state_path.exists())

    def test_draft_mode_is_created_and_verified(self) -> None:
        result = run(
            self.command("apply", "--draft"),
            cwd=self.repo,
            env=self.environment(),
        )
        payload = json.loads(result.stdout)
        state = json.loads(self.state_path.read_text(encoding="utf-8"))

        self.assertTrue(payload["draft"])
        self.assertTrue(state["pr"]["isDraft"])

    def test_apply_rejects_diverged_remote_task_branch(self) -> None:
        run(
            ["git", "switch", "-c", "feat/add-pr-submission"],
            cwd=self.repo,
        )
        other = self.root / "other"
        run(["git", "clone", str(self.remote), str(other)], cwd=self.root)
        run(["git", "switch", "-c", "feat/add-pr-submission", "origin/dev"], cwd=other)
        run(["git", "config", "user.name", "Remote Test"], cwd=other)
        run(["git", "config", "user.email", "remote@example.com"], cwd=other)
        (other / "remote.txt").write_text("remote\n", encoding="utf-8")
        run(["git", "add", "remote.txt"], cwd=other)
        run(
            [
                "git",
                "-c",
                "commit.gpgsign=false",
                "commit",
                "-m",
                "feat: create divergent remote work",
            ],
            cwd=other,
        )
        run(
            ["git", "push", "origin", "feat/add-pr-submission"],
            cwd=other,
        )

        result = subprocess.run(
            self.command("apply"),
            cwd=self.repo,
            env=self.environment(),
            check=False,
            capture_output=True,
            text=True,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("ahead or diverged", result.stderr)
        self.assertFalse(self.state_path.exists())

    def test_existing_pr_content_is_not_overwritten(self) -> None:
        environment = self.environment()
        run(self.command("apply"), cwd=self.repo, env=environment)
        state = json.loads(self.state_path.read_text(encoding="utf-8"))
        state["pr"]["body"] = "Maintainer-edited body"
        self.state_path.write_text(json.dumps(state), encoding="utf-8")

        result = subprocess.run(
            self.command("apply"),
            cwd=self.repo,
            env=environment,
            check=False,
            capture_output=True,
            text=True,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("body differs", result.stderr)
        self.assertEqual(
            json.loads(self.state_path.read_text(encoding="utf-8"))["create_count"],
            1,
        )


if __name__ == "__main__":
    unittest.main()
