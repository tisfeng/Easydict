#!/usr/bin/env python3
"""Focused tests for the post-release canonical notes synchronizer."""

from __future__ import annotations

import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[3]
SCRIPT = ROOT / "scripts/release/release-notes-sync.py"
APPCAST = ROOT / "appcast.xml"


def load_module():
    specification = importlib.util.spec_from_file_location(
        "release_notes_sync", SCRIPT
    )
    assert specification and specification.loader
    module = importlib.util.module_from_spec(specification)
    specification.loader.exec_module(module)
    return module


class ReleaseNotesSyncTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.module = load_module()

    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory()
        self.temporary = Path(self.directory.name)
        self.notes = self.temporary / "2.23.0.md"
        self.notes.write_text(
            "## What's Changed\n\n- A corrected release note\n",
            encoding="UTF-8",
        )
        self.appcast = APPCAST.read_bytes()
        self.rendered = self.module.render_markdown(self.notes.read_text())
        self.release = {
            "id": 123,
            "tag_name": "2.23.0",
            "draft": False,
            "prerelease": True,
            "body": "old body",
            "html_url": "https://github.com/tisfeng/Easydict/releases/tag/2.23.0",
        }
        self.payload = {"sha": "blob-sha"}

    def tearDown(self) -> None:
        self.directory.cleanup()

    def test_candidate_changes_only_target_description(self) -> None:
        candidate, build = self.module.build_appcast_candidate(
            self.appcast, "2.23.0", self.rendered
        )
        self.assertEqual(build, "66")
        original_tree = self.module.parse_appcast(self.appcast)
        candidate_tree = self.module.parse_appcast(candidate)
        original_items = original_tree.getroot().findall("./channel/item")
        candidate_items = candidate_tree.getroot().findall("./channel/item")
        self.assertEqual(len(original_items), len(candidate_items))
        for original, updated in zip(original_items, candidate_items):
            old_description = original.find("description")
            new_description = updated.find("description")
            if (
                original.findtext(
                    "{http://www.andymatuschak.org/xml-namespaces/sparkle}"
                    "shortVersionString"
                )
                == "2.23.0"
            ):
                self.assertEqual(new_description.text, self.rendered)
                if old_description is not None:
                    old_description.text = None
                new_description.text = None
            self.assertEqual(
                ET.tostring(original, encoding="UTF-8"),
                ET.tostring(updated, encoding="UTF-8"),
            )

    def test_preview_does_not_call_writers(self) -> None:
        state = self.temporary / "state.json"
        args = self.module.build_parser().parse_args(
            [
                "2.23.0",
                "--notes-file",
                str(self.notes),
                "--state",
                str(state),
            ]
        )
        with (
            mock.patch.object(
                self.module,
                "validate_notes_checkout",
                return_value=self.notes.parent.resolve(),
            ),
            mock.patch.object(
                self.module,
                "fetch_release",
                return_value=(self.release, '"etag"'),
            ),
            mock.patch.object(
                self.module,
                "fetch_appcast",
                return_value=(self.payload, self.appcast),
            ),
            mock.patch.object(self.module, "update_release_body") as update_release,
            mock.patch.object(self.module, "update_appcast") as update_appcast,
        ):
            with mock.patch("sys.stdout", new=io.StringIO()):
                self.module.sync_notes(args)
        self.assertFalse(update_release.called)
        self.assertFalse(update_appcast.called)
        preview = json.loads(state.read_text(encoding="UTF-8"))["preview"]
        self.assertTrue(preview["release_update_required"])
        self.assertTrue(preview["appcast_update_required"])

    def test_execute_records_failed_stage_for_cas_error(self) -> None:
        state = self.temporary / "state.json"
        args = self.module.build_parser().parse_args(
            [
                "2.23.0",
                "--notes-file",
                str(self.notes),
                "--state",
                str(state),
                "--execute",
            ]
        )
        with (
            mock.patch.object(
                self.module,
                "validate_notes_checkout",
                return_value=self.notes.parent.resolve(),
            ),
            mock.patch.object(
                self.module,
                "fetch_release",
                return_value=(self.release, '"etag"'),
            ),
            mock.patch.object(
                self.module,
                "fetch_appcast",
                return_value=(self.payload, self.appcast),
            ),
            mock.patch.object(
                self.module,
                "update_release_body",
                side_effect=self.module.NotesSyncError(
                    "412 Precondition Failed"
                ),
            ),
        ):
            with self.assertRaises(self.module.NotesSyncError):
                self.module.sync_notes(args)
        saved = json.loads(state.read_text(encoding="UTF-8"))
        self.assertEqual(saved["status"], "failed")
        self.assertEqual(saved["failed_stage"], "release")

    def test_execute_stops_when_appcast_sha_changes_after_preview(self) -> None:
        state = self.temporary / "state.json"
        args = self.module.build_parser().parse_args(
            [
                "2.23.0",
                "--notes-file",
                str(self.notes),
                "--state",
                str(state),
                "--execute",
            ]
        )
        changed_payload = {"sha": "different-blob-sha"}
        with (
            mock.patch.object(
                self.module,
                "validate_notes_checkout",
                return_value=self.notes.parent.resolve(),
            ),
            mock.patch.object(
                self.module,
                "fetch_release",
                return_value=(self.release, '"etag"'),
            ),
            mock.patch.object(
                self.module,
                "fetch_appcast",
                side_effect=[
                    (self.payload, self.appcast),
                    (changed_payload, self.appcast),
                ],
            ),
            mock.patch.object(self.module, "update_release_body"),
        ):
            with self.assertRaises(self.module.NotesSyncError):
                self.module.sync_notes(args)
        saved = json.loads(state.read_text(encoding="UTF-8"))
        self.assertEqual(saved["status"], "failed")
        self.assertEqual(saved["failed_stage"], "appcast")

    def test_execute_is_idempotent_when_both_targets_are_already_equal(self) -> None:
        state = self.temporary / "state.json"
        notes = APPCAST.parent / "changelog" / "2.23.0.md"
        canonical_notes = notes.read_text(encoding="UTF-8")
        release = dict(self.release, body=self.module.normalize_body(canonical_notes))
        args = self.module.build_parser().parse_args(
            [
                "2.23.0",
                "--notes-file",
                str(notes),
                "--state",
                str(state),
                "--execute",
            ]
        )
        payload = {"sha": "blob-sha"}
        with (
            mock.patch.object(
                self.module,
                "validate_notes_checkout",
                return_value=ROOT,
            ),
            mock.patch.object(
                self.module,
                "fetch_release",
                return_value=(release, '"etag"'),
            ),
            mock.patch.object(
                self.module,
                "fetch_appcast",
                return_value=(payload, self.appcast),
            ),
            mock.patch.object(self.module, "update_release_body") as update_release,
            mock.patch.object(self.module, "update_appcast") as update_appcast,
        ):
            with mock.patch("sys.stdout", new=io.StringIO()):
                self.module.sync_notes(args)
        self.assertFalse(update_release.called)
        self.assertFalse(update_appcast.called)
        saved = json.loads(state.read_text(encoding="UTF-8"))
        self.assertEqual(saved["status"], "completed")
        self.assertFalse(saved["release_updated"])
        self.assertFalse(saved["appcast_updated"])


if __name__ == "__main__":
    unittest.main()
