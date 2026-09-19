from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import unittest


SKILL_ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = SKILL_ROOT / "scripts" / "release_content.py"
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


if __name__ == "__main__":
    unittest.main()
