import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[3]
ENTRYPOINT = ROOT / "scripts/release/release-easydict.sh"
COMMON = ROOT / "scripts/release/release-common.sh"
REDRAFT_GIT = ROOT / "scripts/release/release-redraft-git.sh"
REDRAFT = ROOT / "scripts/release/release-redraft.sh"
WORKFLOW = ROOT / "scripts/release/asc-workflow.json"


def run(command, *, cwd=None, env=None, check=True):
    result = subprocess.run(
        command,
        cwd=cwd,
        env=env,
        check=check,
        text=True,
        capture_output=True,
    )
    return result


class ReleaseRedraftTests(unittest.TestCase):
    def test_cli_passes_replace_mode_and_rejects_unsafe_combinations(self):
        version = "9.98.0"
        release_dir = ROOT / f".tmp/release/{version}"
        with tempfile.TemporaryDirectory() as directory:
            tool_dir = Path(directory)
            capture = tool_dir / "arguments.json"
            fake_asc = tool_dir / "asc"
            fake_asc.write_text(
                """#!/usr/bin/env python3
import json
import os
import sys

if sys.argv[1:3] == [\"workflow\", \"validate\"]:
    raise SystemExit(0)
with open(os.environ[\"ASC_CAPTURE\"], \"w\", encoding=\"utf-8\") as handle:
    json.dump(sys.argv[1:], handle)
print(json.dumps({
    \"workflow\": \"draft\",
    \"status\": \"ok\",
    \"run_id\": \"draft-redraft-test\",
    \"steps\": [],
}))
""",
                encoding="utf-8",
            )
            fake_asc.chmod(0o755)
            env = os.environ.copy()
            env["PATH"] = f"{tool_dir}:{env['PATH']}"
            env["ASC_CAPTURE"] = str(capture)

            result = run(
                [str(ENTRYPOINT), "draft", version, "--replace-draft"],
                cwd=ROOT,
                env=env,
            )
            self.assertEqual(result.returncode, 0)
            arguments = json.loads(capture.read_text(encoding="utf-8"))
            self.assertIn("DRAFT_MODE:replace", arguments)

            run([str(ENTRYPOINT), "draft", version], cwd=ROOT, env=env)
            arguments = json.loads(capture.read_text(encoding="utf-8"))
            self.assertIn("DRAFT_MODE:normal", arguments)

            result = run(
                [str(ENTRYPOINT), "publish", version, "--replace-draft"],
                cwd=ROOT,
                env=env,
                check=False,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("supported only with draft", result.stderr)

            result = run(
                [
                    str(ENTRYPOINT),
                    "draft",
                    version,
                    "--replace-draft",
                    "--build-number",
                    "99",
                ],
                cwd=ROOT,
                env=env,
                check=False,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("chooses the next build number automatically", result.stderr)
        shutil.rmtree(release_dir, ignore_errors=True)

    def test_build_number_uses_maximum_plus_one(self):
        result = run(
            [
                "bash",
                "-c",
                f"source {COMMON!s}; next_replacement_build 64 66 65",
            ],
            cwd=ROOT,
        )
        self.assertEqual(result.stdout.strip(), "67")

    def test_workflow_keeps_remote_changes_after_local_verification(self):
        workflow = json.loads(WORKFLOW.read_text(encoding="utf-8"))
        prepare = [
            step["name"]
            for step in workflow["workflows"]["prepare_steps"]["steps"]
        ]
        draft = [
            step["name"]
            for step in workflow["workflows"]["draft_steps"]["steps"]
        ]
        publish = [
            step["name"]
            for step in workflow["workflows"]["publish_steps"]["steps"]
        ]

        self.assertLess(
            prepare.index("snapshot_draft_replacement"),
            prepare.index("archive_replaced_local_state"),
        )
        self.assertLess(
            prepare.index("archive_replaced_local_state"),
            prepare.index("sync_local_dev"),
        )
        self.assertEqual(prepare[-1], "verify_local_release")
        self.assertEqual(
            draft,
            [
                "revalidate_draft_replacement",
                "push_draft_refs",
                "delete_replaced_github_draft",
                "create_github_draft",
                "verify_github_draft",
                "cleanup_draft_replacement",
            ],
        )
        self.assertLess(
            publish.index("prepare_publish_git"),
            publish.index("publish_github_release"),
        )
        self.assertLess(
            publish.index("install_appcast"),
            publish.index("push_published_refs"),
        )
        self.assertLess(
            publish.index("verify_remote_release"),
            publish.index("cleanup_remote_release_branch"),
        )
        self.assertNotIn("push_appcast_refs", publish)

    def test_snapshot_requires_latest_unpublished_version(self):
        version = "4.5.6"
        with tempfile.TemporaryDirectory() as directory:
            temporary = Path(directory)
            repository = temporary / "repository"
            remote = temporary / "origin.git"
            tools = temporary / "tools"
            tools.mkdir()
            run(["git", "init", "--bare", str(remote)])
            run(["git", "init", "-b", "dev", str(repository)])
            run(["git", "config", "user.name", "Release Test"], cwd=repository)
            run(
                ["git", "config", "user.email", "release@example.com"],
                cwd=repository,
            )
            run(["git", "config", "commit.gpgsign", "false"], cwd=repository)
            (repository / "source.txt").write_text("release\n", encoding="utf-8")
            run(["git", "add", "source.txt"], cwd=repository)
            run(["git", "commit", "-m", "release"], cwd=repository)
            commit = run(["git", "rev-parse", "HEAD"], cwd=repository).stdout.strip()
            run(["git", "tag", "-a", version, "-m", version], cwd=repository)
            run(["git", "remote", "add", "origin", str(remote)], cwd=repository)
            run(["git", "push", "origin", "dev", f"refs/tags/{version}"], cwd=repository)

            state = repository / f".tmp/release/{version}/state"
            state.mkdir(parents=True)
            (state / "release.env").write_text(
                "\n".join(
                    [
                        f"RELEASE_SAVED_VERSION={version}",
                        "RELEASE_SAVED_BUILD=12",
                        "RELEASE_SAVED_CHANNEL=beta",
                        f"RELEASE_VERSION_COMMIT={commit}",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            fake_gh = tools / "gh"
            fake_gh.write_text(
                """#!/usr/bin/env python3
import os
import sys

arguments = \" \".join(sys.argv[1:])
if \"releases?per_page=1\" in arguments:
    print(os.environ[\"TOP_RELEASE_JSON\"])
elif \"contents/appcast.xml\" in arguments:
    print(os.environ[\"PUBLIC_APPCAST\"])
else:
    raise SystemExit(f\"unexpected gh call: {arguments}\")
""",
                encoding="utf-8",
            )
            fake_gh.chmod(0o755)
            env = os.environ.copy()
            env.update(
                {
                    "PATH": f"{tools}:{env['PATH']}",
                    "RELEASE_SOURCE_ROOT": str(repository),
                    "RELEASE_REPOSITORY": "example/repository",
                    "VERSION": version,
                    "CHANNEL": "beta",
                    "DRAFT_MODE": "replace",
                    "RELEASE_RUN_MODE": "new",
                    "PUBLIC_APPCAST": "<rss><shortVersionString>4.5.5</shortVersionString></rss>",
                }
            )
            release = {
                "id": 321,
                "node_id": "R_test",
                "tag_name": "4.5.5",
                "draft": True,
                "prerelease": True,
                "created_at": "2026-08-23T00:00:00Z",
                "updated_at": "2026-08-23T00:00:00Z",
            }
            env["TOP_RELEASE_JSON"] = json.dumps([release])
            result = run(
                [str(REDRAFT), "snapshot"],
                cwd=repository,
                env=env,
                check=False,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("not the latest GitHub Release entry", result.stderr)

            replacement = repository / f".tmp/release/{version}/replacement"
            self.assertFalse(replacement.exists())
            shutil.rmtree(replacement, ignore_errors=True)
            release["tag_name"] = version
            env["TOP_RELEASE_JSON"] = json.dumps([release])
            env["PUBLIC_APPCAST"] = (
                f"<rss><shortVersionString>{version}</shortVersionString></rss>"
            )
            result = run(
                [str(REDRAFT), "snapshot"],
                cwd=repository,
                env=env,
                check=False,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("already present in the public appcast", result.stderr)
            self.assertFalse(replacement.exists())

            shutil.rmtree(replacement, ignore_errors=True)
            env["PUBLIC_APPCAST"] = (
                "<rss><shortVersionString>4.5.5</shortVersionString></rss>"
            )
            run([str(REDRAFT), "snapshot"], cwd=repository, env=env)
            metadata = (replacement / "metadata.env").read_text(encoding="utf-8")
            self.assertIn("REPLACEMENT_DRAFT_ID=321", metadata)
            self.assertIn("REPLACEMENT_OLD_BUILD=12", metadata)
            self.assertIn("REPLACEMENT_OLD_RELEASE_BRANCH_OID=missing", metadata)
            snapshot = json.loads(
                (replacement / "github-draft.json").read_text(encoding="utf-8")
            )
            self.assertEqual(snapshot["id"], 321)
            result = run(
                [str(REDRAFT), "snapshot"],
                cwd=repository,
                env=env,
                check=False,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("resume its asc run", result.stderr)
            env["RELEASE_RUN_MODE"] = "resume"
            run([str(REDRAFT), "snapshot"], cwd=repository, env=env)

    def test_replacement_tag_push_is_atomic_and_idempotent(self):
        version = "3.2.1"
        with tempfile.TemporaryDirectory() as directory:
            temporary = Path(directory)
            repository = temporary / "repository"
            remote = temporary / "origin.git"
            run(["git", "init", "--bare", str(remote)])
            run(["git", "init", "-b", "dev", str(repository)])
            run(["git", "config", "user.name", "Release Test"], cwd=repository)
            run(
                ["git", "config", "user.email", "release@example.com"],
                cwd=repository,
            )
            run(["git", "config", "commit.gpgsign", "false"], cwd=repository)
            (repository / "source.txt").write_text("old\n", encoding="utf-8")
            run(["git", "add", "source.txt"], cwd=repository)
            run(["git", "commit", "-m", "old release"], cwd=repository)
            old_commit = run(["git", "rev-parse", "HEAD"], cwd=repository).stdout.strip()
            run(["git", "branch", "main"], cwd=repository)
            run(["git", "tag", "-a", version, "-m", version], cwd=repository)
            old_tag_oid = run(
                ["git", "rev-parse", f"refs/tags/{version}"], cwd=repository
            ).stdout.strip()
            run(["git", "remote", "add", "origin", str(remote)], cwd=repository)
            run(
                ["git", "push", "origin", "dev", "main", f"refs/tags/{version}"],
                cwd=repository,
            )

            (repository / "source.txt").write_text("replacement\n", encoding="utf-8")
            run(["git", "commit", "-am", "replacement release"], cwd=repository)
            new_commit = run(["git", "rev-parse", "HEAD"], cwd=repository).stdout.strip()

            release_dir = repository / f".tmp/release/{version}"
            worktree = release_dir / "worktree"
            worktree.parent.mkdir(parents=True)
            run(
                [
                    "git",
                    "worktree",
                    "add",
                    "-b",
                    f"release/sync-{version}",
                    str(worktree),
                    new_commit,
                ],
                cwd=repository,
            )
            state = release_dir / "state"
            replacement = release_dir / "replacement"
            state.mkdir()
            replacement.mkdir()
            (state / "release.env").write_text(
                "\n".join(
                    [
                        f"RELEASE_SAVED_VERSION={version}",
                        "RELEASE_SAVED_BUILD=8",
                        "RELEASE_SAVED_CHANNEL=beta",
                        f"RELEASE_VERSION_COMMIT={new_commit}",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )
            (replacement / "metadata.env").write_text(
                "\n".join(
                    [
                        f"REPLACEMENT_VERSION={version}",
                        "REPLACEMENT_CHANNEL=beta",
                        "REPLACEMENT_DRAFT_ID=123",
                        "REPLACEMENT_OLD_BUILD=7",
                        f"REPLACEMENT_OLD_VERSION_COMMIT={old_commit}",
                        f"REPLACEMENT_OLD_TAG_OID={old_tag_oid}",
                        f"REPLACEMENT_OLD_TAG_COMMIT={old_commit}",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            env = os.environ.copy()
            env.update(
                {
                    "RELEASE_SOURCE_ROOT": str(repository),
                    "VERSION": version,
                    "CHANNEL": "beta",
                    "DRAFT_MODE": "replace",
                }
            )
            run([str(REDRAFT_GIT), "push-refs"], cwd=repository, env=env)
            run([str(REDRAFT_GIT), "push-refs"], cwd=repository, env=env)

            for ref in ("refs/heads/dev", "refs/heads/main"):
                value = run(["git", "--git-dir", str(remote), "rev-parse", ref])
                self.assertEqual(value.stdout.strip(), old_commit)
            release_ref = run(
                [
                    "git",
                    "--git-dir",
                    str(remote),
                    "rev-parse",
                    f"refs/heads/release/sync-{version}",
                ]
            )
            self.assertEqual(release_ref.stdout.strip(), new_commit)
            peeled = run(
                [
                    "git",
                    "--git-dir",
                    str(remote),
                    "rev-parse",
                    f"refs/tags/{version}^{{commit}}",
                ]
            )
            self.assertEqual(peeled.stdout.strip(), new_commit)
            self.assertTrue((replacement / "refs-replaced.complete").is_file())

    def test_archive_is_temporary_and_cleanup_preserves_new_state(self):
        version = "5.0.0"
        with tempfile.TemporaryDirectory() as directory:
            repository = Path(directory).resolve() / "repository"
            run(["git", "init", "-b", "dev", str(repository)])
            run(["git", "config", "user.name", "Release Test"], cwd=repository)
            run(
                ["git", "config", "user.email", "release@example.com"],
                cwd=repository,
            )
            run(["git", "config", "commit.gpgsign", "false"], cwd=repository)
            (repository / "source.txt").write_text("old\n", encoding="utf-8")
            run(["git", "add", "source.txt"], cwd=repository)
            run(["git", "commit", "-m", "old release"], cwd=repository)
            commit = run(["git", "rev-parse", "HEAD"], cwd=repository).stdout.strip()
            run(["git", "tag", "-a", version, "-m", version], cwd=repository)
            tag_oid = run(
                ["git", "rev-parse", f"refs/tags/{version}"], cwd=repository
            ).stdout.strip()

            release_dir = repository / f".tmp/release/{version}"
            worktree = release_dir / "worktree"
            worktree.parent.mkdir(parents=True)
            run(
                [
                    "git",
                    "worktree",
                    "add",
                    "-b",
                    f"release/sync-{version}",
                    str(worktree),
                    commit,
                ],
                cwd=repository,
            )
            state = release_dir / "state"
            artifacts = release_dir / "artifacts"
            replacement = release_dir / "replacement"
            state.mkdir()
            artifacts.mkdir()
            replacement.mkdir()
            (state / "release.env").write_text("old state\n", encoding="utf-8")
            (artifacts / "old.zip").write_text("old artifact\n", encoding="utf-8")
            (replacement / "metadata.env").write_text(
                "\n".join(
                    [
                        f"REPLACEMENT_VERSION={version}",
                        "REPLACEMENT_CHANNEL=beta",
                        "REPLACEMENT_DRAFT_ID=500",
                        "REPLACEMENT_OLD_BUILD=20",
                        f"REPLACEMENT_OLD_VERSION_COMMIT={commit}",
                        f"REPLACEMENT_OLD_TAG_OID={tag_oid}",
                        f"REPLACEMENT_OLD_TAG_COMMIT={commit}",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )
            env = os.environ.copy()
            env.update(
                {
                    "RELEASE_SOURCE_ROOT": str(repository),
                    "VERSION": version,
                    "CHANNEL": "beta",
                    "DRAFT_MODE": "replace",
                }
            )

            archive_result = run(
                [str(REDRAFT_GIT), "archive"],
                cwd=repository,
                env=env,
                check=False,
            )
            self.assertEqual(archive_result.returncode, 0, archive_result.stderr)
            backup = replacement / "backup"
            self.assertTrue((backup / "worktree").is_dir())
            self.assertTrue((backup / "state/release.env").is_file())
            self.assertTrue((backup / "artifacts/old.zip").is_file())
            self.assertTrue((replacement / "local-archived.complete").is_file())
            self.assertTrue(state.is_dir())
            self.assertTrue(artifacts.is_dir())
            self.assertEqual(
                run(["git", "branch", "--show-current"], cwd=repository).stdout.strip(),
                "dev",
            )

            (state / "release.env").write_text("new state\n", encoding="utf-8")
            for marker in ("refs-replaced", "draft-deleted", "new-draft-created"):
                (replacement / f"{marker}.complete").touch()
            run([str(REDRAFT_GIT), "cleanup"], cwd=repository, env=env)

            self.assertFalse(replacement.exists())
            self.assertEqual(
                (state / "release.env").read_text(encoding="utf-8"),
                "new state\n",
            )
            worktrees = run(["git", "worktree", "list"], cwd=repository).stdout
            self.assertNotIn("replacement/backup/worktree", worktrees)
            branches = run(["git", "branch", "--list"], cwd=repository).stdout
            self.assertNotIn("release/replaced-", branches)
            self.assertEqual(
                run(["git", "branch", "--show-current"], cwd=repository).stdout.strip(),
                "dev",
            )

if __name__ == "__main__":
    unittest.main()
