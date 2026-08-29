import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[3]
BRANCH_SYNC = ROOT / "scripts/release/release-branch-sync.sh"
PUBLISH_GIT = ROOT / "scripts/release/release-publish-git.sh"


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


def configure_repository(repository):
    run(["git", "config", "user.name", "Release Test"], cwd=repository)
    run(
        ["git", "config", "user.email", "release@example.com"],
        cwd=repository,
    )
    run(["git", "config", "commit.gpgsign", "false"], cwd=repository)


class ReleaseGitFlowTests(unittest.TestCase):
    def test_draft_is_isolated_and_publish_merges_into_local_dev(self):
        version = "7.8.9"
        with tempfile.TemporaryDirectory() as directory:
            temporary = Path(directory)
            repository = temporary / "repository"
            remote = temporary / "origin.git"
            remote_worker = temporary / "remote-worker"

            run(["git", "init", "--bare", str(remote)])
            run(["git", "init", "-b", "dev", str(repository)])
            configure_repository(repository)
            (repository / ".gitignore").write_text(".tmp/\n", encoding="utf-8")
            (repository / "base.txt").write_text("base\n", encoding="utf-8")
            run(["git", "add", ".gitignore", "base.txt"], cwd=repository)
            run(["git", "commit", "-m", "base"], cwd=repository)
            base_commit = run(
                ["git", "rev-parse", "HEAD"], cwd=repository
            ).stdout.strip()
            run(["git", "branch", "main"], cwd=repository)
            run(["git", "remote", "add", "origin", str(remote)], cwd=repository)
            run(["git", "push", "origin", "dev", "main"], cwd=repository)

            release_dir = repository / f".tmp/release/{version}"
            release_worktree = release_dir / "worktree"
            release_worktree.parent.mkdir(parents=True)
            run(
                [
                    "git",
                    "worktree",
                    "add",
                    "-b",
                    f"release/sync-{version}",
                    str(release_worktree),
                    base_commit,
                ],
                cwd=repository,
            )
            (release_worktree / "release.txt").write_text(
                "version\n", encoding="utf-8"
            )
            run(["git", "add", "release.txt"], cwd=release_worktree)
            run(
                ["git", "commit", "-m", f"build(release): bump {version}"],
                cwd=release_worktree,
            )
            version_commit = run(
                ["git", "rev-parse", "HEAD"], cwd=release_worktree
            ).stdout.strip()

            state = release_dir / "state"
            state.mkdir()
            (state / "release.env").write_text(
                "\n".join(
                    [
                        f"RELEASE_SAVED_VERSION={version}",
                        "RELEASE_SAVED_BUILD=42",
                        "RELEASE_SAVED_CHANNEL=beta",
                        f"RELEASE_VERSION_COMMIT={version_commit}",
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
                    "DRAFT_MODE": "normal",
                }
            )

            run([str(BRANCH_SYNC), "push-version"], cwd=repository, env=env)
            for ref in ("refs/heads/dev", "refs/heads/main"):
                ref_commit = run(
                    ["git", "--git-dir", str(remote), "rev-parse", ref]
                ).stdout.strip()
                self.assertEqual(ref_commit, base_commit)
            draft_commit = run(
                [
                    "git",
                    "--git-dir",
                    str(remote),
                    "rev-parse",
                    f"refs/heads/release/sync-{version}",
                ]
            ).stdout.strip()
            self.assertEqual(draft_commit, version_commit)

            (repository / "local.txt").write_text("local\n", encoding="utf-8")
            run(["git", "add", "local.txt"], cwd=repository)
            run(["git", "commit", "-m", "local dev work"], cwd=repository)
            local_commit = run(
                ["git", "rev-parse", "HEAD"], cwd=repository
            ).stdout.strip()
            run(["git", "switch", "-c", "feature/in-progress"], cwd=repository)
            (repository / "uncommitted.txt").write_text(
                "preserve me\n", encoding="utf-8"
            )
            feature_head = run(
                ["git", "rev-parse", "HEAD"], cwd=repository
            ).stdout.strip()

            run(
                ["git", "clone", "--branch", "dev", str(remote), str(remote_worker)]
            )
            configure_repository(remote_worker)
            (remote_worker / "remote.txt").write_text("remote\n", encoding="utf-8")
            run(["git", "add", "remote.txt"], cwd=remote_worker)
            run(["git", "commit", "-m", "remote dev work"], cwd=remote_worker)
            remote_commit = run(
                ["git", "rev-parse", "HEAD"], cwd=remote_worker
            ).stdout.strip()
            run(["git", "push", "origin", "dev"], cwd=remote_worker)

            run([str(PUBLISH_GIT), "prepare"], cwd=repository, env=env)
            prepared_head = run(
                ["git", "rev-parse", "HEAD"],
                cwd=release_dir / "publish-integration",
            ).stdout.strip()
            for commit in (local_commit, remote_commit, version_commit):
                result = run(
                    ["git", "merge-base", "--is-ancestor", commit, prepared_head],
                    cwd=repository,
                    check=False,
                )
                self.assertEqual(result.returncode, 0)

            (release_worktree / "appcast.xml").write_text(
                "<rss/>\n", encoding="utf-8"
            )
            run(["git", "add", "appcast.xml"], cwd=release_worktree)
            run(
                [
                    "git",
                    "commit",
                    "-m",
                    f"build(release): add {version} appcast entry",
                ],
                cwd=release_worktree,
            )
            appcast_commit = run(
                ["git", "rev-parse", "HEAD"], cwd=release_worktree
            ).stdout.strip()

            run([str(PUBLISH_GIT), "push"], cwd=repository, env=env)
            local_dev = run(
                ["git", "rev-parse", "refs/heads/dev"], cwd=repository
            ).stdout.strip()
            remote_dev = run(
                ["git", "--git-dir", str(remote), "rev-parse", "refs/heads/dev"]
            ).stdout.strip()
            remote_main = run(
                ["git", "--git-dir", str(remote), "rev-parse", "refs/heads/main"]
            ).stdout.strip()
            remote_release = run(
                [
                    "git",
                    "--git-dir",
                    str(remote),
                    "rev-parse",
                    f"refs/heads/release/sync-{version}",
                ]
            ).stdout.strip()
            self.assertEqual(local_dev, remote_dev)
            self.assertEqual(remote_main, appcast_commit)
            self.assertEqual(remote_release, appcast_commit)
            self.assertEqual(
                run(
                    ["git", "branch", "--show-current"], cwd=repository
                ).stdout.strip(),
                "feature/in-progress",
            )
            self.assertEqual(
                run(["git", "rev-parse", "HEAD"], cwd=repository).stdout.strip(),
                feature_head,
            )
            self.assertEqual(
                (repository / "uncommitted.txt").read_text(encoding="utf-8"),
                "preserve me\n",
            )
            for commit in (local_commit, remote_commit, appcast_commit):
                result = run(
                    ["git", "merge-base", "--is-ancestor", commit, local_dev],
                    cwd=repository,
                    check=False,
                )
                self.assertEqual(result.returncode, 0)

            run([str(PUBLISH_GIT), "cleanup"], cwd=repository, env=env)
            run([str(BRANCH_SYNC), "cleanup"], cwd=repository, env=env)
            missing_release = run(
                [
                    "git",
                    "--git-dir",
                    str(remote),
                    "show-ref",
                    "--verify",
                    f"refs/heads/release/sync-{version}",
                ],
                check=False,
            )
            self.assertNotEqual(missing_release.returncode, 0)
            self.assertFalse((release_dir / "publish-integration").exists())
            self.assertFalse(release_worktree.exists())
            self.assertNotIn(
                f"release/sync-{version}",
                run(["git", "branch", "--list"], cwd=repository).stdout,
            )
            self.assertTrue(
                (state / "remote-release-branch-cleaned.complete").is_file()
            )


if __name__ == "__main__":
    unittest.main()
