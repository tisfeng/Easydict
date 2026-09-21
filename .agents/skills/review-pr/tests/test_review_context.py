from __future__ import annotations

import importlib.util
from pathlib import Path
import sys
import unittest
from unittest.mock import patch


SKILL_ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = SKILL_ROOT / "scripts" / "review_context.py"
sys.path.insert(0, str(SKILL_ROOT / "scripts"))
SPEC = importlib.util.spec_from_file_location("review_context", SCRIPT_PATH)
assert SPEC is not None and SPEC.loader is not None
review_context = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = review_context
SPEC.loader.exec_module(review_context)


def connection(
    nodes: list[dict[str, object]],
    *,
    total_count: int | None = None,
    has_next: bool = False,
    cursor: str | None = None,
) -> dict[str, object]:
    return {
        "nodes": nodes,
        "totalCount": len(nodes) if total_count is None else total_count,
        "pageInfo": {"hasNextPage": has_next, "endCursor": cursor},
    }


def issue(
    number: int,
    *,
    repo: str = "owner/repo",
    body: str = "",
    identifier: str | None = None,
    comments: dict[str, object] | None = None,
    updated_at: str = "2026-09-11T00:00:00Z",
) -> dict[str, object]:
    return {
        "__typename": "Issue",
        "id": identifier or f"ISSUE_{repo.replace('/', '_')}_{number}",
        "number": number,
        "url": f"https://github.com/{repo}/issues/{number}",
        "title": f"Issue {number}",
        "body": body,
        "state": "OPEN",
        "updatedAt": updated_at,
        "comments": comments or connection([]),
    }


def comment(identifier: str, body: str) -> dict[str, object]:
    return {
        "id": identifier,
        "url": f"https://github.com/owner/repo/issues/2#issuecomment-{identifier}",
        "body": body,
        "createdAt": "2026-09-11T00:00:00Z",
        "updatedAt": "2026-09-11T00:00:00Z",
        "author": {"login": "reviewer"},
    }


def pr_context(body: str = "", closing: list[dict[str, object]] | None = None) -> dict[str, object]:
    return {
        "number": 42,
        "url": "https://github.com/owner/repo/pull/42",
        "headRefOid": "head-1",
        "title": "PR title",
        "body": body,
        "closingIssuesReferences": closing or [],
    }


def issue_response(value: dict[str, object]) -> dict[str, object]:
    return {"repository": {"issueOrPullRequest": value}}


class ParseReferenceTests(unittest.TestCase):
    def test_normalizes_supported_references_and_rejects_unsafe_ones(self) -> None:
        accepted = {
            "#12": ("owner/repo", 12),
            "12": ("owner/repo", 12),
            "Other/Project#7": ("other/project", 7),
            "https://github.com/Other/Project/issues/7": ("other/project", 7),
        }
        for raw, expected in accepted.items():
            with self.subTest(raw=raw):
                self.assertEqual(review_context.parse_reference(raw, "OWNER/REPO"), expected)

        for raw in (
            "#0",
            "-1",
            "owner/../repo#1",
            "owner/repo/pull/1",
            "https://example.com/owner/repo/issues/1",
            "https://github.com/owner/repo/pull/1",
            "https://github.com/owner/repo/issues/0",
            "owner/repo#not-a-number",
        ):
            with self.subTest(raw=raw):
                with self.assertRaises(ValueError):
                    review_context.parse_reference(raw, "owner/repo")

    def test_find_references_ignores_fenced_and_inline_examples(self) -> None:
        text = """\
Actual requirement: #4.
`Example only: #3`
```markdown
Do not infer this #2 from a fenced example.
```
"""
        self.assertEqual(review_context.find_references(text, "owner/repo"), ["owner/repo#4"])


class CollectTests(unittest.TestCase):
    def test_large_closing_references_collect_all_pages_before_reading_issues(self) -> None:
        capped = [{"url": f"https://github.com/owner/repo/issues/{number}"} for number in range(1, 101)]
        first_page = {
            "repository": {
                "pullRequest": {
                    "url": "https://github.com/owner/repo/pull/42",
                    "headRefOid": "head-1",
                    "closingIssuesReferences": connection(capped, has_next=True, cursor="next"),
                }
            }
        }
        second_page = {
            "repository": {
                "pullRequest": {
                    "url": "https://github.com/owner/repo/pull/42",
                    "headRefOid": "head-1",
                    "closingIssuesReferences": connection(
                        [{"url": "https://github.com/owner/repo/issues/101"}]
                    ),
                }
            }
        }
        with (
            patch.object(review_context, "graphql", side_effect=[first_page, second_page]) as graphql,
            patch.object(
                review_context, "read_issue", return_value={"read_status": "read", "issue": {}, "comments": {}}
            ),
        ):
            result = review_context.collect("owner/repo", pr_context(closing=capped))

        self.assertTrue(result["references_complete"])
        self.assertEqual(len(result["issues"]), 101)
        self.assertEqual(graphql.call_count, 2)
        self.assertEqual(graphql.call_args_list[0].kwargs["cursor"], None)
        self.assertEqual(graphql.call_args_list[1].kwargs["cursor"], "next")

    def test_large_closing_reference_page_rejects_pr_identity_drift(self) -> None:
        capped = [{"url": f"https://github.com/owner/repo/issues/{number}"} for number in range(1, 101)]
        drifted = {
            "repository": {
                "pullRequest": {
                    "url": "https://github.com/owner/repo/pull/42",
                    "headRefOid": "head-2",
                    "closingIssuesReferences": connection([]),
                }
            }
        }
        with patch.object(review_context, "graphql", return_value=drifted):
            with self.assertRaisesRegex(
                review_context.ContextDriftError, "PR changed during closing issue collection"
            ):
                review_context.collect("owner/repo", pr_context(closing=capped))

    def test_collect_deduplicates_references_and_preserves_every_relation(self) -> None:
        closing = issue(2)
        def fake_graphql(_query: str, **variables: object) -> dict[str, object]:
            if variables["owner"] == "cross":
                return issue_response(issue(3, repo="cross/repo"))
            return issue_response(issue(2))

        with patch.object(review_context, "graphql", side_effect=fake_graphql) as graphql:
            result = review_context.collect(
                "OWNER/REPO",
                pr_context("Background #2 and cross/repo#3", [closing]),
                issue_refs=("#2", "cross/repo#3"),
                discussion_refs=("#2",),
            )

        self.assertEqual(result["schema_version"], 1)
        self.assertEqual(result["requested_issues"], ["cross/repo#3", "owner/repo#2"])
        self.assertEqual(result["discussion_issues"], ["owner/repo#2"])
        self.assertTrue(result["references_complete"])
        by_key = {(item["repo"], item["number"]): item for item in result["issues"]}
        self.assertCountEqual(
            by_key[("owner/repo", 2)]["relations"],
            ["closing", "mentioned", "requested", "discussion"],
        )
        self.assertCountEqual(
            by_key[("cross/repo", 3)]["relations"], ["mentioned", "requested"]
        )
        self.assertEqual(graphql.call_count, 3)

    def test_records_issue_read_errors_and_pr_mistypes_without_losing_context(self) -> None:
        def fake_graphql(_query: str, **variables: object) -> dict[str, object]:
            if variables["number"] == 2:
                return issue_response({"__typename": "PullRequest", "id": "PR_2", "number": 2})
            if variables["number"] == 3:
                raise OSError("network unavailable")
            self.fail(f"Unexpected issue query: {variables}")

        with patch.object(review_context, "graphql", side_effect=fake_graphql):
            result = review_context.collect("owner/repo", pr_context("#2 #3"))

        self.assertTrue(result["references_complete"])
        by_number = {item["number"]: item for item in result["issues"]}
        self.assertEqual(by_number[2]["read_status"], "not_issue")
        self.assertEqual(by_number[3]["read_status"], "read_failed")
        self.assertIn("network unavailable", by_number[3]["diagnostic"])

    def test_discussion_comments_paginate_and_final_guard_rejects_issue_drift(self) -> None:
        first_comments = connection(
            [comment("comment-1", "First")], total_count=2, has_next=True, cursor="next-page"
        )
        stable_initial = issue(2, comments=first_comments)
        next_comments = connection([comment("comment-2", "Second")], total_count=2)
        stable_final = issue(
            2,
            comments={"totalCount": 2, "nodes": []},
        )
        drifted_final = issue(
            2,
            comments={"totalCount": 2, "nodes": []},
            updated_at="2026-09-11T00:01:00Z",
        )
        with patch.object(
            review_context,
            "graphql",
            side_effect=[
                issue_response(stable_initial),
                issue_response(issue(2, comments=next_comments)),
                issue_response(stable_final),
            ],
        ):
            complete = review_context.collect("owner/repo", pr_context(), discussion_refs=("#2",))

        item = complete["issues"][0]
        self.assertEqual(item["comments"]["status"], "complete")
        self.assertEqual([comment["id"] for comment in item["comments"]["items"]], ["comment-1", "comment-2"])
        self.assertEqual(item["comments"]["totalCount"], 2)

        with patch.object(
            review_context,
            "graphql",
            side_effect=[
                issue_response(stable_initial),
                issue_response(issue(2, comments=next_comments)),
                issue_response(drifted_final),
            ],
        ):
            drifted = review_context.collect("owner/repo", pr_context(), discussion_refs=("#2",))

        self.assertTrue(drifted["references_complete"])
        self.assertEqual(drifted["issues"][0]["read_status"], "read_failed")
        self.assertIn("changed", drifted["issues"][0]["diagnostic"].lower())
