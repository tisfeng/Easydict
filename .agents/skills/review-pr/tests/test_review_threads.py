from __future__ import annotations

import contextlib
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import patch


SKILL_ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = SKILL_ROOT / "scripts" / "review_threads.py"
SPEC = importlib.util.spec_from_file_location("review_threads", SCRIPT_PATH)
assert SPEC is not None and SPEC.loader is not None
review_threads = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = review_threads
SPEC.loader.exec_module(review_threads)


def page(nodes: list[dict], has_next: bool = False, cursor: str | None = None) -> dict:
    return {"nodes": nodes, "pageInfo": {"hasNextPage": has_next, "endCursor": cursor}}


def comment(identifier: str) -> dict:
    return {
        "id": identifier,
        "databaseId": 1,
        "url": f"https://example.test/comments/{identifier}",
        "body": f"Comment {identifier}",
        "updatedAt": "2026-09-06T00:00:00Z",
        "createdAt": "2026-09-06T00:00:00Z",
        "author": {"login": "reviewer"},
        "commit": {"oid": "head-1"},
    }


def thread(
    identifier: str,
    comments: list[dict] | None = None,
    *,
    resolved: bool = False,
    can_resolve: bool = True,
    has_next_comments: bool = False,
    comment_cursor: str | None = None,
) -> dict:
    return {
        "id": identifier,
        "isResolved": resolved,
        "isOutdated": False,
        "viewerCanResolve": can_resolve,
        "path": "Sources/File.swift",
        "line": 10,
        "originalLine": 10,
        "comments": page(comments or [comment(f"{identifier}-comment")], has_next_comments, comment_cursor),
    }


def snapshot(
    threads: list[dict], *, head: str = "head-1", pr_id: str = "pr-1", state: str = "OPEN"
) -> dict:
    return {
        "repo": "owner/repo",
        "number": 42,
        "id": pr_id,
        "url": "https://example.test/pr/42",
        "headRefOid": head,
        "state": state,
        "threads": threads,
    }


def decision(current_thread: dict, **changes: object) -> dict:
    value = {
        "thread_id": current_thread["id"],
        "assessment": "fixed",
        "fingerprint": review_threads.fingerprint(current_thread),
        "evidence": "Verified by the current implementation.",
        "permalink": "https://example.test/permalink",
        "evidence_head": "head-1",
    }
    value.update(changes)
    return value


def plan(*decisions: dict, **changes: object) -> dict:
    value = {
        "version": 1,
        "repo": "owner/repo",
        "number": 42,
        "id": "pr-1",
        "headRefOid": "head-1",
        "decisions": list(decisions),
    }
    value.update(changes)
    return value


class CollectTests(unittest.TestCase):
    def test_graphql_sets_a_bounded_timeout(self) -> None:
        completed = subprocess.CompletedProcess(["gh"], 0, '{"data":{"ok":true}}', "")
        with patch.object(review_threads.subprocess, "run", return_value=completed) as run:
            result = review_threads.graphql("query { viewer { login } }")

        self.assertEqual(result, {"ok": True})
        self.assertEqual(run.call_args.kwargs["timeout"], 60)

    def test_collects_all_thread_and_comment_pages(self) -> None:
        first = thread("thread-1", [comment("c-1")], has_next_comments=True, comment_cursor="comments-2")
        second = thread("thread-2", [comment("c-3")])
        responses = [
            {"repository": {"pullRequest": {"id": "pr-1", "url": "url", "headRefOid": "head-1", "state": "OPEN", "reviewThreads": page([first], True, "threads-2")}}},
            {"node": {"comments": page([comment("c-2")])}},
            {"repository": {"pullRequest": {"id": "pr-1", "url": "url", "headRefOid": "head-1", "state": "OPEN", "reviewThreads": page([second])}}},
            {"repository": {"pullRequest": {"id": "pr-1", "url": "url", "headRefOid": "head-1", "state": "OPEN"}}},
        ]

        with patch.object(review_threads, "graphql", side_effect=responses) as graphql:
            result = review_threads.collect("owner/repo", 42)

        self.assertEqual([item["id"] for item in result["threads"]], ["thread-1", "thread-2"])
        self.assertEqual([item["id"] for item in result["threads"][0]["comments"]], ["c-1", "c-2"])
        self.assertEqual(graphql.call_count, 4)

    def test_rejects_cyclic_thread_pagination(self) -> None:
        response = {"repository": {"pullRequest": {"id": "pr-1", "url": "url", "headRefOid": "head-1", "state": "OPEN", "reviewThreads": page([], True, "again")}}}
        with patch.object(review_threads, "graphql", side_effect=[response, response]):
            with self.assertRaisesRegex(ValueError, "cyclic pagination"):
                review_threads.collect("owner/repo", 42)

    def test_rejects_cyclic_comment_pagination(self) -> None:
        first = thread("thread-1", has_next_comments=True, comment_cursor="again")
        repeated_comments = {"node": {"comments": page([comment("c-2")], True, "again")}}
        initial = {"repository": {"pullRequest": {"id": "pr-1", "url": "url", "headRefOid": "head-1", "state": "OPEN", "reviewThreads": page([first])}}}
        with patch.object(review_threads, "graphql", side_effect=[initial, repeated_comments]):
            with self.assertRaisesRegex(ValueError, "cyclic pagination"):
                review_threads.collect("owner/repo", 42)

    def test_rejects_pr_identity_change_between_thread_pages(self) -> None:
        initial = {"repository": {"pullRequest": {"id": "pr-1", "url": "url", "headRefOid": "head-1", "state": "OPEN", "reviewThreads": page([], True, "next")}}}
        changed = {"repository": {"pullRequest": {"id": "pr-1", "url": "url", "headRefOid": "head-2", "state": "OPEN", "reviewThreads": page([])}}}
        with patch.object(review_threads, "graphql", side_effect=[initial, changed]):
            with self.assertRaisesRegex(ValueError, "PR changed during collection"):
                review_threads.collect("owner/repo", 42)

    def test_final_identity_check_rejects_head_drift_during_last_comment_page_without_mutating(self) -> None:
        planned = thread("thread-1")
        last_page_thread = thread(
            "thread-1",
            [comment("c-1")],
            has_next_comments=True,
            comment_cursor="comments-2",
        )
        initial = {
            "repository": {
                "pullRequest": {
                    "id": "pr-1",
                    "url": "url",
                    "headRefOid": "head-1",
                    "state": "OPEN",
                    "reviewThreads": page([last_page_thread]),
                }
            }
        }
        comment_page = {"node": {"comments": page([comment("c-2")])}}
        changed_final = {
            "repository": {
                "pullRequest": {
                    "id": "pr-1",
                    "url": "url",
                    "headRefOid": "head-2",
                    "state": "OPEN",
                }
            }
        }
        queries: list[str] = []

        def fake_graphql(query: str, **_variables: object) -> dict:
            queries.append(query)
            return [initial, comment_page, changed_final][len(queries) - 1]

        with patch.object(review_threads, "graphql", side_effect=fake_graphql):
            results = review_threads.apply_plan(plan(decision(planned)))

        self.assertEqual(results[0]["status"], "error")
        self.assertIn("PR changed during collection", results[0]["error"])
        self.assertFalse(any("mutation" in query for query in queries))

    def test_rejects_duplicate_thread_or_comment_ids(self) -> None:
        duplicate_threads = {"repository": {"pullRequest": {"id": "pr-1", "url": "url", "headRefOid": "head-1", "state": "OPEN", "reviewThreads": page([thread("same"), thread("same")])}}}
        with patch.object(review_threads, "graphql", return_value=duplicate_threads):
            with self.assertRaisesRegex(ValueError, "Duplicate threads"):
                review_threads.collect("owner/repo", 42)

        duplicate_comments = thread("thread-1", [comment("same"), comment("same")])
        one_thread = {"repository": {"pullRequest": {"id": "pr-1", "url": "url", "headRefOid": "head-1", "state": "OPEN", "reviewThreads": page([duplicate_comments])}}}
        with patch.object(review_threads, "graphql", return_value=one_thread):
            with self.assertRaisesRegex(ValueError, "Duplicate comments"):
                review_threads.collect("owner/repo", 42)


class ApplyPlanTests(unittest.TestCase):
    def test_validate_plan_requires_allowed_assessment_and_current_semantic_evidence(self) -> None:
        current = thread("thread-1")
        for invalid in (
            decision(current, assessment="needs_fix"),
            decision(current, evidence="  "),
            decision(current, evidence_head="older-head"),
        ):
            with self.assertRaises(ValueError):
                review_threads.validate_plan(plan(invalid))

    def test_resolves_only_after_fresh_snapshot_and_reads_back(self) -> None:
        current = thread("thread-1")
        after = thread("thread-1", resolved=True)
        calls: list[str] = []

        def fake_graphql(query: str, **_variables: object) -> dict:
            calls.append(query)
            self.assertEqual(len(calls), 1, "the mutation must have exactly one fresh snapshot before it")
            return {"data": "ignored"}

        with patch.object(review_threads, "collect", side_effect=[snapshot([current]), snapshot([after])]) as collect, patch.object(review_threads, "graphql", side_effect=fake_graphql):
            results = review_threads.apply_plan(plan(decision(current)))

        self.assertEqual(results[0]["status"], "resolved")
        self.assertEqual(collect.call_count, 2)
        self.assertIn("resolveReviewThread", calls[0])

    def test_already_resolved_is_idempotent_and_does_not_mutate(self) -> None:
        current = thread("thread-1", resolved=True)
        with patch.object(review_threads, "collect", return_value=snapshot([current])), patch.object(review_threads, "graphql") as graphql:
            results = review_threads.apply_plan(plan(decision(current)))

        self.assertEqual(results[0]["status"], "already_resolved")
        graphql.assert_not_called()

    def test_thread_drift_is_skipped_but_a_later_stable_thread_can_proceed(self) -> None:
        planned_first, planned_second = thread("thread-1"), thread("thread-2")
        drifted_first = thread("thread-1", [comment("new-comment")])
        stable_second = thread("thread-2")
        resolved_second = thread("thread-2", resolved=True)
        with patch.object(
            review_threads,
            "collect",
            side_effect=[snapshot([drifted_first]), snapshot([stable_second]), snapshot([resolved_second])],
        ), patch.object(review_threads, "graphql") as graphql:
            results = review_threads.apply_plan(plan(decision(planned_first), decision(planned_second)))

        self.assertEqual([result["status"] for result in results], ["stale_thread", "resolved"])
        graphql.assert_called_once()

    def test_pr_drift_stops_and_reports_unattempted_decisions(self) -> None:
        first, second = thread("thread-1"), thread("thread-2")
        with patch.object(review_threads, "collect", return_value=snapshot([first, second], head="new-head")), patch.object(review_threads, "graphql") as graphql:
            results = review_threads.apply_plan(plan(decision(first), decision(second)))

        self.assertEqual([result["status"] for result in results], ["stale_pr", "not_attempted"])
        graphql.assert_not_called()

    def test_missing_permission_is_reported_without_mutation(self) -> None:
        current = thread("thread-1", can_resolve=False)
        with patch.object(review_threads, "collect", return_value=snapshot([current])), patch.object(review_threads, "graphql") as graphql:
            results = review_threads.apply_plan(plan(decision(current)))

        self.assertEqual(results[0]["status"], "cannot_resolve")
        graphql.assert_not_called()

    def test_post_mutation_head_or_thread_change_is_never_reported_as_success(self) -> None:
        current = thread("thread-1")
        changed = thread("thread-1", resolved=True)
        another = thread("thread-2")
        with patch.object(review_threads, "collect", side_effect=[snapshot([current]), snapshot([changed], head="new-head")]), patch.object(review_threads, "graphql"):
            results = review_threads.apply_plan(plan(decision(current), decision(another)))

        self.assertEqual([result["status"] for result in results], ["changed_after_mutation", "not_attempted"])
        self.assertTrue(results[0]["isResolved"])

    def test_post_mutation_permission_change_is_expected_when_resolution_succeeds(self) -> None:
        current = thread("thread-1", can_resolve=True)
        after = thread("thread-1", resolved=True, can_resolve=False)
        with patch.object(review_threads, "collect", side_effect=[snapshot([current]), snapshot([after])]), patch.object(review_threads, "graphql"):
            results = review_threads.apply_plan(plan(decision(current)))

        self.assertEqual(results[0]["status"], "resolved")

    def test_mutation_failure_is_unknown_and_never_claims_resolution(self) -> None:
        current, another = thread("thread-1"), thread("thread-2")
        transport_error = subprocess.CalledProcessError(1, ["gh", "api", "graphql"])
        with patch.object(review_threads, "collect", return_value=snapshot([current, another])), patch.object(review_threads, "graphql", side_effect=transport_error):
            results = review_threads.apply_plan(plan(decision(current), decision(another)))

        self.assertEqual([result["status"] for result in results], ["unknown_after_mutation", "not_attempted"])


class CommandTests(unittest.TestCase):
    def test_collect_cli_emits_fingerprints(self) -> None:
        current = thread("thread-1")
        expected_fingerprint = review_threads.fingerprint(current)
        output = io.StringIO()
        with patch.object(review_threads, "collect", return_value=snapshot([current])), patch.object(sys, "argv", ["review_threads.py", "collect", "--repo", "owner/repo", "--pr", "42"]), contextlib.redirect_stdout(output):
            exit_code = review_threads.main()

        self.assertEqual(exit_code, 0)
        result = json.loads(output.getvalue())
        self.assertEqual(result["threads"][0]["fingerprint"], expected_fingerprint)

    def test_apply_cli_requires_explicit_allow_resolve(self) -> None:
        with patch.object(sys, "argv", ["review_threads.py", "apply", "--plan", "plan.json"]):
            with self.assertRaises(SystemExit) as raised:
                review_threads.main()

        self.assertEqual(raised.exception.code, 2)


if __name__ == "__main__":
    unittest.main()
