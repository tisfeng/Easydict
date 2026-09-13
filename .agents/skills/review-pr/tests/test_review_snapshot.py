from __future__ import annotations

import contextlib
import copy
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import threading
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


def pr_identity(*, number: int = 42, url: str = "https://github.com/owner/repo/pull/42",
                head: str = "head-1", base_name: str = "main", base: str = "base-1") -> dict[str, object]:
    return {
        "number": number,
        "url": url,
        "headRefOid": head,
        "baseRefName": base_name,
        "baseRefOid": base,
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
            patch.object(
                review_snapshot,
                "collect_pr_identity",
                return_value=pr_identity(),
            ),
        ):
            return review_snapshot.collect_snapshot("owner/repo", 42)

    @staticmethod
    def with_fingerprints(snapshot: dict[str, object]) -> dict[str, object]:
        snapshot["fingerprints"] = review_snapshot.section_fingerprints(
            snapshot["pr"], snapshot["context"], snapshot["threads"], snapshot["checks"]
        )
        return snapshot

    @staticmethod
    def refresh(initial: dict[str, object], current: dict[str, object], **extra: object) -> dict[str, object]:
        return review_snapshot.refresh_snapshot(
            "owner/repo",
            42,
            expected_head=initial["headRefOid"],
            expected_pr_fingerprint=initial["fingerprints"]["pr"],
            expected_context_fingerprint=initial["fingerprints"]["context"],
            expected_threads_fingerprint=initial["fingerprints"]["threads"],
            expected_checks_fingerprint=initial["fingerprints"]["checks"],
            current_snapshot=current,
            **extra,
        )

    def test_collect_returns_complete_evidence_and_stable_fingerprints(self) -> None:
        first = self.collect()
        second = self.collect()

        self.assertEqual(first["schema_version"], 1)
        self.assertEqual(first["mode"], "collect")
        self.assertEqual(first["headRefOid"], "head-1")
        self.assertEqual(set(first["fingerprints"]), set(review_snapshot.SECTIONS))
        self.assertEqual(set(first["fingerprints"]), {"pr", "context", "threads", "checks"})
        self.assertNotIn("reviewContext", first["pr"])
        self.assertEqual(first["context"], second["context"])
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

    def test_collect_rechecks_full_identity_after_all_parallel_collectors_finish(self) -> None:
        """The closing identity read must happen after, rather than alongside, collectors."""

        checks_finished = threading.Event()
        context_finished = threading.Event()
        threads_finished = threading.Event()
        final_read = threading.Event()

        def collect_checks(*_arguments: object) -> dict[str, object]:
            checks_finished.set()
            return check_payload()

        def collect_context(*_arguments: object) -> dict[str, object]:
            self.assertTrue(checks_finished.wait(timeout=5), "checks did not finish")
            context_finished.set()
            return {"issues": [], "requested_issues": [], "discussion_issues": []}

        def collect_threads(*_arguments: object) -> dict[str, object]:
            self.assertTrue(checks_finished.wait(timeout=5), "checks did not finish")
            threads_finished.set()
            return thread_payload()

        def collect_identity(*_arguments: object) -> dict[str, object]:
            self.assertTrue(checks_finished.is_set())
            self.assertTrue(context_finished.is_set())
            self.assertTrue(threads_finished.is_set())
            final_read.set()
            return pr_identity()

        with (
            patch.object(review_snapshot, "collect_pr", return_value=pr_payload()),
            patch.object(review_snapshot.review_context, "collect", side_effect=collect_context),
            patch.object(review_snapshot.review_threads, "collect", side_effect=collect_threads),
            patch.object(review_snapshot, "collect_checks", side_effect=collect_checks),
            patch.object(review_snapshot, "collect_pr_identity", side_effect=collect_identity),
        ):
            snapshot = review_snapshot.collect_snapshot("owner/repo", 42)

        self.assertTrue(final_read.is_set())
        self.assertEqual(snapshot["headRefOid"], "head-1")

    def test_collect_rejects_final_identity_drift_or_missing_evidence(self) -> None:
        for name, final_identity, message in (
            ("number", pr_identity(number=43), "identity changed"),
            ("url", pr_identity(url="https://github.com/owner/repo/pull/43"), "identity changed"),
            ("head", pr_identity(head="head-2"), "identity changed"),
            ("base name", pr_identity(base_name="release/1.0"), "identity changed"),
            ("base SHA", pr_identity(base="base-2"), "identity changed"),
        ):
            with self.subTest(field=name):
                with (
                    patch.object(review_snapshot, "collect_pr", return_value=pr_payload()),
                    patch.object(review_snapshot.review_context, "collect", return_value={"issues": []}),
                    patch.object(review_snapshot.review_threads, "collect", return_value=thread_payload()),
                    patch.object(review_snapshot, "collect_checks", return_value=check_payload()),
                    patch.object(review_snapshot, "collect_pr_identity", return_value=final_identity),
                ):
                    with self.assertRaisesRegex(review_snapshot.SnapshotError, message):
                        review_snapshot.collect_snapshot("owner/repo", 42)

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
                expected_context_fingerprint=initial["fingerprints"]["context"],
                expected_threads_fingerprint=initial["fingerprints"]["threads"],
                expected_checks_fingerprint=initial["fingerprints"]["checks"],
            )

        self.assertFalse(refreshed["unchanged"])
        self.assertEqual(refreshed["changed_fields"], ["checks"])
        self.assertIn("checks", refreshed)
        self.assertNotIn("pr", refreshed)
        self.assertNotIn("context", refreshed)
        self.assertNotIn("threads", refreshed)

    def test_head_change_expands_all_current_evidence(self) -> None:
        initial = self.collect()
        current = self.collect()
        current["headRefOid"] = "head-2"
        current["pr"]["headRefOid"] = "head-2"
        current["threads"]["headRefOid"] = "head-2"
        current["checks"]["headRefOid"] = "head-2"
        self.with_fingerprints(current)

        with patch.object(review_snapshot, "collect_snapshot", return_value=current):
            refreshed = review_snapshot.refresh_snapshot(
                "owner/repo",
                42,
                expected_head=initial["headRefOid"],
                expected_pr_fingerprint=initial["fingerprints"]["pr"],
                expected_context_fingerprint=initial["fingerprints"]["context"],
                expected_threads_fingerprint=initial["fingerprints"]["threads"],
                expected_checks_fingerprint=initial["fingerprints"]["checks"],
            )

        self.assertIn("head", refreshed["changed_fields"])
        for section in review_snapshot.SECTIONS:
            self.assertIn(section, refreshed)

    def test_base_only_refresh_requires_complete_expected_pair_and_marks_base(self) -> None:
        initial = self.collect()
        current = copy.deepcopy(initial)
        current["pr"]["baseRefName"] = "release/1.0"
        current["pr"]["baseRefOid"] = "base-2"
        current["baseRefName"] = "release/1.0"
        current["baseRefOid"] = "base-2"
        self.with_fingerprints(current)

        refreshed = self.refresh(
            initial,
            current,
            expected_base_name="main",
            expected_base_sha="base-1",
        )

        self.assertIn("base", refreshed["changed_fields"])
        self.assertIn("pr", refreshed["changed_fields"])
        self.assertEqual(refreshed["base_comparison"], "checked")
        self.assertEqual(refreshed["pr"]["baseRefOid"], "base-2")
        with self.assertRaisesRegex(review_snapshot.SnapshotError, "provided together"):
            self.refresh(initial, current, expected_base_name="main")

    def test_valid_previous_snapshot_returns_complete_thread_deltas(self) -> None:
        initial = self.collect()
        current = copy.deepcopy(initial)
        existing = current["threads"]["threads"][0]
        existing["comments"].append(copy.deepcopy(existing["comments"][0]))
        existing["comments"][-1]["id"] = "comment-reply"
        existing["comments"][-1]["body"] = "A later reply"
        existing["isResolved"] = True
        existing["isOutdated"] = True
        added = copy.deepcopy(existing)
        added["id"] = "thread-new"
        added["isResolved"] = False
        added["comments"][0]["id"] = "comment-new"
        current["threads"]["threads"].append(added)
        self.with_fingerprints(current)

        refreshed = self.refresh(initial, current, previous_snapshot=copy.deepcopy(initial))

        self.assertNotIn("threads", refreshed)
        delta = refreshed["threads_delta"]
        self.assertEqual(delta["removed_ids"], [])
        self.assertEqual([item["id"] for item in delta["changed"]], ["thread-1", "thread-new"])
        self.assertEqual(delta["changed"][0]["comments"][-1]["body"], "A later reply")
        self.assertTrue(delta["changed"][0]["isResolved"])
        self.assertTrue(delta["changed"][0]["isOutdated"])
        self.assertEqual([item["id"] for item in delta["index"]], ["thread-1", "thread-new"])

    def test_tampered_previous_snapshot_resets_to_full_evidence(self) -> None:
        initial = self.collect()
        tampered = copy.deepcopy(initial)
        tampered["threads"]["threads"][0]["comments"][0]["body"] = "forged"

        refreshed = self.refresh(initial, copy.deepcopy(initial), previous_snapshot=tampered)

        self.assertIn("evidence_reset", refreshed)
        for section in review_snapshot.SECTIONS:
            self.assertIn(section, refreshed)

    def test_refresh_snapshot_out_persists_full_current_evidence_not_delta(self) -> None:
        initial = self.collect()
        current = copy.deepcopy(initial)
        current_thread = current["threads"]["threads"][0]
        current_thread["comments"].append(copy.deepcopy(current_thread["comments"][0]))
        current_thread["comments"][-1]["id"] = "comment-new-reply"
        current_thread["comments"][-1]["body"] = "new reply"
        self.with_fingerprints(current)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            previous_path = root / "previous.json"
            previous_hash = review_snapshot.snapshot_transport.save(previous_path, initial, initial)
            output_path = root / "current.json"
            output = io.StringIO()
            arguments = [
                "review_snapshot.py", "refresh", "--repo", "owner/repo", "--pr", "42",
                "--expected-head", "head-1",
                "--expected-pr-fingerprint", initial["fingerprints"]["pr"],
                "--expected-context-fingerprint", initial["fingerprints"]["context"],
                "--expected-threads-fingerprint", initial["fingerprints"]["threads"],
                "--expected-checks-fingerprint", initial["fingerprints"]["checks"],
                "--expected-base-name", "main", "--expected-base-sha", "base-1",
                "--previous-snapshot", str(previous_path),
                "--previous-storage-sha256", previous_hash,
                "--snapshot-out", str(output_path), "--page-chars", "5",
            ]
            with patch.object(review_snapshot, "collect_snapshot", return_value=current) as collect_snapshot, patch.object(sys, "argv", arguments), contextlib.redirect_stdout(output):
                self.assertEqual(review_snapshot.main(), 0)

            first_page = json.loads(output.getvalue())
            stored = review_snapshot.snapshot_transport.read(output_path, first_page["storage_sha256"])

        collect_snapshot.assert_called_once_with("owner/repo", 42)
        self.assertEqual(stored["snapshot"]["threads"], current["threads"])
        self.assertIn("threads_delta", stored["report"])
        self.assertNotIn("threads", stored["report"])

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

    @staticmethod
    def with_issue(snapshot):
        context = snapshot["context"]
        context["issues"] = [{
            "repo": "owner/repo", "number": 7, "url": "https://github.com/owner/repo/issues/7",
            "relations": ["closing"], "read_status": "read",
            "issue": {"id": "I7", "number": 7, "url": "https://github.com/owner/repo/issues/7",
                      "title": "Persist settings", "body": "Settings must survive restart",
                      "state": "OPEN", "updatedAt": "same-time"},
            "comments": {"status": "complete", "totalCount": 1,
                         "items": [{"id": "C7", "body": "Apply to all settings", "updatedAt": "same-time"}]},
        }]
        context["discussion_issues"] = ["owner/repo#7"]
        return ReviewSnapshotTests.with_fingerprints(snapshot)

    def test_requirement_change_does_not_resend_pr_evidence(self) -> None:
        initial = self.with_issue(self.collect())
        current = copy.deepcopy(initial)
        current["context"]["issues"][0]["issue"]["body"] = "Also persist offline"
        current["context"]["issues"][0]["comments"]["items"][0]["body"] = "Include private mode"
        self.with_fingerprints(current)

        refreshed = self.refresh(initial, current, previous_snapshot=copy.deepcopy(initial))

        self.assertEqual(refreshed["changed_fields"], ["context"])
        self.assertNotIn("pr", refreshed)
        self.assertNotIn("context", refreshed)
        self.assertNotIn("checks", refreshed)
        delta = refreshed["context_delta"]
        self.assertEqual(delta["removed_ids"], [])
        self.assertEqual(
            [f"{item['repo']}#{item['number']}" for item in delta["changed"]],
            ["owner/repo#7"],
        )
        self.assertEqual(delta["changed"][0]["issue"]["body"], "Also persist offline")
        self.assertEqual(
            delta["changed"][0]["comments"]["items"][0]["body"], "Include private mode"
        )
        self.assertEqual(delta["coverage"], "bodies_collected")
        self.assertEqual(delta["discussion_issues"], ["owner/repo#7"])
        self.assertEqual([item["id"] for item in delta["index"]], ["owner/repo#7"])

    def test_context_failure_is_not_an_empty_success(self) -> None:
        initial = self.with_issue(self.collect())
        current = copy.deepcopy(initial)
        current["context"]["issues"][0] = {
            "repo": "owner/repo", "number": 7, "relations": ["closing"],
            "read_status": "permission_denied", "diagnostic": "HTTP 403",
        }
        self.with_fingerprints(current)
        result = self.refresh(initial, current)
        self.assertEqual(result["context_coverage"], "partial")
        self.assertEqual(result["context"]["issues"][0]["read_status"], "permission_denied")

    def test_refresh_inherits_sources_only_from_reviewed_previous_snapshot(self) -> None:
        initial = self.with_issue(self.collect())
        initial["context"]["requested_issues"] = ["other/repo#9"]
        self.with_fingerprints(initial)
        arguments = dict(
            expected_head=initial["headRefOid"], expected_pr_fingerprint=initial["fingerprints"]["pr"],
            expected_context_fingerprint=initial["fingerprints"]["context"],
            expected_threads_fingerprint=initial["fingerprints"]["threads"],
            expected_checks_fingerprint=initial["fingerprints"]["checks"],
        )
        with patch.object(review_snapshot, "collect_snapshot", return_value=initial) as collect:
            review_snapshot.refresh_snapshot("owner/repo", 42, previous_snapshot=initial, **arguments)
        collect.assert_called_once_with("owner/repo", 42, issue_refs=["other/repo#9"], discussion_refs=["owner/repo#7"])
        tampered = copy.deepcopy(initial)
        tampered["context"]["requested_issues"] = ["secret/repo#10"]
        with patch.object(review_snapshot, "collect_snapshot", return_value=initial) as collect:
            result = review_snapshot.refresh_snapshot("owner/repo", 42, previous_snapshot=tampered, **arguments)
        collect.assert_called_once_with("owner/repo", 42)
        self.assertIn("evidence_reset", result)

if __name__ == "__main__":
    unittest.main()
