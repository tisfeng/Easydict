#!/usr/bin/env python3
"""Behavior tests for public GitHub Release verification contracts."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "release-public.py"
WORKFLOW = ROOT / "scripts" / "asc-workflow.json"
SPARKLE_NS = "http://www.andymatuschak.org/xml-namespaces/sparkle"


def run_script(*arguments: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["python3", str(SCRIPT), *arguments],
        check=False,
        capture_output=True,
        text=True,
    )


def appcast(
    version: str = "2.24.0",
    build: str = "67",
    *,
    channel: str = "beta",
    description: str = "&lt;h2&gt;What's Changed&lt;/h2&gt;",
    length: str = "3",
    signature: str = "sig",
    url: str | None = None,
    extra_element: str = "",
) -> str:
    download_url = url or (
        f"https://github.com/tisfeng/Easydict/releases/download/"
        f"{version}/Easydict.zip"
    )
    channel_element = f"<sparkle:channel>{channel}</sparkle:channel>" if channel else ""
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<rss xmlns:sparkle="{SPARKLE_NS}" version="2.0">
  <channel>
    <title>Easydict</title>
    <item>
      <title>{version}</title>
      <pubDate>Mon, 21 Sep 2026 12:00:00 +0800</pubDate>
      <description>{description}</description>
      {channel_element}
      <sparkle:version>{build}</sparkle:version>
      <sparkle:shortVersionString>{version}</sparkle:shortVersionString>
      <sparkle:fullReleaseNotesLink>https://github.com/tisfeng/Easydict/releases/tag/{version}</sparkle:fullReleaseNotesLink>
      <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
      {extra_element}
      <enclosure url="{download_url}"
        length="{length}" type="application/octet-stream" sparkle:edSignature="{signature}" />
    </item>
  </channel>
</rss>
'''


class ReleasePublicTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.directory = Path(self.temporary_directory.name)

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def write(self, name: str, content: str | bytes) -> Path:
        path = self.directory / name
        if isinstance(content, bytes):
            path.write_bytes(content)
        else:
            path.write_text(content, encoding="utf-8")
        return path

    def test_validate_headers_accepts_final_response_and_range(self) -> None:
        headers = self.write(
            "headers.txt",
            "HTTP/2 302\r\nContent-Length: 0\r\n\r\n"
            "HTTP/2 206\r\nContent-Length: 1\r\n"
            "Content-Type: application/octet-stream\r\n"
            "Content-Range: bytes 0-0/123\r\n\r\n",
        )
        result = run_script(
            "validate-headers",
            "--headers",
            str(headers),
            "--status",
            "206",
            "--length",
            "1",
            "--content-type",
            "application/octet-stream",
            "--range-total",
            "123",
        )
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_validate_headers_rejects_wrong_range_total(self) -> None:
        headers = self.write(
            "headers.txt",
            "HTTP/2 206\r\nContent-Length: 1\r\n"
            "Content-Type: application/octet-stream\r\n"
            "Content-Range: bytes 0-0/999\r\n\r\n",
        )
        result = run_script(
            "validate-headers",
            "--headers",
            str(headers),
            "--status",
            "206",
            "--length",
            "1",
            "--content-type",
            "application/octet-stream",
            "--range-total",
            "123",
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Range Content-Range mismatch", result.stderr)

    def test_validate_assets_requires_size_type_and_digest(self) -> None:
        artifact_dir = self.directory / "artifacts"
        artifact_dir.mkdir()
        files = {
            "Easydict.zip": b"zip",
            "Easydict.dmg": b"dmg",
            "SHA256SUMS.txt": b"checksum\n",
        }
        assets = []
        for name, content in files.items():
            path = artifact_dir / name
            path.write_bytes(content)
            content_type = {
                "Easydict.zip": "application/zip",
                "Easydict.dmg": "application/x-apple-diskimage",
                "SHA256SUMS.txt": "text/plain; charset=utf-8",
            }[name]
            assets.append(
                {
                    "name": name,
                    "state": "uploaded",
                    "size": len(content),
                    "contentType": content_type,
                    "digest": f"sha256:{hashlib.sha256(content).hexdigest()}",
                }
            )
        release = self.write("release.json", json.dumps({"assets": assets}))
        result = run_script(
            "validate-assets",
            "--release-json",
            str(release),
            "--artifact-dir",
            str(artifact_dir),
        )
        self.assertEqual(result.returncode, 0, result.stderr)

        assets[0]["digest"] = "sha256:wrong"
        release.write_text(json.dumps({"assets": assets}), encoding="utf-8")
        rejected = run_script(
            "validate-assets",
            "--release-json",
            str(release),
            "--artifact-dir",
            str(artifact_dir),
        )
        self.assertNotEqual(rejected.returncode, 0)
        self.assertIn("digest mismatch", rejected.stderr)

    def test_validate_assets_rejects_duplicate_asset(self) -> None:
        artifact_dir = self.directory / "artifacts"
        artifact_dir.mkdir()
        for name in ("Easydict.zip", "Easydict.dmg", "SHA256SUMS.txt"):
            (artifact_dir / name).write_bytes(b"x")
        release = self.write(
            "release.json",
            json.dumps(
                {
                    "assets": [
                        {"name": "Easydict.zip", "state": "uploaded", "size": 1,
                         "contentType": "application/zip", "digest": "sha256:" + hashlib.sha256(b"x").hexdigest()},
                        {"name": "Easydict.zip", "state": "uploaded", "size": 1,
                         "contentType": "application/zip", "digest": "sha256:" + hashlib.sha256(b"x").hexdigest()},
                    ]
                }
            ),
        )
        result = run_script(
            "validate-assets",
            "--release-json",
            str(release),
            "--artifact-dir",
            str(artifact_dir),
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("exactly one", result.stderr)

    def test_validate_assets_rejects_non_uploaded_asset(self) -> None:
        artifact_dir = self.directory / "artifacts"
        artifact_dir.mkdir()
        assets = []
        content_types = {
            "Easydict.zip": "application/zip",
            "Easydict.dmg": "application/x-apple-diskimage",
            "SHA256SUMS.txt": "text/plain; charset=utf-8",
        }
        for name, content_type in content_types.items():
            content = name.encode()
            (artifact_dir / name).write_bytes(content)
            assets.append(
                {
                    "name": name,
                    "state": "new" if name == "Easydict.dmg" else "uploaded",
                    "size": len(content),
                    "contentType": content_type,
                    "digest": f"sha256:{hashlib.sha256(content).hexdigest()}",
                }
            )
        release = self.write("release.json", json.dumps({"assets": assets}))
        result = run_script(
            "validate-assets",
            "--release-json",
            str(release),
            "--artifact-dir",
            str(artifact_dir),
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("not uploaded", result.stderr)

    def test_compare_appcast_checks_signature_and_all_target_fields(self) -> None:
        expected = self.write("expected.xml", appcast())
        actual = self.write("actual.xml", appcast())
        result = run_script(
            "compare-appcast",
            "--expected",
            str(expected),
            "--actual",
            str(actual),
            "--version",
            "2.24.0",
            "--build",
            "67",
        )
        self.assertEqual(result.returncode, 0, result.stderr)

        variants = {
            "channel": appcast(channel="stable"),
            "description": appcast(description="different"),
            "length": appcast(length="999"),
            "signature": appcast(signature="different"),
            "url": appcast(url="https://example.com/Easydict.zip"),
            "unexpected element": appcast(
                extra_element="<sparkle:phasedRolloutInterval>86400</sparkle:phasedRolloutInterval>"
            ),
        }
        for field, content in variants.items():
            with self.subTest(field=field):
                actual.write_text(content, encoding="utf-8")
                rejected = run_script(
                    "compare-appcast",
                    "--expected",
                    str(expected),
                    "--actual",
                    str(actual),
                    "--version",
                    "2.24.0",
                    "--build",
                    "67",
                )
                self.assertNotEqual(rejected.returncode, 0)
                self.assertIn("public appcast entry mismatch", rejected.stderr)

    def test_compare_file_rejects_public_checksum_drift(self) -> None:
        expected = self.write("expected.txt", "sha256  Easydict.zip\n")
        actual = self.write("actual.txt", "sha256  other.zip\n")
        result = run_script(
            "compare-file", "--expected", str(expected), "--actual", str(actual)
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("checksum content mismatch", result.stderr)

    def test_workflow_verifies_public_assets_before_pushing_appcast_refs(self) -> None:
        workflow = json.loads(WORKFLOW.read_text(encoding="utf-8"))
        publish = [
            step["name"]
            for step in workflow["workflows"]["publish_steps"]["steps"]
        ]
        self.assertLess(
            publish.index("publish_github_release"),
            publish.index("verify_public_release_assets"),
        )
        self.assertLess(
            publish.index("verify_public_release_assets"),
            publish.index("push_published_refs"),
        )


if __name__ == "__main__":
    unittest.main()
