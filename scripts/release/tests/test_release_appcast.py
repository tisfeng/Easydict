#!/usr/bin/env python3
"""Behavior tests for Easydict Sparkle appcast transitions."""

from __future__ import annotations

from pathlib import Path
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET


SCRIPT = Path(__file__).resolve().parents[1] / "release-appcast.py"
SPARKLE_NS = "http://www.andymatuschak.org/xml-namespaces/sparkle"


def appcast_item(version: str, build: str, channel: str = "") -> str:
    channel_element = (
        f"<sparkle:channel>{channel}</sparkle:channel>" if channel else ""
    )
    return f"""
        <item>
            <title>{version}</title>
            {channel_element}
            <pubDate>Sun, 23 Aug 2026 00:00:00 +0800</pubDate>
            <sparkle:version>{build}</sparkle:version>
            <sparkle:shortVersionString>{version}</sparkle:shortVersionString>
            <sparkle:releaseNotesLink>https://example.com/{version}</sparkle:releaseNotesLink>
            <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
            <enclosure url="https://example.com/{version}/Easydict.zip"
                length="3" type="application/octet-stream"
                sparkle:edSignature="signature" />
        </item>
    """


def appcast_document(*items: str) -> str:
    return f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<rss xmlns:sparkle="{SPARKLE_NS}" version="2.0">
    <channel>
        <title>Easydict</title>
        {''.join(items)}
    </channel>
</rss>
"""


class ReleaseAppcastTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.directory = Path(self.temporary_directory.name)
        self.original = self.directory / "original.xml"
        self.candidate = self.directory / "candidate.xml"
        self.archive = self.directory / "Easydict.zip"
        self.archive.write_bytes(b"zip")
        self.original.write_text(
            appcast_document(
                appcast_item("2.21.0", "63", "beta"),
                appcast_item("2.20.0", "62"),
            ),
            encoding="UTF-8",
        )
        self.candidate.write_text(
            appcast_document(
                appcast_item("2.22.0", "64", "beta"),
                appcast_item("2.21.0", "63", "beta"),
                appcast_item("2.20.0", "62"),
            ),
            encoding="UTF-8",
        )

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def run_script(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(SCRIPT), *arguments],
            check=False,
            capture_output=True,
            text=True,
        )

    def validate(self, previous_beta_version: str = "") -> subprocess.CompletedProcess[str]:
        arguments = [
            "validate",
            "--original",
            str(self.original),
            "--appcast",
            str(self.candidate),
            "--archive",
            str(self.archive),
            "--version",
            "2.22.0",
            "--build",
            "64",
            "--channel",
            "beta",
            "--release-notes-url",
            "https://example.com/2.22.0",
            "--download-url",
            "https://example.com/2.22.0/Easydict.zip",
        ]
        if previous_beta_version:
            arguments.extend(
                ["--previous-beta-version", previous_beta_version]
            )
        return self.run_script(*arguments)

    def test_promotes_only_the_previous_beta_and_is_idempotent(self) -> None:
        initial_validation = self.validate()
        self.assertEqual(
            initial_validation.returncode,
            0,
            initial_validation.stderr,
        )

        result = self.run_script(
            "find-previous-beta",
            "--appcast",
            str(self.candidate),
            "--version",
            "2.22.0",
            "--build",
            "64",
            "--channel",
            "beta",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "2.21.0")

        promote_arguments = [
            "promote-previous-beta",
            "--appcast",
            str(self.candidate),
            "--version",
            "2.22.0",
            "--build",
            "64",
            "--previous-version",
            "2.21.0",
        ]
        first_promotion = self.run_script(*promote_arguments)
        second_promotion = self.run_script(*promote_arguments)
        self.assertEqual(first_promotion.returncode, 0, first_promotion.stderr)
        self.assertEqual(second_promotion.returncode, 0, second_promotion.stderr)

        tree = ET.parse(self.candidate)
        channels = {
            item.find(f"{{{SPARKLE_NS}}}shortVersionString").text:
                item.find(f"{{{SPARKLE_NS}}}channel")
            for item in tree.getroot().findall("./channel/item")
        }
        self.assertEqual(channels["2.22.0"].text, "beta")
        self.assertIsNone(channels["2.21.0"])
        self.assertIsNone(channels["2.20.0"])

        validation = self.validate("2.21.0")
        self.assertEqual(validation.returncode, 0, validation.stderr)
        unapproved_validation = self.validate()
        self.assertNotEqual(unapproved_validation.returncode, 0)
        self.assertIn(
            "unexpected change to old appcast item",
            unapproved_validation.stderr,
        )

        self.original.write_text(
            self.candidate.read_text(encoding="UTF-8"),
            encoding="UTF-8",
        )
        resumed_validation = self.validate("2.21.0")
        self.assertEqual(
            resumed_validation.returncode,
            0,
            resumed_validation.stderr,
        )

    def test_rejects_other_changes_to_old_items(self) -> None:
        promotion = self.run_script(
            "promote-previous-beta",
            "--appcast",
            str(self.candidate),
            "--version",
            "2.22.0",
            "--build",
            "64",
            "--previous-version",
            "2.21.0",
        )
        self.assertEqual(promotion.returncode, 0, promotion.stderr)

        contents = self.candidate.read_text(encoding="UTF-8")
        self.candidate.write_text(
            contents.replace("<title>2.20.0</title>", "<title>changed</title>"),
            encoding="UTF-8",
        )
        validation = self.validate("2.21.0")
        self.assertNotEqual(validation.returncode, 0)
        self.assertIn("unexpected change to old appcast item", validation.stderr)

    def test_stable_release_has_no_beta_predecessor_transition(self) -> None:
        result = self.run_script(
            "find-previous-beta",
            "--appcast",
            str(self.candidate),
            "--version",
            "2.22.0",
            "--build",
            "64",
            "--channel",
            "stable",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "")


if __name__ == "__main__":
    unittest.main()
