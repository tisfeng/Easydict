#!/usr/bin/env python3
"""Behavior tests for canonical release notes."""

from __future__ import annotations

import importlib.util
from pathlib import Path
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "release_notes.py"
SPEC = importlib.util.spec_from_file_location("release_notes", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
release_notes = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(release_notes)


class ReleaseNotesTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.directory = Path(self.temporary_directory.name)
        self.notes = self.directory / "2.22.0.md"
        self.notes.write_text(
            "## What's Changed\n\n* Fix Unicode: 简体中文 🎉\n",
            encoding="utf-8",
        )

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def test_validates_and_hashes_terminal_newline_consistently(self) -> None:
        with_newline = release_notes.read_notes(self.notes, "2.22.0")
        digest = release_notes.notes_sha256(with_newline)
        self.notes.write_text(with_newline.rstrip("\n"), encoding="utf-8")
        without_newline = release_notes.read_notes(self.notes, "2.22.0")
        self.assertEqual(release_notes.notes_sha256(without_newline), digest)

    def test_rejects_wrong_filename_crlf_and_front_matter(self) -> None:
        wrong_name = self.directory / "notes.md"
        wrong_name.write_text("notes\n", encoding="utf-8")
        with self.assertRaisesRegex(
            release_notes.ReleaseNotesError, "filename must be"
        ):
            release_notes.read_notes(wrong_name, "2.22.0")

        self.notes.write_bytes(b"notes\r\n")
        with self.assertRaisesRegex(release_notes.ReleaseNotesError, "LF"):
            release_notes.read_notes(self.notes, "2.22.0")

        self.notes.write_text("---\ntitle: notes\n---\n", encoding="utf-8")
        with self.assertRaisesRegex(
            release_notes.ReleaseNotesError, "front matter"
        ):
            release_notes.read_notes(self.notes, "2.22.0")

    def test_snapshot_rejects_manual_drift(self) -> None:
        state = self.directory / "release-notes.json"
        release_notes.atomic_write_json(
            state,
            release_notes.notes_metadata(self.notes, "2.22.0"),
        )
        release_notes.validate_state(self.notes, "2.22.0", state)

        self.notes.write_text("## Edited\n", encoding="utf-8")
        with self.assertRaisesRegex(
            release_notes.ReleaseNotesError, "changed after snapshot"
        ):
            release_notes.validate_state(self.notes, "2.22.0", state)

    def test_verifies_github_body_with_transport_line_endings(self) -> None:
        body = self.notes.read_text(encoding="utf-8").rstrip("\n")
        payload = {
            "tagName": "2.22.0",
            "body": body.replace("\n", "\r\n"),
        }
        digest = release_notes.verify_release(self.notes, "2.22.0", payload)
        self.assertEqual(digest, release_notes.notes_sha256(body))

        payload["body"] += "\r\nextra"
        with self.assertRaisesRegex(
            release_notes.ReleaseNotesError, "differs from canonical"
        ):
            release_notes.verify_release(self.notes, "2.22.0", payload)

    def test_renderer_linkifies_only_text_nodes(self) -> None:
        markdown = """![Image](https://example.com/image.png)

Bare https://example.com/page.

```text
https://example.com/code
```
"""
        rendered = release_notes.render_markdown(markdown)
        self.assertIn('src="https://example.com/image.png"', rendered)
        self.assertNotIn('<a href="https://example.com/image.png"', rendered)
        self.assertIn(
            '<a href="https://example.com/page">https://example.com/page</a>.',
            rendered,
        )
        self.assertNotIn('<a href="https://example.com/code"', rendered)

    def test_renderer_does_not_nest_links(self) -> None:
        rendered = release_notes.render_markdown(
            "[https://example.com](https://example.org)\n"
        )
        self.assertEqual(
            rendered,
            '<p><a href="https://example.org">https://example.com</a></p>',
        )
        self.assertEqual(rendered.count("<a "), 1)

    def test_renderer_keeps_balanced_url_parentheses(self) -> None:
        url = "https://en.wikipedia.org/wiki/Sparkle_(software)"
        rendered = release_notes.render_markdown(f"Read {url}\n")
        self.assertIn(f'<a href="{url}">{url}</a>', rendered)

    def test_renderer_does_not_linkify_raw_excluded_html(self) -> None:
        markdown = """<a href="https://example.com">https://example.org</a>

<code>https://example.com/code</code>

<pre>https://example.com/pre</pre>
"""
        rendered = release_notes.render_markdown(markdown)
        self.assertEqual(rendered.count("<a "), 1)
        self.assertNotIn('<a href="https://example.com/code"', rendered)
        self.assertNotIn('<a href="https://example.com/pre"', rendered)


if __name__ == "__main__":
    unittest.main()
