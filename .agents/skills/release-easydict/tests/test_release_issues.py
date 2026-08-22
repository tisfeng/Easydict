from __future__ import annotations

import importlib.util
from pathlib import Path
import unittest


SKILL_ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = SKILL_ROOT / "scripts" / "release_issues.py"
SPEC = importlib.util.spec_from_file_location("release_issues", SCRIPT_PATH)
assert SPEC is not None and SPEC.loader is not None
release_issues = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(release_issues)


def issue_payload(number: int, state: str = "open") -> dict[str, object]:
    return {
        "number": number,
        "title": f"Issue {number}",
        "body": "Expected release behavior",
        "state": state,
        "state_reason": None,
        "url": f"https://github.com/tisfeng/Easydict/issues/{number}",
        "created_at": "2026-07-01T00:00:00Z",
        "updated_at": "2026-08-01T00:00:00Z",
        "closed_at": None,
        "labels": [],
        "comments": [],
        "reopened_events": [],
    }


class ReleaseIssueTests(unittest.TestCase):
    def test_extracts_existing_weak_reference_forms(self) -> None:
        text = """Related to #1201 and tisfeng/Easydict#1254.
See https://github.com/tisfeng/Easydict/issues/1229#issuecomment-1.
Ignore other/repo#99 and https://github.com/other/repo/issues/98.
"""

        references = release_issues.extract_text_references(
            text,
            "tisfeng/Easydict",
            "pr_body",
        )

        self.assertEqual(
            sorted(reference["issue_number"] for reference in references),
            [1201, 1229, 1254],
        )

    def test_build_candidates_aggregates_prs_and_skips_pr_entities(
        self,
    ) -> None:
        prs = [
            {
                "number": 1203,
                "title": "Add shortcut",
                "body": "Related: #1234 and #9999",
                "mergedAt": "2026-08-01T00:00:00Z",
                "url": "https://github.com/tisfeng/Easydict/pull/1203",
                "closingIssuesReferences": [],
                "commits": [],
                "files": [],
            },
            {
                "number": 1212,
                "title": "Restore focus",
                "body": "See tisfeng/Easydict#1234",
                "mergedAt": "2026-08-02T00:00:00Z",
                "url": "https://github.com/tisfeng/Easydict/pull/1212",
                "closingIssuesReferences": [],
                "commits": [],
                "files": [],
            },
        ]

        def loader(repository: str, number: int) -> dict[str, object] | None:
            self.assertEqual(repository, "tisfeng/Easydict")
            return None if number == 9999 else issue_payload(number)

        payload = release_issues.build_candidates(
            "tisfeng/Easydict",
            "2.22.0",
            prs,
            issue_loader=loader,
        )

        self.assertEqual(len(payload["candidates"]), 1)
        candidate = payload["candidates"][0]
        self.assertEqual(candidate["issue_number"], 1234)
        self.assertEqual(candidate["source_prs"], [1203, 1212])
        self.assertEqual(
            {reference["pr_number"] for reference in candidate["references"]},
            {1203, 1212},
        )

    def candidates(self) -> dict[str, object]:
        payload: dict[str, object] = {
            "schema_version": 1,
            "repository": "tisfeng/Easydict",
            "version": "2.22.0",
            "generated_at": "2026-08-23T00:00:00Z",
            "prs": [],
            "candidates": [
                {
                    "issue_number": 1201,
                    "source_prs": [1212],
                    "references": [],
                    "issue": issue_payload(1201),
                }
            ],
        }
        payload["source_sha256"] = release_issues.stable_hash(payload)
        return payload

    def decision(
        self,
        candidates: dict[str, object],
        *,
        relationship: str = "target",
        completion: str = "resolved",
        action: str = "notify_on_release",
    ) -> dict[str, object]:
        return {
            "schema_version": 1,
            "source_sha256": candidates["source_sha256"],
            "decisions": [
                {
                    "issue_number": 1201,
                    "relationship": relationship,
                    "completion": completion,
                    "decision": action,
                    "language": "en",
                    "source_prs": [1212],
                    "positive_evidence": ["The released PR covers the issue."],
                    "counter_evidence": [],
                    "reason": "The two release gates pass.",
                }
            ],
        }

    def test_two_gate_policy_accepts_only_complete_target_issue(self) -> None:
        candidates = self.candidates()
        decisions = self.decision(candidates)

        result = release_issues.validate_decisions(candidates, decisions)

        self.assertEqual(result[1201]["decision"], "notify_on_release")

    def test_two_gate_policy_rejects_partial_issue_notification(self) -> None:
        candidates = self.candidates()
        decisions = self.decision(candidates, completion="partial")

        with self.assertRaisesRegex(
            release_issues.ReleaseIssueError,
            "two-gate policy",
        ):
            release_issues.validate_decisions(candidates, decisions)

    def test_post_publish_refresh_cannot_promote_skipped_issue(self) -> None:
        frozen_candidates = self.candidates()
        previous = self.decision(
            frozen_candidates,
            relationship="related",
            completion="partial",
            action="skip",
        )
        candidates = self.candidates()
        candidates["previous_source_sha256"] = frozen_candidates["source_sha256"]
        candidates["source_sha256"] = release_issues.stable_hash(candidates)
        refreshed = self.decision(candidates)

        with self.assertRaisesRegex(
            release_issues.ReleaseIssueError,
            "illegally promoted",
        ):
            release_issues.validate_decisions(candidates, refreshed, previous)

    def test_post_publish_refresh_rejects_unrelated_previous_snapshot(self) -> None:
        frozen_candidates = self.candidates()
        previous = self.decision(
            frozen_candidates,
            relationship="related",
            completion="partial",
            action="skip",
        )
        candidates = self.candidates()
        candidates["previous_source_sha256"] = "different-source"
        candidates["source_sha256"] = release_issues.stable_hash(candidates)
        refreshed = self.decision(
            candidates,
            relationship="related",
            completion="partial",
            action="skip",
        )

        with self.assertRaisesRegex(
            release_issues.ReleaseIssueError,
            "frozen candidate snapshot",
        ):
            release_issues.validate_decisions(candidates, refreshed, previous)

    def test_decisions_cannot_add_unknown_issue(self) -> None:
        candidates = self.candidates()
        decisions = self.decision(candidates)
        fabricated = dict(decisions["decisions"][0])
        fabricated["issue_number"] = 9999
        decisions["decisions"] = [fabricated]

        with self.assertRaisesRegex(
            release_issues.ReleaseIssueError,
            "unknown issue",
        ):
            release_issues.validate_decisions(candidates, decisions)

    def test_decisions_reject_tampered_candidate_snapshot(self) -> None:
        candidates = self.candidates()
        decisions = self.decision(candidates)
        candidates["candidates"][0]["issue"]["title"] = "Tampered"

        with self.assertRaisesRegex(
            release_issues.ReleaseIssueError,
            "integrity check",
        ):
            release_issues.validate_decisions(candidates, decisions)

    def test_beta_comments_include_update_setting_in_both_languages(self) -> None:
        english = release_issues.release_comment(
            "2.22.0",
            "beta",
            "https://example.com/release",
            "en",
            "resolved",
        )
        chinese = release_issues.release_comment(
            "2.22.0",
            "beta",
            "https://example.com/release",
            "zh-Hans",
            "implemented",
        )

        self.assertIn("Include Beta versions", english)
        self.assertIn("包括 Beta 版本", chinese)
        self.assertIn("easydict-release-notification:2.22.0", english)

    def test_reopened_issue_is_detected_without_local_action_state(self) -> None:
        issue = issue_payload(1201)
        issue["reopened_events"] = [
            {"created_at": "2026-08-23T02:00:00Z", "actor": "reporter"}
        ]
        marker_comment = {
            "body": release_issues.marker_for("2.22.0"),
            "created_at": "2026-08-23T01:00:00Z",
        }

        self.assertTrue(
            release_issues.was_reopened_after_marker(issue, marker_comment)
        )

        issue["reopened_events"] = [
            {"created_at": "2026-08-23T00:00:00Z", "actor": "reporter"}
        ]
        self.assertFalse(
            release_issues.was_reopened_after_marker(issue, marker_comment)
        )


if __name__ == "__main__":
    unittest.main()
