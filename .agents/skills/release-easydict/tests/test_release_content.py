from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import unittest


SKILL_ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = SKILL_ROOT / "scripts" / "release_content.py"
FIXTURE_PATH = Path(__file__).parent / "fixtures" / "release.json"
SPEC = importlib.util.spec_from_file_location("release_content", SCRIPT_PATH)
assert SPEC is not None and SPEC.loader is not None
release_content = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(release_content)


class ReleaseContentTests(unittest.TestCase):
    def setUp(self) -> None:
        release = json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))
        self.source = release_content.capture_payload(
            "tisfeng/Easydict",
            "2.22.0",
            release,
        )
        self.curated = {
            "schema_version": 1,
            "source_sha256": self.source["source_sha256"],
            "release_title": "2.22.0 ✨ feat: add a global translation toggle",
            "highlight_pr": 1203,
            "entries": [
                {
                    "pr_number": 1203,
                    "title": "feat(shortcut): add a global translation toggle shortcut",
                },
                {
                    "pr_number": 1212,
                    "title": "fix(window): restore input focus after layout changes",
                },
            ],
        }

    def test_capture_extracts_generated_pr_entries(self) -> None:
        self.assertEqual(
            [entry["pr_number"] for entry in self.source["entries"]],
            [1203, 1212],
        )
        self.assertEqual(self.source["entries"][0]["author"], "@bsythegreat")

    def test_render_only_replaces_human_pr_titles(self) -> None:
        rendered = release_content.render_notes(self.source, self.curated)

        self.assertIn(
            "feat(shortcut): add a global translation toggle shortcut "
            "by @bsythegreat in https://github.com/tisfeng/Easydict/pull/1203",
            rendered,
        )
        self.assertIn("## New Contributors", rendered)
        self.assertIn(
            "**Full Changelog**: "
            "https://github.com/tisfeng/Easydict/compare/2.21.0...2.22.0",
            rendered,
        )

    def test_render_rejects_missing_or_extra_pr_entries(self) -> None:
        curated = dict(self.curated)
        curated["entries"] = self.curated["entries"][:1]

        with self.assertRaisesRegex(
            release_content.ReleaseContentError,
            "curated PR set differs",
        ):
            release_content.render_notes(self.source, curated)

    def test_render_rejects_non_english_content(self) -> None:
        curated = dict(self.curated)
        curated["entries"] = [dict(item) for item in self.curated["entries"]]
        curated["entries"][0]["title"] = "feat(shortcut): 增加快捷键"

        with self.assertRaisesRegex(
            release_content.ReleaseContentError,
            "not English",
        ):
            release_content.render_notes(self.source, curated)

    def test_render_rejects_highlight_outside_release(self) -> None:
        curated = dict(self.curated)
        curated["highlight_pr"] = 9999

        with self.assertRaisesRegex(
            release_content.ReleaseContentError,
            "highlight_pr",
        ):
            release_content.render_notes(self.source, curated)

    def test_render_rejects_title_with_mismatched_emoji(self) -> None:
        curated = dict(self.curated)
        curated["release_title"] = (
            "2.22.0 🐞 feat: add a global translation toggle"
        )

        with self.assertRaisesRegex(
            release_content.ReleaseContentError,
            "emoji does not match",
        ):
            release_content.render_notes(self.source, curated)

    def test_render_rejects_tampered_capture(self) -> None:
        source = dict(self.source)
        source["source_body"] = f"{source['source_body']}tampered"

        with self.assertRaisesRegex(
            release_content.ReleaseContentError,
            "integrity check",
        ):
            release_content.render_notes(source, self.curated)


if __name__ == "__main__":
    unittest.main()
