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
            snapshot["pr"], snapshot["threads"], snapshot["checks"]
        )
        return snapshot

    @staticmethod
    def refresh(initial: dict[str, object], current: dict[str, object], **extra: object) -> dict[str, object]:
        return review_snapshot.refresh_snapshot(
            "owner/repo",
            42,
            expected_head=initial["headRefOid"],
            expected_pr_fingerprint=initial["fingerprints"]["pr"],
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
            patch.object(
                review_snapshot,
                "collect_pr_identity",
                return_value=pr_identity(),
            ),
        ):
            with self.assertRaisesRegex(
                review_snapshot.SnapshotError, "checks do not match"
            ):
                review_snapshot.collect_snapshot("owner/repo", 42)

    def test_collect_accepts_github_repository_case_variation_and_preserves_raw_values(self) -> None:
        initial = pr_payload()
        initial["url"] = "https://github.com/IfTechIO/Scoco/pull/42"
        threads = thread_payload()
        threads["url"] = "https://github.com/iftechio/SCOCO/pull/42"
        final = pr_identity(url="https://github.com/IFTECHIO/scoco/pull/42")
        with (
            patch.object(review_snapshot, "collect_pr", return_value=initial),
            patch.object(review_snapshot.review_context, "collect", return_value={"issues": []}),
            patch.object(review_snapshot.review_threads, "collect", return_value=threads),
            patch.object(review_snapshot, "collect_checks", return_value=check_payload()),
            patch.object(review_snapshot, "collect_pr_identity", return_value=final),
        ):
            snapshot = review_snapshot.collect_snapshot("iftechio/SCOCO", 42)

        self.assertEqual(snapshot["repo"], "iftechio/SCOCO")
        self.assertEqual(snapshot["pr"]["url"], initial["url"])
        self.assertEqual(snapshot["threads"]["url"], threads["url"])

    def test_collected_mixed_case_snapshot_is_reused_by_metadata_cli(self) -> None:
        head = "a" * 40
        initial = pr_payload(head=head)
        initial["url"] = "https://github.com/IfTechIO/Scoco/pull/42"
        initial["headRepository"] = {"name": "Scoco"}
        initial["headRepositoryOwner"] = {"login": "contributor"}
        threads = thread_payload(head=head)
        threads["url"] = "https://github.com/iftechio/SCOCO/pull/42"
        final = pr_identity(
            url="https://github.com/IFTECHIO/scoco/pull/42",
            head=head,
        )
        with (
            patch.object(review_snapshot, "collect_pr", return_value=initial),
            patch.object(review_snapshot.review_context, "collect", return_value={"issues": []}),
            patch.object(review_snapshot.review_threads, "collect", return_value=threads),
            patch.object(review_snapshot, "collect_checks", return_value=check_payload(head=head)),
            patch.object(review_snapshot, "collect_pr_identity", return_value=final),
        ):
            snapshot = review_snapshot.collect_snapshot("iftechio/SCOCO", 42)

        with tempfile.TemporaryDirectory() as directory:
            saved_path = Path(directory) / "snapshot.json"
            storage_hash = review_snapshot.snapshot_transport.save(
                saved_path,
                snapshot,
                {"mode": "full"},
            )
            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT_PATH.parent / "prepare_pr_metadata.py"),
                    "--snapshot-file",
                    str(saved_path),
                    "--storage-sha256",
                    storage_hash,
                    "--repo",
                    "IFTECHIO/scoco",
                    "--pr",
                    "42",
                ],
                check=False,
                capture_output=True,
                text=True,
            )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            result.stdout.rstrip("\n").split("\t")[-1],
            initial["url"],
        )

    def test_collect_keeps_head_and_base_comparisons_case_sensitive(self) -> None:
        for field, final in (
            ("head", pr_identity(head="HEAD-1")),
            ("base", pr_identity(base_name="MAIN")),
        ):
            with self.subTest(field=field):
                with (
                    patch.object(review_snapshot, "collect_pr", return_value=pr_payload()),
                    patch.object(review_snapshot.review_context, "collect", return_value={"issues": []}),
                    patch.object(review_snapshot.review_threads, "collect", return_value=thread_payload()),
                    patch.object(review_snapshot, "collect_checks", return_value=check_payload()),
                    patch.object(review_snapshot, "collect_pr_identity", return_value=final),
                ):
                    with self.assertRaisesRegex(review_snapshot.SnapshotError, "identity changed"):
                        review_snapshot.collect_snapshot("owner/repo", 42)

    def test_collect_pr_identity_rejects_non_github_url_or_wrong_number(self) -> None:
        for name, url in (
            ("non-GitHub host", "https://example.test/owner/repo/pull/42"),
            ("non-HTTPS URL", "http://github.com/owner/repo/pull/42"),
            ("wrong PR number", "https://github.com/owner/repo/pull/43"),
        ):
            with self.subTest(url=name):
                with patch.object(
                    review_snapshot,
                    "run_json",
                    return_value=(pr_identity(url=url), 0),
                ):
                    with self.assertRaisesRegex(review_snapshot.SnapshotError, "URL"):
                        review_snapshot.collect_pr_identity("owner/repo", 42)

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

    def test_collect_pr_identity_rejects_each_missing_final_field(self) -> None:
        for field in review_snapshot.IDENTITY_FIELDS:
            with self.subTest(field=field):
                incomplete = pr_identity()
                del incomplete[field]
                with patch.object(review_snapshot, "run_json", return_value=(incomplete, 0)):
                    message = "number does not match" if field == "number" else f"missing {field}"
                    with self.assertRaisesRegex(review_snapshot.SnapshotError, message):
                        review_snapshot.collect_pr_identity("owner/repo", 42)

    def test_final_identity_read_failure_emits_no_stdout_or_snapshot_file(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output_path = Path(directory) / "must-not-exist.json"
            output = io.StringIO()
            error = io.StringIO()
            arguments = [
                "review_snapshot.py", "collect", "--repo", "owner/repo", "--pr", "42",
                "--snapshot-out", str(output_path),
            ]
            with (
                patch.object(review_snapshot, "collect_pr", return_value=pr_payload()),
                patch.object(review_snapshot.review_context, "collect", return_value={"issues": []}),
                patch.object(review_snapshot.review_threads, "collect", return_value=thread_payload()),
                patch.object(review_snapshot, "collect_checks", return_value=check_payload()),
                patch.object(
                    review_snapshot, "collect_pr_identity",
                    side_effect=review_snapshot.SnapshotError("final identity read failed"),
                ),
                patch.object(sys, "argv", arguments),
                contextlib.redirect_stdout(output),
                contextlib.redirect_stderr(error),
            ):
                self.assertEqual(review_snapshot.main(), 1)

            self.assertEqual(output.getvalue(), "")
            self.assertIn("final identity read failed", error.getvalue())
            self.assertFalse(output_path.exists())

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
                expected_threads_fingerprint=initial["fingerprints"]["threads"],
                expected_checks_fingerprint=initial["fingerprints"]["checks"],
            )

        self.assertIn("head", refreshed["changed_fields"])
        for section in ("pr", "threads", "checks"):
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

    def test_transport_order_is_ignored_but_reply_order_is_evidence(self) -> None:
        initial = self.collect()
        second_thread = copy.deepcopy(initial["threads"]["threads"][0])
        second_thread["id"] = "thread-2"
        second_thread["comments"][0]["id"] = "comment-2"
        initial["threads"]["threads"].append(second_thread)
        initial["checks"]["items"].append(
            {"bucket": "pass", "link": "https://example.test/other", "name": "lint", "state": "SUCCESS", "workflow": "Validate"}
        )
        self.with_fingerprints(initial)
        reordered = copy.deepcopy(initial)
        reordered["threads"]["threads"].reverse()
        reordered["checks"]["items"].reverse()
        self.with_fingerprints(reordered)

        refreshed = self.refresh(initial, reordered)
        self.assertTrue(refreshed["unchanged"])
        reordered_replies = copy.deepcopy(initial)
        reply = copy.deepcopy(reordered_replies["threads"]["threads"][0]["comments"][0])
        reply["id"] = "comment-later"
        reordered_replies["threads"]["threads"][0]["comments"].append(reply)
        self.with_fingerprints(reordered_replies)
        ordered_reply_fingerprint = reordered_replies["fingerprints"]["threads"]
        reordered_replies["threads"]["threads"][0]["comments"].reverse()
        self.with_fingerprints(reordered_replies)
        self.assertNotEqual(
            ordered_reply_fingerprint,
            reordered_replies["fingerprints"]["threads"],
        )

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

    def test_thread_delta_reports_removal_and_resolution(self) -> None:
        initial = self.collect()
        removed = copy.deepcopy(initial["threads"]["threads"][0])
        removed["id"] = "thread-removed"
        removed["isResolved"] = True
        initial["threads"]["threads"].append(removed)
        self.with_fingerprints(initial)
        current = copy.deepcopy(initial)
        current["threads"]["threads"] = current["threads"]["threads"][:1]
        current["threads"]["threads"][0]["isResolved"] = True
        self.with_fingerprints(current)

        refreshed = self.refresh(initial, current, previous_snapshot=copy.deepcopy(initial))

        self.assertEqual(refreshed["threads_delta"]["removed_ids"], ["thread-removed"])
        self.assertTrue(refreshed["threads_delta"]["changed"][0]["isResolved"])

    def test_thread_delta_reports_reopen(self) -> None:
        initial = self.collect()
        initial["threads"]["threads"][0]["isResolved"] = True
        self.with_fingerprints(initial)
        current = copy.deepcopy(initial)
        current["threads"]["threads"][0]["isResolved"] = False
        self.with_fingerprints(current)

        refreshed = self.refresh(initial, current, previous_snapshot=copy.deepcopy(initial))

        changed = refreshed["threads_delta"]["changed"]
        self.assertEqual([item["id"] for item in changed], ["thread-1"])
        self.assertFalse(changed[0]["isResolved"])

    def test_tampered_previous_snapshot_resets_to_full_evidence(self) -> None:
        initial = self.collect()
        tampered = copy.deepcopy(initial)
        tampered["threads"]["threads"][0]["comments"][0]["body"] = "forged"

        refreshed = self.refresh(initial, copy.deepcopy(initial), previous_snapshot=tampered)

        self.assertIn("evidence_reset", refreshed)
        for section in ("pr", "threads", "checks"):
            self.assertIn(section, refreshed)

    def test_refresh_cli_recollects_full_evidence_when_previous_file_is_corrupt(self) -> None:
        current = self.collect()
        with tempfile.TemporaryDirectory() as directory:
            corrupted = Path(directory) / "previous.json"
            corrupted.write_text("not a snapshot", encoding="utf-8")
            output = io.StringIO()
            arguments = [
                "review_snapshot.py", "refresh", "--repo", "owner/repo", "--pr", "42",
                "--expected-head", "head-1",
                "--expected-pr-fingerprint", current["fingerprints"]["pr"],
                "--expected-threads-fingerprint", current["fingerprints"]["threads"],
                "--expected-checks-fingerprint", current["fingerprints"]["checks"],
                "--previous-snapshot", str(corrupted),
                "--previous-storage-sha256", "0" * 64,
            ]
            with patch.object(review_snapshot, "collect_snapshot", return_value=current) as collect_snapshot, patch.object(sys, "argv", arguments), contextlib.redirect_stdout(output):
                self.assertEqual(review_snapshot.main(), 0)

        result = json.loads(output.getvalue())
        collect_snapshot.assert_called_once_with("owner/repo", 42)
        self.assertIn("evidence_reset", result)
        self.assertIn("threads", result)

    def test_page_cli_reads_only_saved_local_evidence(self) -> None:
        current = self.collect()
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "saved.json"
            storage_hash = review_snapshot.snapshot_transport.save(path, current, current)
            output = io.StringIO()
            with patch.object(review_snapshot, "collect_snapshot", side_effect=AssertionError("page must not read remote state")), patch.object(
                sys,
                "argv",
                [
                    "review_snapshot.py", "page", "--snapshot-file", str(path),
                    "--expected-storage-sha256", storage_hash, "--chars", "1",
                ],
            ), contextlib.redirect_stdout(output):
                self.assertEqual(review_snapshot.main(), 0)

        result = json.loads(output.getvalue())
        self.assertEqual(result["transport"], "paged")
        self.assertEqual(result["page"]["offset"], 0)

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

    @staticmethod
    def with_issue(snapshot):
        context = snapshot["pr"]["reviewContext"]
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

    def test_goal_evidence_changes_refresh_pr_without_head_change(self) -> None:
        initial = self.with_issue(self.collect())
        changes = {
            "title": lambda pr: pr.update(title="A narrower goal"),
            "description": lambda pr: pr.update(body="Only preserve selected settings"),
            "issue_body": lambda pr: pr["reviewContext"]["issues"][0]["issue"].update(body="Also persist offline"),
            "issue_reply": lambda pr: pr["reviewContext"]["issues"][0]["comments"]["items"][0].update(body="Include private mode"),
            "unlink": lambda pr: pr["reviewContext"].update(issues=[]),
        }
        for name, change in changes.items():
            with self.subTest(change=name):
                current = copy.deepcopy(initial)
                change(current["pr"])
                self.with_fingerprints(current)
                result = self.refresh(initial, current)
                self.assertFalse(result["unchanged"])
                self.assertEqual(result["changed_fields"], ["pr"])
                self.assertEqual(result["pr"], current["pr"])
                self.assertNotIn("threads", result)
                self.assertEqual(result["headRefOid"], initial["headRefOid"])

    def test_collect_binds_issue_body_to_pr_evidence_without_waiting_for_checks(self) -> None:
        pr = pr_payload()
        pr["closingIssuesReferences"] = [{"url": "https://github.com/other/project/issues/7"}]
        issue = {"__typename": "Issue", "id": "I7", "number": 7,
                 "url": "https://github.com/other/project/issues/7", "title": "Persist settings",
                 "body": "Settings must survive restart", "state": "OPEN", "updatedAt": "same-time",
                 "comments": {"totalCount": 3}}
        with patch.object(review_snapshot, "collect_pr", return_value=pr), patch.object(
            review_snapshot.review_threads, "collect", return_value=thread_payload()
        ), patch.object(review_snapshot, "collect_checks", return_value=check_payload(exit_code=8)), patch.object(
            review_snapshot.review_context, "graphql", return_value={"repository": {"issueOrPullRequest": issue}}
        ) as graphql, patch.object(
            review_snapshot, "collect_pr_identity", return_value=pr_identity()
        ):
            result = review_snapshot.collect_snapshot("owner/repo", 42)
        self.assertEqual(graphql.call_count, 1)
        source = result["pr"]["reviewContext"]["issues"][0]
        self.assertEqual(source["issue"]["body"], issue["body"])
        self.assertEqual(source["relations"], ["closing"])
        self.assertEqual(source["comments"]["status"], "not_requested")
        self.assertEqual(result["summary"]["context"]["coverage"], "bodies_collected")
        self.assertEqual(result["checks"]["exit_code"], 8)
        self.assertNotIn("reviewContext", pr)  # Do not mutate cached input metadata in place.

    def test_context_failure_is_not_an_empty_success(self) -> None:
        initial = self.with_issue(self.collect())
        current = copy.deepcopy(initial)
        current["pr"]["reviewContext"]["issues"][0] = {
            "repo": "owner/repo", "number": 7, "relations": ["closing"],
            "read_status": "permission_denied", "diagnostic": "HTTP 403",
        }
        self.with_fingerprints(current)
        result = self.refresh(initial, current)
        self.assertEqual(result["context_coverage"], "partial")
        self.assertEqual(result["pr"]["reviewContext"]["issues"][0]["read_status"], "permission_denied")

    def test_diagnostic_wording_and_source_order_do_not_invalidate_evidence(self) -> None:
        initial = self.with_issue(self.collect())
        another = copy.deepcopy(initial["pr"]["reviewContext"]["issues"][0])
        another.update(number=8, read_status="read_failed", diagnostic="timeout at 10:00")
        initial["pr"]["reviewContext"]["issues"].append(another)
        initial["pr"]["closingIssuesReferences"] = [{"url": "issue/8"}, {"url": "issue/7"}]
        self.with_fingerprints(initial)
        current = copy.deepcopy(initial)
        current["pr"]["reviewContext"]["issues"].reverse()
        current["pr"]["reviewContext"]["issues"][0]["diagnostic"] = "timeout at 11:00"
        current["pr"]["closingIssuesReferences"].reverse()
        self.with_fingerprints(current)
        result = self.refresh(initial, current)
        self.assertTrue(result["unchanged"])
        self.assertEqual(result["context_coverage"], "partial")

    def test_legacy_snapshot_missing_context_requires_new_evidence(self) -> None:
        current = self.collect()
        legacy = copy.deepcopy(current)
        del legacy["pr"]["reviewContext"]
        self.with_fingerprints(legacy)
        self.assertEqual(review_snapshot.review_context.coverage(legacy["pr"]), "not_collected")
        result = self.refresh(legacy, current, previous_snapshot=legacy)
        self.assertFalse(result["unchanged"])
        self.assertEqual(result["pr"]["reviewContext"]["schema_version"], 1)
        self.assertEqual(result["context_coverage"], "bodies_collected")

    def test_refresh_inherits_sources_only_from_reviewed_previous_snapshot(self) -> None:
        initial = self.with_issue(self.collect())
        initial["pr"]["reviewContext"]["requested_issues"] = ["other/repo#9"]
        self.with_fingerprints(initial)
        arguments = dict(
            expected_head=initial["headRefOid"], expected_pr_fingerprint=initial["fingerprints"]["pr"],
            expected_threads_fingerprint=initial["fingerprints"]["threads"],
            expected_checks_fingerprint=initial["fingerprints"]["checks"],
        )
        with patch.object(review_snapshot, "collect_snapshot", return_value=initial) as collect:
            review_snapshot.refresh_snapshot("owner/repo", 42, previous_snapshot=initial, **arguments)
        collect.assert_called_once_with("owner/repo", 42, issue_refs=["other/repo#9"], discussion_refs=["owner/repo#7"])
        tampered = copy.deepcopy(initial)
        tampered["pr"]["reviewContext"]["requested_issues"] = ["secret/repo#10"]
        with patch.object(review_snapshot, "collect_snapshot", return_value=initial) as collect:
            result = review_snapshot.refresh_snapshot("owner/repo", 42, previous_snapshot=tampered, **arguments)
        collect.assert_called_once_with("owner/repo", 42)
        self.assertIn("evidence_reset", result)

    def test_selected_evidence_survives_paging_and_preparation_transport(self) -> None:
        initial = self.with_issue(self.collect())
        with tempfile.TemporaryDirectory() as directory:
            path = str(Path(directory) / "context.json")
            storage_hash = review_snapshot.snapshot_transport.save(path, initial, initial)
            saved = review_snapshot.snapshot_transport.read(path, storage_hash)["snapshot"]
            page = review_snapshot.snapshot_transport.page(path, storage_hash, 0, 100000)
        self.assertEqual(saved["pr"]["reviewContext"], initial["pr"]["reviewContext"])
        self.assertEqual(json.loads(page["page"]["text"])["pr"]["reviewContext"], initial["pr"]["reviewContext"])

    def test_cli_passes_explicit_goal_and_discussion_sources(self) -> None:
        current = self.collect()
        argv = ["review_snapshot.py", "collect", "--repo", "owner/repo", "--pr", "42",
                "--issue", "other/repo#9", "--issue-comments", "#7"]
        with patch.object(sys, "argv", argv), patch.object(review_snapshot, "collect_snapshot", return_value=current) as collect, contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(review_snapshot.main(), 0)
        collect.assert_called_once_with("owner/repo", 42, issue_refs=["other/repo#9"], discussion_refs=["#7"])


if __name__ == "__main__":
    unittest.main()
