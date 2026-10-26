from __future__ import annotations

import importlib.util
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
        "viewerDidAuthor": False,
        "state": "SUBMITTED",
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


def target_response(
    target: dict | None,
    *,
    head: str = "head-1",
    pr_id: str = "pr-1",
    state: str = "OPEN",
) -> dict:
    """Return the GraphQL envelope used by collect_thread's page query."""
    node = None
    if target is not None:
        node = dict(target, pullRequest={"id": pr_id})
    return {
        "repository": {
            "pullRequest": {
                "id": pr_id,
                "url": "https://example.test/pr/42",
                "headRefOid": head,
                "state": state,
            }
        },
        "node": node,
    }


def target_final_response(
    target: dict | None,
    *,
    total_count: int = 1,
    head: str = "head-1",
    pr_id: str = "pr-1",
    state: str = "OPEN",
) -> dict:
    """Return collect_thread's final identity/count guard response."""
    node = None
    if target is not None:
        node = {
            **{key: target[key] for key in review_threads.THREAD_FIELDS.split()},
            "pullRequest": {"id": pr_id},
            "comments": {"totalCount": total_count},
        }
    return target_response(node, head=head, pr_id=pr_id, state=state)


def decision(current_thread: dict, **changes: object) -> dict:
    value = {
        "thread_id": current_thread["id"],
        "assessment": "fixed",
        "fingerprint": review_threads.fingerprint(current_thread),
        "evidence": "Verified by the current implementation.",
        "permalink": "https://example.test/permalink",
        "evidence_head": "head-1",
        "reply_body": "Fixed in the current remote implementation; validation not run.",
    }
    value.update(changes)
    return value


def plan(*decisions: dict, **changes: object) -> dict:
    value = {
        "version": 2,
        "repo": "owner/repo",
        "number": 42,
        "id": "pr-1",
        "headRefOid": "head-1",
        "decisions": list(decisions),
    }
    value.update(changes)
    return value


class CollectTests(unittest.TestCase):
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

    def test_rejects_pr_identity_change_between_thread_pages(self) -> None:
        initial = {"repository": {"pullRequest": {"id": "pr-1", "url": "url", "headRefOid": "head-1", "state": "OPEN", "reviewThreads": page([], True, "next")}}}
        changed = {"repository": {"pullRequest": {"id": "pr-1", "url": "url", "headRefOid": "head-2", "state": "OPEN", "reviewThreads": page([])}}}
        with patch.object(review_threads, "graphql", side_effect=[initial, changed]):
            with self.assertRaisesRegex(ValueError, "PR changed during collection"):
                review_threads.collect("owner/repo", 42)

    def test_final_identity_check_rejects_head_drift_during_last_comment_page_without_mutating(self) -> None:
        planned = thread("thread-1")
        first_page_thread = thread(
            "thread-1",
            [comment("c-1")],
            has_next_comments=True,
            comment_cursor="comments-2",
        )
        second_page_thread = thread("thread-1", [comment("c-2")])
        initial = target_response(first_page_thread)
        second_page = target_response(second_page_thread)
        changed_final = target_final_response(second_page_thread, total_count=2, head="head-2")
        queries: list[str] = []

        def fake_graphql(query: str, **_variables: object) -> dict:
            queries.append(query)
            return [initial, second_page, changed_final][len(queries) - 1]

        with patch.object(review_threads, "graphql", side_effect=fake_graphql):
            results = review_threads.apply_plan(plan(decision(planned)))

        self.assertEqual(results[0]["status"], "error")
        self.assertIn("PR or target thread changed after pagination", results[0]["error"])
        self.assertFalse(any("mutation" in query for query in queries))

class CollectTargetThreadTests(unittest.TestCase):
    def test_collect_thread_reads_only_target_and_all_comment_pages(self) -> None:
        first = thread("thread-1", [comment("c-1")], has_next_comments=True, comment_cursor="comments-2")
        second = thread("thread-1", [comment("c-2")])
        responses = [
            target_response(first),
            target_response(second),
            target_final_response(second, total_count=2),
        ]

        with patch.object(review_threads, "graphql", side_effect=responses) as graphql:
            result = review_threads.collect_thread("owner/repo", 42, "thread-1")

        self.assertEqual([item["id"] for item in result["threads"]], ["thread-1"])
        self.assertEqual([item["id"] for item in result["threads"][0]["comments"]], ["c-1", "c-2"])
        self.assertEqual(graphql.call_count, 3)
        first_call = graphql.call_args_list[0]
        second_call = graphql.call_args_list[1]
        self.assertIn("node(id:$id)", first_call.args[0])
        self.assertEqual(first_call.kwargs, {"owner": "owner", "name": "repo", "number": 42, "id": "thread-1", "cursor": None})
        self.assertEqual(second_call.kwargs["cursor"], "comments-2")
        self.assertIn("totalCount", graphql.call_args_list[2].args[0])

    def test_collect_thread_rejects_foreign_thread(self) -> None:
        foreign = thread("thread-1")
        with patch.object(
            review_threads,
            "graphql",
            return_value=target_response(foreign, pr_id="pr-1"),
        ) as graphql:
            # The requested PR stays pr-1 while the target node identifies pr-other.
            graphql.return_value["node"]["pullRequest"] = {"id": "pr-other"}
            with self.assertRaisesRegex(ValueError, "does not belong"):
                review_threads.collect_thread("owner/repo", 42, "thread-1")

def collected_thread(identifier: str, *, resolved: bool = False, can_resolve: bool = True) -> dict:
    value = thread(identifier, resolved=resolved, can_resolve=can_resolve)
    value["comments"] = value["comments"]["nodes"]
    return value


def reply_comment() -> dict:
    return dict(comment("reply-1"), viewerDidAuthor=True, body=decision({"id": "unused"})["reply_body"])


def with_reply(current: dict, *, resolved: bool = False) -> dict:
    return dict(current, comments=current["comments"] + [reply_comment()], isResolved=resolved)


class ApplyPlanTests(unittest.TestCase):
    def test_replies_then_resolves_only_after_confirmation_and_reads_back(self) -> None:
        current = collected_thread("thread-1")
        replied = with_reply(current)
        events = []

        def collect(*_args):
            events.append("collect")
            return snapshot([[current, replied, dict(replied, isResolved=True)][events.count("collect") - 1]])

        def mutate(query, **variables):
            if "addPullRequestReviewThreadReply" in query:
                events.append("reply")
                self.assertEqual(variables, {"id": "thread-1", "body": decision(current)["reply_body"]})
                return {"addPullRequestReviewThreadReply": {"comment": reply_comment()}}
            self.assertIn("resolveReviewThread", query)
            events.append("resolve")
            return {}

        with patch.object(review_threads, "collect_thread", side_effect=collect), patch.object(review_threads, "graphql", side_effect=mutate):
            result = review_threads.apply_plan(plan(decision(current)))[0]
        self.assertEqual(events, ["collect", "reply", "collect", "resolve", "collect"])
        self.assertEqual(result["status"], "resolved")
        self.assertEqual(result["reply_status"], "posted")
        self.assertEqual(result["reply_url"], reply_comment()["url"])

    def test_thread_drift_is_skipped_but_a_later_stable_thread_can_proceed(self) -> None:
        first, second = collected_thread("thread-1"), collected_thread("thread-2")
        replied = with_reply(second)
        drifted = dict(first, comments=first["comments"] + [comment("new-comment")])
        with patch.object(review_threads, "collect_thread", side_effect=[snapshot([drifted]), snapshot([second]), snapshot([replied]), snapshot([dict(replied, isResolved=True)])]), patch.object(review_threads, "graphql", side_effect=[{"addPullRequestReviewThreadReply": {"comment": reply_comment()}}, {}]) as graphql:
            results = review_threads.apply_plan(plan(decision(first), decision(second)))
        self.assertEqual([result["status"] for result in results], ["stale_thread", "resolved"])
        self.assertEqual(graphql.call_count, 2)

    def test_pr_drift_stops_and_reports_unattempted_decisions(self) -> None:
        first, second = collected_thread("thread-1"), collected_thread("thread-2")
        with patch.object(review_threads, "collect_thread", return_value=snapshot([first], head="new-head")) as collect, patch.object(review_threads, "graphql") as graphql:
            results = review_threads.apply_plan(plan(decision(first), decision(second)))
        self.assertEqual([result["status"] for result in results], ["stale_pr", "not_attempted"])
        collect.assert_called_once()
        graphql.assert_not_called()

    def test_missing_permission_and_already_resolved_do_not_reply(self) -> None:
        for current, status in [(collected_thread("thread-1", can_resolve=False), "cannot_resolve"), (collected_thread("thread-1", resolved=True), "already_resolved")]:
            with self.subTest(status=status), patch.object(review_threads, "collect_thread", return_value=snapshot([current])), patch.object(review_threads, "graphql") as graphql:
                result = review_threads.apply_plan(plan(decision(current)))[0]
                self.assertEqual(result["status"], status)
                self.assertEqual(result["reply_status"], "not_attempted")
                graphql.assert_not_called()

    def test_reply_failure_never_attempts_resolve(self) -> None:
        current, another = collected_thread("thread-1"), collected_thread("thread-2")
        error = subprocess.CalledProcessError(1, ["gh", "api", "graphql"])
        with patch.object(review_threads, "collect_thread", return_value=snapshot([current])), patch.object(review_threads, "graphql", side_effect=error) as graphql:
            results = review_threads.apply_plan(plan(decision(current), decision(another)))
        self.assertEqual([result["status"] for result in results], ["unknown_after_mutation", "not_attempted"])
        self.assertEqual(results[0]["reply_status"], "unknown")
        graphql.assert_called_once()
        self.assertIn("addPullRequestReviewThreadReply", graphql.call_args.args[0])

    def test_lost_reply_response_is_reused_after_refresh_without_duplicate(self) -> None:
        remote_thread = collected_thread("thread-1")
        original_plan = plan(decision(remote_thread))
        mutations = []

        def fake_graphql(query, **variables):
            if "addPullRequestReviewThreadReply" in query:
                mutations.append("reply")
                remote_thread["comments"].append(
                    dict(reply_comment(), body=variables["body"])
                )
                # The server commits the reply before the client loses its response.
                raise subprocess.TimeoutExpired(["gh", "api", "graphql"], 60)
            if "resolveReviewThread" in query:
                mutations.append("resolve")
                remote_thread["isResolved"] = True
                return {"resolveReviewThread": {"thread": {"id": "thread-1", "isResolved": True}}}
            if "totalCount" in query:
                return target_final_response(
                    remote_thread, total_count=len(remote_thread["comments"])
                )
            self.assertIn("node(id:$id)", query)
            return target_response(
                dict(remote_thread, comments=page(list(remote_thread["comments"])))
            )

        with patch.object(review_threads, "graphql", side_effect=fake_graphql):
            failed = review_threads.apply_plan(original_plan)[0]
            self.assertEqual(failed["status"], "unknown_after_mutation")
            self.assertEqual(failed["reply_status"], "unknown")
            self.assertNotIn("reply_id", failed)
            self.assertFalse(remote_thread["isResolved"])
            self.assertEqual(mutations, ["reply"])

            stale = review_threads.apply_plan(original_plan)[0]
            self.assertEqual(stale["status"], "stale_thread")
            self.assertEqual(mutations, ["reply"])

            refreshed = review_threads.collect_thread("owner/repo", 42, "thread-1")
            refreshed_decision = decision(refreshed["threads"][0])
            self.assertNotEqual(
                refreshed_decision["fingerprint"], original_plan["decisions"][0]["fingerprint"]
            )
            resumed = review_threads.apply_plan(plan(refreshed_decision))[0]

        self.assertEqual(resumed["status"], "resolved")
        self.assertEqual(resumed["reply_status"], "reused")
        self.assertEqual(resumed["reply_id"], "reply-1")
        self.assertEqual(resumed["reply_url"], reply_comment()["url"])
        self.assertEqual(mutations, ["reply", "resolve"])
        self.assertEqual(
            [item["id"] for item in remote_thread["comments"]],
            ["thread-1-comment", "reply-1"],
        )
        self.assertTrue(remote_thread["isResolved"])

    def test_changes_after_reply_prevent_resolution(self) -> None:
        current = collected_thread("thread-1")
        replied = with_reply(current)
        changed = dict(replied, comments=replied["comments"] + [comment("follow-up")])
        cases = [snapshot([replied], head="new-head"), snapshot([changed]), snapshot([current])]
        for after in cases:
            with self.subTest(after=after), patch.object(review_threads, "collect_thread", side_effect=[snapshot([current]), after]), patch.object(review_threads, "graphql", return_value={"addPullRequestReviewThreadReply": {"comment": reply_comment()}}) as graphql:
                result = review_threads.apply_plan(plan(decision(current)))[0]
                self.assertEqual(result["status"], "changed_after_reply")
                self.assertEqual(result["reply_status"], "posted")
                graphql.assert_called_once()

    def test_resolve_failure_preserves_reply_and_refreshed_plan_reuses_it(self) -> None:
        current = collected_thread("thread-1")
        replied = with_reply(current)
        error = subprocess.CalledProcessError(1, ["gh", "api", "graphql"])
        with patch.object(review_threads, "collect_thread", side_effect=[snapshot([current]), snapshot([replied])]), patch.object(review_threads, "graphql", side_effect=[{"addPullRequestReviewThreadReply": {"comment": reply_comment()}}, error]):
            result = review_threads.apply_plan(plan(decision(current)))[0]
        self.assertEqual(result["status"], "unknown_after_mutation")
        self.assertEqual(result["reply_status"], "posted")
        self.assertEqual(result["reply_id"], "reply-1")
        with patch.object(review_threads, "collect_thread", side_effect=[snapshot([replied]), snapshot([dict(replied, isResolved=True)])]), patch.object(review_threads, "graphql", return_value={}) as graphql:
            resumed = review_threads.apply_plan(plan(decision(replied)))[0]
        self.assertEqual(resumed["status"], "resolved")
        self.assertEqual(resumed["reply_status"], "reused")
        graphql.assert_called_once()
        self.assertIn("resolveReviewThread", graphql.call_args.args[0])

    def test_other_users_or_pending_matching_reply_is_not_reused(self) -> None:
        for changes in [{"viewerDidAuthor": False}, {"state": "PENDING"}]:
            current = collected_thread("thread-1")
            current["comments"].append(dict(reply_comment(), id="other-reply", **changes))
            replied = with_reply(current)
            with self.subTest(changes=changes), patch.object(review_threads, "collect_thread", side_effect=[snapshot([current]), snapshot([replied]), snapshot([dict(replied, isResolved=True)])]), patch.object(review_threads, "graphql", side_effect=[{"addPullRequestReviewThreadReply": {"comment": reply_comment()}}, {}]) as graphql:
                result = review_threads.apply_plan(plan(decision(current)))[0]
                self.assertEqual(result["reply_status"], "posted")
                self.assertEqual(graphql.call_count, 2)

    def test_pending_reply_response_does_not_resolve(self) -> None:
        current = collected_thread("thread-1")
        with patch.object(review_threads, "collect_thread", return_value=snapshot([current])), patch.object(review_threads, "graphql", return_value={"addPullRequestReviewThreadReply": {"comment": dict(reply_comment(), state="PENDING")}}) as graphql:
            result = review_threads.apply_plan(plan(decision(current)))[0]
        self.assertEqual(result["status"], "unknown_after_mutation")
        self.assertEqual(result["reply_status"], "unknown")
        graphql.assert_called_once()

    def test_post_resolution_drift_is_not_success(self) -> None:
        current = with_reply(collected_thread("thread-1"))
        with patch.object(review_threads, "collect_thread", side_effect=[snapshot([current]), snapshot([dict(current, isResolved=True)], head="new-head")]), patch.object(review_threads, "graphql", return_value={}):
            result = review_threads.apply_plan(plan(decision(current)))[0]
        self.assertEqual(result["status"], "changed_after_mutation")
        self.assertTrue(result["isResolved"])

    def test_old_plan_and_empty_reply_are_rejected_before_io(self) -> None:
        current = collected_thread("thread-1")
        for invalid in [plan(decision(current), version=1), plan(decision(current, reply_body=" "))]:
            with self.subTest(plan=invalid), patch.object(review_threads, "graphql") as graphql:
                with self.assertRaises(ValueError):
                    review_threads.apply_plan(invalid)
                graphql.assert_not_called()


class CommandTests(unittest.TestCase):
    def test_graphql_preserves_literal_reply_body(self) -> None:
        for body in ["@filename", "true", "123", "First line\nSecond line"]:
            response = subprocess.CompletedProcess([], 0, stdout='{"data":{"ok":true}}')
            with self.subTest(body=body), patch.object(review_threads.subprocess, "run", return_value=response) as run:
                self.assertEqual(review_threads.graphql("mutation", body=body, number=42), {"ok": True})
                arguments = run.call_args.args[0]
                self.assertEqual(arguments[arguments.index("body=" + body) - 1], "-f")
                self.assertEqual(arguments[arguments.index("number=42") - 1], "-F")

    def test_apply_cli_requires_explicit_allow_resolve(self) -> None:
        for flags in [[], ["--allow-resolve"], ["--allow-reply"]]:
            with self.subTest(flags=flags), patch.object(sys, "argv", ["review_threads.py", "apply", "--plan", "plan.json", *flags]):
                with self.assertRaises(SystemExit) as raised:
                    review_threads.main()
                self.assertEqual(raised.exception.code, 2)


if __name__ == "__main__":
    unittest.main()
