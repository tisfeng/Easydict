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
EXPECTED_HEADINGS = [
    "## 背景 / Context",
    "## 变更内容 / Changes",
    "## 关联 Issue / Linked Issues",
    "## 验证 / Verification",
    "## 截图 / Screenshots",
]
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
            "context": "PR creation needs a deterministic workflow.",
            "changes": "Add deterministic PR planning and submission.",
            "verification": "- Unit tests passed.",
            "issues": ("#123",),
            "ui_change": False,
            "draft": False,
        }
        values.update(overrides)
        return submit_pr.PRContent(**values)

    def test_bundled_template_renders_fixed_five_section_contract(self) -> None:
        body = submit_pr.render_pr_body(self.content())

        self.assertEqual(
            [line for line in body.splitlines() if line.startswith("## ")],
            EXPECTED_HEADINGS,
        )
        self.assertIn("## 背景 / Context\n\nPR creation needs", body)
        self.assertIn("## 变更内容 / Changes\n\nAdd deterministic", body)
        self.assertIn("## 关联 Issue / Linked Issues\n\n- #123", body)
        self.assertTrue(body.endswith("## 截图 / Screenshots\n\nN/A\n"))

    def test_optional_issues_and_ui_screenshot_notice_are_rendered(self) -> None:
        body = submit_pr.render_pr_body(self.content(issues=(), ui_change=True))

        linked = body.split(EXPECTED_HEADINGS[2], 1)[1]
        linked = linked.split(EXPECTED_HEADINGS[3], 1)[0]
        self.assertEqual(linked.strip(), "")
        self.assertTrue(body.endswith(f"{submit_pr.UI_SCREENSHOT_NOTICE}\n"))

    def test_issue_policy_forbid_rejects_auto_close_but_neutral_allows_it(self) -> None:
        neutral = submit_pr.render_pr_body(
            self.content(context="Fixes #123", issue_policy="neutral"),
        )
        self.assertIn("Fixes #123", neutral)

        with self.assertRaisesRegex(submit_pr.SubmitPRError, "auto-closing"):
            submit_pr.render_pr_body(
                self.content(context="Fixes #123", issue_policy="forbid"),
            )

    def test_context_and_changes_are_required(self) -> None:
        for field in ("context", "changes"):
            with self.subTest(field=field):
                with self.assertRaisesRegex(submit_pr.SubmitPRError, field):
                    submit_pr.render_pr_body(self.content(**{field: ""}))


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
                state.setdefault("gh_calls", []).append(args)
                state_path.write_text(json.dumps(state))

                def value(flag):
                    return args[args.index(flag) + 1]

                if args[:2] == ["auth", "status"]:
                    print("Logged in to github.com")
                elif args[:2] == ["repo", "view"]:
                    state.setdefault("repo_views", []).append(args[2])
                    state_path.write_text(json.dumps(state))
                    print(json.dumps(state["repos"][args[2].casefold()]))
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
                    state["pr"]["headRefOid"] = (
                        "0" * 40
                        if state.get("corrupt_final_view")
                        else os.environ["FAKE_HEAD_SHA"]
                    )
                    state_path.write_text(json.dumps(state))
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

    def command(
        self,
        action: str,
        *extra: str,
        title: str = "feat(cli): add deterministic PR submission",
        context: str = "PR creation needs a deterministic workflow.",
        changes: str = "Add deterministic PR submission.",
        verification: str = "- Unit tests passed.",
        head_branch: str | None = "feat/deterministic-pr-submission",
    ) -> list[str]:
        command = [
            sys.executable,
            str(SCRIPT_PATH),
            action,
            "--repo-root",
            str(self.repo),
            "--title",
            title,
            "--context",
            context,
            "--changes",
            changes,
            "--verification",
            verification,
        ]
        if head_branch is not None:
            command.extend(("--head-branch", head_branch))
        return [*command, *extra]

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
        self.assertNotIn("template", payload)
        self.assertTrue(payload["needs_screenshots"])
        self.assertEqual(
            [line for line in payload["body"].splitlines() if line.startswith("## ")],
            EXPECTED_HEADINGS,
        )
        self.assertEqual(run(["git", "show-ref"], cwd=self.repo).stdout, refs_before)
        self.assertEqual(
            run(["git", "status", "--porcelain=v1"], cwd=self.repo).stdout,
            status_before,
        )
        fetch_after = fetch_head.read_bytes() if fetch_head.exists() else None
        self.assertEqual(fetch_after, fetch_before)
        self.assertFalse((self.repo / ".tmp" / "submit-pr").exists())

    def test_detached_plan_previews_branch_creation_without_mutation(self) -> None:
        run(
            ["git", "config", "branch.main.gh-merge-base", "obsolete"],
            cwd=self.repo,
        )
        run(["git", "checkout", "--detach", self.head_sha], cwd=self.repo)
        refs_before = run(["git", "show-ref"], cwd=self.repo).stdout
        status_before = run(["git", "status", "--porcelain=v1"], cwd=self.repo).stdout

        payload = json.loads(
            run(self.command("plan"), cwd=self.repo, env=self.environment()).stdout
        )

        self.assertIsNone(payload["current_branch"])
        self.assertEqual(payload["base"], "main")
        self.assertEqual(payload["head_branch"], "feat/deterministic-pr-submission")
        self.assertEqual(payload["planned_branch_action"], "would-create")
        self.assertEqual(run(["git", "show-ref"], cwd=self.repo).stdout, refs_before)
        self.assertEqual(
            run(["git", "status", "--porcelain=v1"], cwd=self.repo).stdout,
            status_before,
        )
        self.assertEqual(
            run(["git", "branch", "--show-current"], cwd=self.repo).stdout,
            "",
        )

    def test_detached_plan_suffixes_a_divergent_local_branch(self) -> None:
        base_tree = run(
            ["git", "rev-parse", f"{self.base_sha}^{{tree}}"],
            cwd=self.repo,
        ).stdout.strip()
        divergent_sha = run(
            [
                "git",
                "commit-tree",
                base_tree,
                "-p",
                self.base_sha,
                "-m",
                "chore: occupy task branch",
            ],
            cwd=self.repo,
        ).stdout.strip()
        run(
            [
                "git",
                "branch",
                "feat/deterministic-pr-submission",
                divergent_sha,
            ],
            cwd=self.repo,
        )
        run(["git", "checkout", "--detach", self.head_sha], cwd=self.repo)
        refs_before = run(["git", "show-ref"], cwd=self.repo).stdout
        status_before = run(["git", "status", "--porcelain=v1"], cwd=self.repo).stdout

        payload = json.loads(
            run(self.command("plan"), cwd=self.repo, env=self.environment()).stdout
        )

        self.assertEqual(
            payload["head_branch"],
            "feat/deterministic-pr-submission-2",
        )
        self.assertEqual(payload["planned_branch_action"], "would-create")
        self.assertEqual(run(["git", "show-ref"], cwd=self.repo).stdout, refs_before)
        self.assertEqual(
            run(["git", "status", "--porcelain=v1"], cwd=self.repo).stdout,
            status_before,
        )
        self.assertEqual(
            run(["git", "branch", "--show-current"], cwd=self.repo).stdout,
            "",
        )

    def test_detached_plan_requires_agent_supplied_branch_without_mutation(self) -> None:
        run(["git", "checkout", "--detach", self.head_sha], cwd=self.repo)
        refs_before = run(["git", "show-ref"], cwd=self.repo).stdout

        result = subprocess.run(
            self.command("plan", head_branch=None),
            cwd=self.repo,
            env=self.environment(),
            check=False,
            capture_output=True,
            text=True,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("--head-branch is required when HEAD is detached", result.stderr)
        self.assertEqual(run(["git", "show-ref"], cwd=self.repo).stdout, refs_before)

    def test_plan_ignores_repository_pr_templates(self) -> None:
        template_directory = self.repo / ".github" / "PULL_REQUEST_TEMPLATE"
        template_directory.mkdir(parents=True)
        (self.repo / ".github" / "PULL_REQUEST_TEMPLATE.md").write_text(
            "## 变更摘要\n\n仓库旧摘要\n\n"
            "## 验证情况\n\n仓库旧验证\n\n"
            "## 关联上下文\n\n仓库旧上下文\n",
            encoding="utf-8",
        )
        (template_directory / "maintenance.md").write_text(
            "## Maintainer Checklist\n\n- [ ] Legacy marker\n",
            encoding="utf-8",
        )

        payload = json.loads(
            run(self.command("plan"), cwd=self.repo, env=self.environment()).stdout
        )

        self.assertEqual(
            [line for line in payload["body"].splitlines() if line.startswith("## ")],
            EXPECTED_HEADINGS,
        )
        for repository_text in (
            "变更摘要",
            "验证情况",
            "关联上下文",
            "仓库旧摘要",
            "Legacy marker",
        ):
            self.assertNotIn(repository_text, payload["body"])

    def test_removed_body_options_are_rejected(self) -> None:
        for option, value in (
            ("--summary", "Legacy summary"),
            ("--template", ".github/PULL_REQUEST_TEMPLATE.md"),
            ("--extra-body-file", "extra.md"),
        ):
            with self.subTest(option=option):
                result = subprocess.run(
                    self.command("plan", option, value),
                    cwd=self.repo,
                    env=self.environment(),
                    check=False,
                    capture_output=True,
                    text=True,
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("unrecognized arguments", result.stderr)

    def test_plan_rejects_expanded_protected_or_invalid_explicit_branch_without_mutation(self) -> None:
        run(["git", "branch", "feat/previous-checkout", "HEAD"], cwd=self.repo)
        run(["git", "checkout", "feat/previous-checkout"], cwd=self.repo)
        run(["git", "checkout", "main"], cwd=self.repo)
        expansion = run(["git", "check-ref-format", "--branch", "@{-1}"], cwd=self.repo).stdout.strip()
        self.assertNotEqual(expansion, "@{-1}")

        for requested, option in (
            ("@{-1}", ()),
            ("main", ("--protected-branch", "main")),
            ("invalid..branch", ()),
        ):
            with self.subTest(requested=requested):
                refs_before = run(["git", "show-ref"], cwd=self.repo).stdout
                checkout_before = run(["git", "branch", "--show-current"], cwd=self.repo).stdout
                result = subprocess.run(
                    self.command("plan", "--head-branch", requested, *option),
                    cwd=self.repo,
                    env=self.environment(),
                    check=False,
                    capture_output=True,
                    text=True,
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(result.stdout, "")
                self.assertEqual(run(["git", "show-ref"], cwd=self.repo).stdout, refs_before)
                self.assertEqual(
                    run(["git", "branch", "--show-current"], cwd=self.repo).stdout,
                    checkout_before,
                )

    def test_apply_pushes_same_repo_branch_and_reuses_pr(self) -> None:
        environment = self.environment()
        first = json.loads(
            run(self.command("apply"), cwd=self.repo, env=environment).stdout
        )

        self.assertEqual(first["push_action"], "created")
        self.assertEqual(first["pr_action"], "created")
        self.assertFalse(first["is_cross_repository"])
        self.assertEqual(first["pr_verification"]["status"], "passed")
        self.assertEqual(first["pr_verification"]["head_sha"], self.head_sha)
        self.assertEqual(len(first["pr_verification"]["body_sha256"]), 64)
        self.assertGreaterEqual(first["timings_ms"]["total"], 0)
        self.assertTrue(
            {
                "worktree_check",
                "github_auth",
                "topology",
                "fetch_base",
                "plan_revalidation",
                "existing_pr_lookup",
                "local_branch",
                "push",
                "pr_create",
                "final_pr_verification",
            }.issubset(first["timings_ms"])
        )
        state = json.loads(self.state_path.read_text(encoding="utf-8"))
        self.assertEqual(
            [
                line
                for line in state["pr"]["body"].splitlines()
                if line.startswith("## ")
            ],
            EXPECTED_HEADINGS,
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

        state["gh_calls"] = []
        self.state_path.write_text(json.dumps(state), encoding="utf-8")
        second = json.loads(
            run(self.command("apply"), cwd=self.repo, env=environment).stdout
        )
        state = json.loads(self.state_path.read_text(encoding="utf-8"))
        self.assertEqual(second["pr_action"], "reused")
        self.assertEqual(state["create_count"], 1)
        self.assertEqual(
            sum(call[:2] == ["pr", "view"] for call in state["gh_calls"]),
            1,
        )

    def test_detached_apply_creates_branch_without_attaching_checkout(self) -> None:
        run(["git", "checkout", "--detach", self.head_sha], cwd=self.repo)

        payload = json.loads(
            run(self.command("apply"), cwd=self.repo, env=self.environment()).stdout
        )

        self.assertEqual(payload["branch_action"], "created")
        self.assertEqual(payload["push_action"], "created")
        self.assertEqual(payload["pr_action"], "created")
        self.assertEqual(payload["pr_verification"]["status"], "passed")
        self.assertEqual(
            run(["git", "branch", "--show-current"], cwd=self.repo).stdout,
            "",
        )
        self.assertEqual(
            run(
                [
                    "git",
                    "rev-parse",
                    "refs/heads/feat/deterministic-pr-submission",
                ],
                cwd=self.repo,
            ).stdout.strip(),
            self.head_sha,
        )

        repeated = json.loads(
            run(self.command("apply"), cwd=self.repo, env=self.environment()).stdout
        )
        self.assertEqual(repeated["branch_action"], "reused")
        self.assertEqual(repeated["push_action"], "reused")
        self.assertEqual(repeated["pr_action"], "reused")
        self.assertEqual(
            run(["git", "branch", "--show-current"], cwd=self.repo).stdout,
            "",
        )

    def test_local_branch_write_rejects_checkout_state_drift(self) -> None:
        run(["git", "checkout", "--detach", self.head_sha], cwd=self.repo)
        run(["git", "checkout", "main"], cwd=self.repo)

        with self.assertRaisesRegex(submit_pr.SubmitPRError, "checkout changed"):
            submit_pr.ensure_local_branch(
                self.repo,
                None,
                "feat/deterministic-pr-submission",
                self.head_sha,
            )

        self.assertIsNone(
            submit_pr.local_branch_sha(
                self.repo,
                "feat/deterministic-pr-submission",
            )
        )

    def test_apply_fast_forwards_existing_pr_after_new_local_commit(self) -> None:
        first_environment = self.environment()
        first = json.loads(
            run(self.command("apply"), cwd=self.repo, env=first_environment).stdout
        )
        self.assertEqual(first["pr_action"], "created")

        (self.repo / "follow-up.txt").write_text("follow-up\n", encoding="utf-8")
        run(["git", "add", "follow-up.txt"], cwd=self.repo)
        run(
            [
                "git",
                "-c",
                "commit.gpgsign=false",
                "commit",
                "-m",
                "fix(cli): refine PR submission",
            ],
            cwd=self.repo,
        )
        self.head_sha = run(["git", "rev-parse", "HEAD"], cwd=self.repo).stdout.strip()

        planned = json.loads(
            run(self.command("plan"), cwd=self.repo, env=self.environment()).stdout
        )
        self.assertEqual(planned["planned_branch_action"], "would-update")

        second = json.loads(
            run(self.command("apply"), cwd=self.repo, env=self.environment()).stdout
        )

        self.assertEqual(second["push_action"], "updated")
        self.assertEqual(second["pr_action"], "reused")
        self.assertEqual(second["branch_action"], "updated")
        state = json.loads(self.state_path.read_text(encoding="utf-8"))
        self.assertEqual(state["create_count"], 1)
        self.assertEqual(state["pr"]["headRefOid"], self.head_sha)
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
        self.assertEqual(remote_head, self.head_sha)

    def test_final_verification_failure_does_not_emit_success_receipt(self) -> None:
        state = json.loads(self.state_path.read_text(encoding="utf-8"))
        state["corrupt_final_view"] = True
        self.state_path.write_text(json.dumps(state), encoding="utf-8")

        result = subprocess.run(
            self.command("apply"),
            cwd=self.repo,
            env=self.environment(),
            check=False,
            capture_output=True,
            text=True,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertIn("headRefOid", result.stderr)

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

    def test_apply_rejects_multiple_push_urls_before_remote_writes(self) -> None:
        run(
            [
                "git",
                "remote",
                "set-url",
                "--add",
                "--push",
                "upstream",
                "git@github.com:acme/project.git",
            ],
            cwd=self.repo,
        )
        run(
            [
                "git",
                "remote",
                "set-url",
                "--add",
                "--push",
                "upstream",
                "git@github.com:contrib/project.git",
            ],
            cwd=self.repo,
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
        self.assertIn("multiple push URLs", result.stderr)
        self.assertNotIn("pr", json.loads(self.state_path.read_text(encoding="utf-8")))

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

    def test_batched_commit_log_preserves_multiple_subjects_and_full_messages(self) -> None:
        (self.repo / "follow-up.txt").write_text("follow-up\n", encoding="utf-8")
        run(["git", "add", "follow-up.txt"], cwd=self.repo)
        run(
            [
                "git",
                "-c",
                "commit.gpgsign=false",
                "commit",
                "-m",
                "fix(cli): preserve multilingual PR evidence",
                "-m",
                "保留多语言提交正文。\n\nResolves #321",
            ],
            cwd=self.repo,
        )

        planned = json.loads(
            run(self.command("plan"), cwd=self.repo, env=self.environment()).stdout
        )
        self.assertEqual(
            [commit["subject"] for commit in planned["commits"]],
            [
                "feat(cli): add deterministic PR submission",
                "fix(cli): preserve multilingual PR evidence",
            ],
        )

        forbidden = subprocess.run(
            self.command("plan", "--issue-policy", "forbid"),
            cwd=self.repo,
            env=self.environment(),
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertNotEqual(forbidden.returncode, 0)
        self.assertIn("auto-closing", forbidden.stderr)

    def test_existing_pr_language_change_stops_without_overwrite(self) -> None:
        environment = self.environment()
        run(self.command("apply"), cwd=self.repo, env=environment)
        state_before = json.loads(self.state_path.read_text(encoding="utf-8"))

        result = subprocess.run(
            self.command(
                "apply",
                title="perf(git-workflow): 优化技能执行编排",
                context="现有流程包含不必要的模型往返。",
                changes="减少可预测 Git 工作流中的模型往返。",
                verification="- 已通过针对性行为测试。",
            ),
            cwd=self.repo,
            env=environment,
            check=False,
            capture_output=True,
            text=True,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("title: expected", result.stderr)
        self.assertIn("body differs", result.stderr)
        state_after = json.loads(self.state_path.read_text(encoding="utf-8"))
        self.assertEqual(state_after["pr"], state_before["pr"])
        self.assertEqual(state_after["create_count"], state_before["create_count"])

    def test_existing_pr_with_legacy_body_stops_without_overwrite(self) -> None:
        environment = self.environment()
        run(self.command("apply"), cwd=self.repo, env=environment)
        state_before = json.loads(self.state_path.read_text(encoding="utf-8"))
        state_before["pr"]["body"] = (
            "## 变更说明 / Summary\n\nLegacy summary\n\n"
            "## 关联 Issue / Linked Issues\n\n"
            "## 验证 / Verification\n\n- Legacy verification\n\n"
            "## 截图 / Screenshots\n\nN/A\n"
        )
        self.state_path.write_text(json.dumps(state_before), encoding="utf-8")

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
        state_after = json.loads(self.state_path.read_text(encoding="utf-8"))
        self.assertEqual(state_after["pr"], state_before["pr"])
        self.assertEqual(state_after["create_count"], state_before["create_count"])

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
