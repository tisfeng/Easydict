from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SKILL_ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = SKILL_ROOT / "scripts" / "release_content.py"
import sys
sys.path.insert(0, str(SKILL_ROOT / "scripts"))
from release_pr_policy import classify_release_pr  # noqa: E402

SPEC = importlib.util.spec_from_file_location("release_content", SCRIPT_PATH)
assert SPEC is not None and SPEC.loader is not None
release_content = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(release_content)


class ReleaseContentTests(unittest.TestCase):
    def test_capture_keeps_pr_metadata_for_issue_followup(self) -> None:
        fixture = json.loads(
            (Path(__file__).parent / "fixtures" / "release.json").read_text(
                encoding="utf-8"
            )
        )
        captured = release_content.capture_payload(
            "tisfeng/Easydict", "2.22.0", fixture
        )
        self.assertEqual(captured["schema_version"], 2)
        self.assertEqual(
            [entry["pr_number"] for entry in captured["entries"]],
            [1203, 1212],
        )

    def test_accepts_conventional_english_release_title(self) -> None:
        release_content.validate_release_title(
            "2.22.0",
            "2.22.0 ✨ feat: add a global translation toggle",
        )

    def test_rejects_title_with_mismatched_emoji(self) -> None:
        with self.assertRaisesRegex(
            release_content.ReleaseContentError,
            "emoji does not match",
        ):
            release_content.validate_release_title(
                "2.22.0",
                "2.22.0 🐞 feat: add a global translation toggle",
            )

    def test_rejects_non_english_title(self) -> None:
        with self.assertRaisesRegex(
            release_content.ReleaseContentError,
            "concise English",
        ):
            release_content.validate_release_title(
                "2.22.0",
                "2.22.0 ✨ feat: 增加全局翻译开关",
            )

    def test_draft_body_must_equal_canonical_notes(self) -> None:
        notes = "## What's Changed\n\n* Fix one thing\n"
        release = {
            "tagName": "2.22.0",
            "isDraft": True,
            "body": notes.replace("\n", "\r\n").rstrip("\r\n"),
        }
        release_content.validate_draft(release, "2.22.0", notes)

        release["body"] += "\r\n* Different"
        with self.assertRaisesRegex(
            release_content.ReleaseContentError,
            "differs from canonical",
        ):
            release_content.validate_draft(release, "2.22.0", notes)

    def test_release_must_remain_a_draft(self) -> None:
        with self.assertRaisesRegex(
            release_content.ReleaseContentError,
            "expected Draft",
        ):
            release_content.validate_draft(
                {"tagName": "2.22.0", "isDraft": False, "body": "notes"},
                "2.22.0",
                "notes",
            )

    def test_parse_change_entries_accepts_short_markdown_pr_links(self) -> None:
        entries = release_content.parse_change_entries(
            "## What's Changed\n"
            "* fix: restore selection by @author in [#1285](https://github.com/tisfeng/Easydict/pull/1285)\n"
        )
        self.assertEqual(entries[0]["pr_number"], 1285)
        self.assertEqual(
            entries[0]["pr_url"],
            "https://github.com/tisfeng/Easydict/pull/1285",
        )

    def test_parse_change_entries_rejects_mismatched_short_link_label(self) -> None:
        with self.assertRaisesRegex(
            release_content.ReleaseContentError,
            "does not match URL",
        ):
            release_content.parse_change_entries(
                "## What's Changed\n"
                "* fix: restore selection by @author in [#1284](https://github.com/tisfeng/Easydict/pull/1285)\n"
            )

    def test_bot_pr_is_excluded_by_shared_release_policy(self) -> None:
        decision = classify_release_pr(
            {
                "title": "chore(star-history): update generated assets",
                "author": {"login": "app/github-actions", "is_bot": True},
            }
        )
        self.assertEqual(decision["decision"], "ignored")

    def test_human_pr_is_included_by_shared_release_policy(self) -> None:
        decision = classify_release_pr(
            {
                "title": "fix: restore query focus",
                "author": {"login": "tisfeng", "is_bot": False},
            }
        )
        self.assertEqual(decision["decision"], "included")

    def test_validate_pr_policy_rejects_ignored_entries(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            notes = Path(directory) / "2.23.0.md"
            notes.write_text(
                "## What's Changed\n"
                "* chore(star-history): update generated assets by @app/github-actions in "
                "https://github.com/tisfeng/Easydict/pull/1280\n",
                encoding="utf-8",
            )
            args = type(
                "Args",
                (),
                {"repo": "tisfeng/Easydict", "version": "2.23.0", "notes": notes},
            )()
            with (
                patch.object(
                    release_content,
                    "fetch_pr_policy",
                    return_value={
                        "decision": "ignored",
                        "reason": "generated star-history assets by a bot",
                    },
                ),
                self.assertRaisesRegex(
                    release_content.ReleaseContentError,
                    "ignored bot PRs",
                ),
            ):
                release_content.validate_pr_policy_command(args)

    def test_validate_pr_policy_scans_new_contributors_links(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            notes = Path(directory) / "2.23.0.md"
            notes.write_text(
                "## What's Changed\n* Fix one by @author in "
                "https://github.com/tisfeng/Easydict/pull/1201\n\n"
                "## New Contributors\n* @app/github-actions made their first contribution in "
                "https://github.com/tisfeng/Easydict/pull/1280\n",
                encoding="utf-8",
            )
            args = type(
                "Args",
                (),
                {"repo": "tisfeng/Easydict", "version": "2.23.0", "notes": notes},
            )()
            def classify(number: int) -> dict[str, str]:
                return (
                    {"decision": "ignored", "reason": "bot"}
                    if number == 1280
                    else {"decision": "included", "reason": "human"}
                )
            with (
                patch.object(
                    release_content,
                    "fetch_pr_policy",
                    side_effect=lambda _repo, number: classify(number),
                ),
                self.assertRaisesRegex(
                    release_content.ReleaseContentError,
                    "#1280",
                ),
            ):
                release_content.validate_pr_policy_command(args)


if __name__ == "__main__":
    unittest.main()
