from __future__ import annotations

import hashlib
import importlib.util
import os
from pathlib import Path
import stat
import tempfile
import unittest


SKILL_ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = SKILL_ROOT / "scripts" / "snapshot_transport.py"
SPEC = importlib.util.spec_from_file_location("snapshot_transport_under_test", SCRIPT_PATH)
assert SPEC is not None and SPEC.loader is not None
snapshot_transport = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(snapshot_transport)


def snapshot() -> dict[str, object]:
    return {
        "schema_version": 1,
        "repo": "owner/repo",
        "number": 42,
        "headRefOid": "head-1",
        "pr": {"baseRefName": "main", "baseRefOid": "base-1"},
        "fingerprints": {"pr": "p", "threads": "t", "checks": "c"},
        "summary": {"threads": {"open": 1}, "checks": {"total": 1}},
        "threads": {"threads": [{"id": "thread-1", "comments": [{"body": "完整证据"}]}]},
    }


def report() -> dict[str, object]:
    return {
        "schema_version": 1,
        "mode": "refresh",
        "threads_delta": {"changed": [{"id": "thread-1", "body": "你好🙂"}]},
    }


class SnapshotTransportTests(unittest.TestCase):
    def test_utf8_pages_reconstruct_exact_report_with_continuous_coverage(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "evidence.json"
            expected_storage_hash = snapshot_transport.save(path, snapshot(), report())
            expected_report = snapshot_transport.encode(report()).decode("utf-8")
            expected_report_hash = hashlib.sha256(snapshot_transport.encode(report())).hexdigest()
            pieces: list[str] = []
            offset = 0
            while True:
                current = snapshot_transport.page(path, expected_storage_hash, offset, 3)
                page = current["page"]
                self.assertEqual(page["offset"], offset)
                self.assertEqual(page["sha256"], expected_report_hash)
                self.assertEqual(page["total_chars"], len(expected_report))
                self.assertEqual(page["total_bytes"], len(expected_report.encode("utf-8")))
                pieces.append(page["text"])
                if page["next_offset"] is None:
                    self.assertEqual(page["end"], len(expected_report))
                    break
                self.assertGreater(page["next_offset"], offset)
                offset = page["next_offset"]

            self.assertEqual("".join(pieces), expected_report)
            self.assertTrue(snapshot_transport.page(path, expected_storage_hash, 0, len(expected_report))["page"]["complete"])
            self.assertEqual(stat.S_IMODE(path.stat().st_mode) & 0o077, 0)

    def test_tampered_storage_and_invalid_page_bounds_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "evidence.json"
            storage_hash = snapshot_transport.save(path, snapshot(), report())
            with self.assertRaisesRegex(ValueError, "offset"):
                snapshot_transport.page(path, storage_hash, -1, 1)
            with self.assertRaisesRegex(ValueError, "offset"):
                snapshot_transport.page(path, storage_hash, 0, 0)

            path.write_bytes(b'{"tampered":true}')
            with self.assertRaisesRegex(ValueError, "hash changed"):
                snapshot_transport.read(path, storage_hash)

    def test_save_never_replaces_existing_file_or_symlink(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            existing = root / "existing.json"
            existing.write_text("keep", encoding="utf-8")
            with self.assertRaises(FileExistsError):
                snapshot_transport.save(existing, snapshot(), report())
            self.assertEqual(existing.read_text(encoding="utf-8"), "keep")

            target = root / "target.json"
            target.write_text("target content", encoding="utf-8")
            link = root / "evidence-link.json"
            os.symlink(target, link)
            with self.assertRaises(FileExistsError):
                snapshot_transport.save(link, snapshot(), report())
            self.assertEqual(target.read_text(encoding="utf-8"), "target content")


if __name__ == "__main__":
    unittest.main()
