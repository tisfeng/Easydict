import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[3]
REDRAFT = ROOT / "scripts/release/release-redraft.sh"


def run(command, *, cwd=None, env=None):
    return subprocess.run(
        command,
        cwd=cwd,
        env=env,
        check=True,
        text=True,
        capture_output=True,
    )


class ReleaseRedraftGitHubTests(unittest.TestCase):
    def test_delete_targets_frozen_draft_id_and_is_idempotent(self):
        version = "6.0.0"
        with tempfile.TemporaryDirectory() as directory:
            temporary = Path(directory).resolve()
            repository = temporary / "repository"
            tools = temporary / "tools"
            repository.mkdir()
            tools.mkdir()
            replacement = repository / f".tmp/release/{version}/replacement"
            replacement.mkdir(parents=True)
            old_commit = "1" * 40
            old_tag = "2" * 40
            (replacement / "metadata.env").write_text(
                "\n".join(
                    [
                        f"REPLACEMENT_VERSION={version}",
                        "REPLACEMENT_CHANNEL=beta",
                        "REPLACEMENT_DRAFT_ID=600",
                        "REPLACEMENT_DRAFT_CREATED_AT=2026-08-23T00:00:00Z",
                        "REPLACEMENT_DRAFT_UPDATED_AT=2026-08-23T00:00:00Z",
                        "REPLACEMENT_OLD_BUILD=30",
                        f"REPLACEMENT_OLD_VERSION_COMMIT={old_commit}",
                        f"REPLACEMENT_OLD_TAG_OID={old_tag}",
                        f"REPLACEMENT_OLD_TAG_COMMIT={old_commit}",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )
            (replacement / "refs-replaced.complete").touch()
            draft_state = temporary / "draft.json"
            draft_state.write_text(
                json.dumps(
                    {
                        "id": 600,
                        "tag_name": version,
                        "draft": True,
                        "prerelease": True,
                        "created_at": "2026-08-23T00:00:00Z",
                        "updated_at": "2026-08-23T00:00:00Z",
                    }
                ),
                encoding="utf-8",
            )
            calls = temporary / "calls.log"
            fake_gh = tools / "gh"
            fake_gh.write_text(
                """#!/usr/bin/env python3
import os
from pathlib import Path
import sys

arguments = sys.argv[1:]
state = Path(os.environ["DRAFT_STATE"])
with open(os.environ["GH_CALLS"], "a", encoding="utf-8") as handle:
    handle.write(" ".join(arguments) + "\\n")
if "--method" in arguments and "DELETE" in arguments:
    state.unlink()
elif any("releases/600" in argument for argument in arguments):
    if not state.exists():
        raise SystemExit(1)
    print(state.read_text(encoding="utf-8"))
elif any("releases?per_page=1" in argument for argument in arguments):
    if state.exists():
        print("[" + state.read_text(encoding="utf-8") + "]")
elif any("releases?per_page=100" in argument for argument in arguments):
    if state.exists():
        print("600")
elif arguments[:2] == ["release", "view"]:
    raise SystemExit(1)
else:
    raise SystemExit(f"unexpected gh call: {arguments}")
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
                    "DRAFT_STATE": str(draft_state),
                    "GH_CALLS": str(calls),
                }
            )

            run([str(REDRAFT), "delete-draft"], cwd=repository, env=env)
            run([str(REDRAFT), "delete-draft"], cwd=repository, env=env)
            self.assertFalse(draft_state.exists())
            self.assertTrue((replacement / "draft-deleted.complete").is_file())
            call_lines = calls.read_text(encoding="utf-8").splitlines()
            delete_calls = [line for line in call_lines if "DELETE" in line]
            self.assertEqual(len(delete_calls), 1)
            self.assertIn("releases/600", delete_calls[0])


if __name__ == "__main__":
    unittest.main()
