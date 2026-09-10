from __future__ import annotations

import importlib.util
from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import patch


SKILL_ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = SKILL_ROOT / "scripts" / "review_snapshot.py"
SPEC = importlib.util.spec_from_file_location("review_snapshot", SCRIPT_PATH)
assert SPEC is not None and SPEC.loader is not None
review_snapshot = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = review_snapshot
SPEC.loader.exec_module(review_snapshot)


def pr_payload(*, head: str = "head-1") -> dict[str, object]:
    return {
        "number": 42,
        "title": "fix(review): preserve exact snapshots",
        "url": "https://github.com/owner/repo/pull/42",
        "body": "Body",
        "baseRefName": "main",
        "baseRefOid": "base-1",
        "headRefName": "fix/review-snapshots",
        "headRefOid": head,
        "headRepository": {"nameWithOwner": "owner/repo"},
        "headRepositoryOwner": {"login": "owner"},
        "isCrossRepository": False,
        "isDraft": False,
        "state": "OPEN",
        "mergeable": "MERGEABLE",
        "mergeStateStatus": "CLEAN",
        "updatedAt": "2026-09-10T00:00:00Z",
        "files": [],
        "commits": [],
        "closingIssuesReferences": [],
        "comments": [],
        "reviews": [],
    }


def thread_payload(*, head: str = "head-1") -> dict[str, object]:
    return {
        "repo": "owner/repo",
        "number": 42,
        "id": "pr-1",
        "url": "https://github.com/owner/repo/pull/42",
        "headRefOid": head,
        "state": "OPEN",
        "threads": [
            {
                "id": "thread-1",
                "isResolved": False,
                "isOutdated": False,
                "viewerCanResolve": True,
                "path": "src/file.py",
                "line": 10,
                "originalLine": 10,
                "comments": [
                    {
                        "id": "comment-1",
                        "databaseId": 1,
                        "url": "https://example.test/comment-1",
                        "body": "Review body",
                        "updatedAt": "2026-09-10T00:00:00Z",
                        "createdAt": "2026-09-10T00:00:00Z",
                        "author": {"login": "reviewer"},
                        "commit": {"oid": head},
                    }
                ],
            }
        ],
    }


def check_payload(*, exit_code: int = 0, head: str = "head-1") -> dict[str, object]:
    return {
        "headRefOid": head,
        "exit_code": exit_code,
        "items": [
            {
                "bucket": "pass",
                "link": "https://example.test/check",
                "name": "validate",
                "state": "SUCCESS",
                "workflow": "Validate",
            }
        ],
    }


class ReviewSnapshotTests(unittest.TestCase):
    def collect(self) -> dict[str, object]:
        with (
            patch.object(review_snapshot, "collect_pr", return_value=pr_payload()),
            patch.object(
                review_snapshot.review_threads,
                "collect",
                return_value=thread_payload(),
            ),
            patch.object(
                review_snapshot,
                "collect_checks",
                return_value=check_payload(),
            ),
        ):
            return review_snapshot.collect_snapshot("owner/repo", 42)

    def test_collect_returns_complete_evidence_and_stable_fingerprints(self) -> None:
        first = self.collect()
        second = self.collect()

        self.assertEqual(first["schema_version"], 1)
        self.assertEqual(first["mode"], "collect")
        self.assertEqual(first["headRefOid"], "head-1")
        self.assertEqual(first["summary"]["threads"]["open"], 1)
        self.assertEqual(first["summary"]["checks"]["buckets"], {"pass": 1})
        self.assertEqual(first["fingerprints"], second["fingerprints"])
        self.assertEqual(
            first["threads"]["threads"][0]["fingerprint"],
            second["threads"]["threads"][0]["fingerprint"],
        )

    def test_collect_rejects_pr_and_thread_head_drift(self) -> None:
        with (
            patch.object(review_snapshot, "collect_pr", return_value=pr_payload()),
            patch.object(
                review_snapshot.review_threads,
                "collect",
                return_value=thread_payload(head="head-2"),
            ),
            patch.object(
                review_snapshot,
                "collect_checks",
                return_value=check_payload(),
            ),
        ):
            with self.assertRaisesRegex(
                review_snapshot.SnapshotError, "head changed"
            ):
                review_snapshot.collect_snapshot("owner/repo", 42)

    def test_collect_rejects_checks_from_another_head(self) -> None:
        with (
            patch.object(review_snapshot, "collect_pr", return_value=pr_payload()),
            patch.object(
                review_snapshot.review_threads,
                "collect",
                return_value=thread_payload(),
            ),
            patch.object(
                review_snapshot,
                "collect_checks",
                return_value=check_payload(head="head-2"),
            ),
        ):
            with self.assertRaisesRegex(
                review_snapshot.SnapshotError, "checks do not match"
            ):
                review_snapshot.collect_snapshot("owner/repo", 42)

    def test_unchanged_refresh_omits_repeated_full_sections(self) -> None:
        current = self.collect()

        with patch.object(review_snapshot, "collect_snapshot", return_value=current):
            refreshed = review_snapshot.refresh_snapshot(
                "owner/repo",
                42,
                expected_head=current["headRefOid"],
                expected_pr_fingerprint=current["fingerprints"]["pr"],
                expected_threads_fingerprint=current["fingerprints"]["threads"],
                expected_checks_fingerprint=current["fingerprints"]["checks"],
            )

        self.assertTrue(refreshed["unchanged"])
        self.assertEqual(refreshed["changed_fields"], [])
        for section in ("pr", "threads", "checks"):
            self.assertNotIn(section, refreshed)

    def test_refresh_expands_only_changed_section_when_head_is_stable(self) -> None:
        initial = self.collect()
        current = dict(initial)
        current["checks"] = check_payload(exit_code=1)
        current["fingerprints"] = dict(initial["fingerprints"])
        current["fingerprints"]["checks"] = review_snapshot.canonical_fingerprint(
            current["checks"]
        )
        current["summary"] = dict(initial["summary"])
        current["summary"]["checks"] = review_snapshot.summarize_checks(
            current["checks"]
        )

        with patch.object(review_snapshot, "collect_snapshot", return_value=current):
            refreshed = review_snapshot.refresh_snapshot(
                "owner/repo",
                42,
                expected_head=initial["headRefOid"],
                expected_pr_fingerprint=initial["fingerprints"]["pr"],
                expected_threads_fingerprint=initial["fingerprints"]["threads"],
                expected_checks_fingerprint=initial["fingerprints"]["checks"],
            )

        self.assertFalse(refreshed["unchanged"])
        self.assertEqual(refreshed["changed_fields"], ["checks"])
        self.assertIn("checks", refreshed)
        self.assertNotIn("pr", refreshed)
        self.assertNotIn("threads", refreshed)

    def test_head_change_expands_all_current_evidence(self) -> None:
        initial = self.collect()
        current = self.collect()
        current["headRefOid"] = "head-2"

        with patch.object(review_snapshot, "collect_snapshot", return_value=current):
            refreshed = review_snapshot.refresh_snapshot(
                "owner/repo",
                42,
                expected_head=initial["headRefOid"],
                expected_pr_fingerprint=initial["fingerprints"]["pr"],
                expected_threads_fingerprint=initial["fingerprints"]["threads"],
                expected_checks_fingerprint=initial["fingerprints"]["checks"],
            )

        self.assertIn("head", refreshed["changed_fields"])
        for section in ("pr", "threads", "checks"):
            self.assertIn(section, refreshed)

    def test_checks_treat_failure_and_pending_exit_codes_as_observed_state(self) -> None:
        for exit_code in (0, 1, 8):
            with self.subTest(exit_code=exit_code):
                head = subprocess.CompletedProcess(
                    ["gh"],
                    0,
                    '{"headRefOid":"head-1"}',
                    "",
                )
                checks = subprocess.CompletedProcess(
                    ["gh"],
                    exit_code,
                    '[{"bucket":"pending","name":"validate"}]',
                    "",
                )
                with patch.object(
                    review_snapshot.subprocess,
                    "run",
                    side_effect=(checks, head),
                ) as run:
                    result = review_snapshot.collect_checks(
                        "owner/repo", 42, "head-1"
                    )

                self.assertEqual(result["headRefOid"], "head-1")
                self.assertEqual(result["exit_code"], exit_code)
                self.assertEqual(result["items"][0]["bucket"], "pending")
                arguments = run.call_args_list[0].args[0]
                self.assertNotIn("--watch", arguments)

    def test_checks_reject_head_change_during_collection(self) -> None:
        checks = subprocess.CompletedProcess(["gh"], 0, "[]", "")
        head_after = subprocess.CompletedProcess(
            ["gh"], 0, '{"headRefOid":"head-2"}', ""
        )
        with patch.object(
            review_snapshot.subprocess,
            "run",
            side_effect=(checks, head_after),
        ):
            with self.assertRaisesRegex(
                review_snapshot.SnapshotError, "head changed while collecting checks"
            ):
                review_snapshot.collect_checks("owner/repo", 42, "head-1")


if __name__ == "__main__":
    unittest.main()
