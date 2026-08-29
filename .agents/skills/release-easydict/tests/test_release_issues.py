from __future__ import annotations

import argparse
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


SKILL_ROOT = Path(__file__).resolve().parents[1]
REPOSITORY_ROOT = SKILL_ROOT.parents[2]
SCRIPT_PATH = SKILL_ROOT / "scripts" / "release_issues.py"
PR_TEMPLATE_PATH = REPOSITORY_ROOT / ".github" / "pull_request_template.md"
SPEC = importlib.util.spec_from_file_location("release_issues", SCRIPT_PATH)
assert SPEC is not None and SPEC.loader is not None
release_issues = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(release_issues)


def issue_payload(
    number: int,
    state: str = "open",
    *,
    marker: bool = False,
) -> dict[str, object]:
    comments: list[dict[str, object]] = []
    if marker:
        comments.append(
            {
                "author": "tisfeng",
                "body": release_issues.marker_for("2.22.0"),
                "created_at": "2026-08-23T01:00:00Z",
                "url": f"https://github.com/tisfeng/Easydict/issues/{number}#issuecomment-1",
            }
        )
    return {
        "number": number,
        "title": f"Issue {number}",
        "body": "Expected release behavior",
        "state": state,
        "state_reason": None,
        "url": f"https://github.com/tisfeng/Easydict/issues/{number}",
        "created_at": "2026-07-01T00:00:00Z",
        "updated_at": "2026-08-23T00:00:00Z",
        "closed_at": None,
        "labels": [],
        "comments": comments,
    }


def release_payload() -> dict[str, object]:
    return {
        "tag_name": "2.22.0",
        "url": "https://github.com/tisfeng/Easydict/releases/tag/2.22.0",
        "name": "2.22.0 release",
        "channel": "beta",
    }


class ReleaseIssueFollowupTests(unittest.TestCase):
    def candidates(self) -> dict[str, object]:
        payload: dict[str, object] = {
            "schema_version": 2,
            "repository": "tisfeng/Easydict",
            "version": "2.22.0",
            "generated_at": "2026-08-23T00:00:00Z",
            "prs": [
                {
                    "number": 1212,
                    "title": "Restore input focus",
                    "body": "Related to #1201",
                    "merged_at": "2026-08-01T00:00:00Z",
                    "url": "https://github.com/tisfeng/Easydict/pull/1212",
                    "commits": [],
                    "files": [],
                    "references": [],
                }
            ],
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
        relationship: str = "fixes",
        resolution: str = "resolved",
        outcome: str = "fixed",
        negative_evidence: list[dict[str, str]] | None = None,
    ) -> dict[str, object]:
        return {
            "schema_version": 2,
            "source_sha256": candidates["source_sha256"],
            "decisions": [
                {
                    "issue_number": 1201,
                    "source_prs": [1212],
                    "associations": [
                        {
                            "pr_number": 1212,
                            "relationship": relationship,
                            "evidence": [
                                {
                                    "url": "https://github.com/tisfeng/Easydict/pull/1212",
                                    "summary": "The PR addresses the reported behavior.",
                                }
                            ],
                        }
                    ],
                    "resolution": resolution,
                    "outcome": outcome,
                    "language": "zh-Hans",
                    "negative_evidence": negative_evidence or [],
                    "reason": "The released PR resolves the reported behavior.",
                }
            ],
        }

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

    def test_linked_issue_section_marks_supported_reference_forms(self) -> None:
        text = """## 变更说明 / Summary

Background: #1199

## 关联 Issue / Linked Issues

- #1201
- https://github.com/tisfeng/Easydict/issues/1229
- tisfeng/Easydict#1254

### Notes

- #1206

## 验证 / Verification

Regression context: #1300
"""

        references = release_issues.extract_text_references(
            text,
            "tisfeng/Easydict",
            "pr_body",
        )
        kinds_by_issue = {
            reference["issue_number"]: reference["kind"]
            for reference in references
        }

        self.assertEqual(
            kinds_by_issue,
            {
                1199: "local_number",
                1201: "linked_issue",
                1206: "linked_issue",
                1229: "linked_issue",
                1254: "linked_issue",
                1300: "local_number",
            },
        )

    def test_linked_issue_template_placeholder_is_not_a_reference(self) -> None:
        text = """## 关联 Issue / Linked Issues

- #<issue-number>
- https://github.com/tisfeng/Easydict/issues/<issue-number>
- tisfeng/Easydict#<issue-number>
"""

        references = release_issues.extract_text_references(
            text,
            "tisfeng/Easydict",
            "pr_body",
        )

        self.assertEqual(references, [])

    def test_repository_pr_template_contains_no_issue_candidate(self) -> None:
        template = PR_TEMPLATE_PATH.read_text(encoding="utf-8")

        references = release_issues.extract_text_references(
            template,
            "tisfeng/Easydict",
            "pr_body",
        )

        self.assertEqual(references, [])
        self.assertEqual(len(release_issues.linked_issue_ranges(template)), 1)

    def test_linked_issue_formats_share_one_candidate(self) -> None:
        prs = [
            {
                "number": 1212,
                "title": "Restore focus",
                "body": """## 关联 Issue / Linked Issues

- #1201
- https://github.com/tisfeng/Easydict/issues/1201
""",
                "mergedAt": "2026-08-02T00:00:00Z",
                "url": "https://github.com/tisfeng/Easydict/pull/1212",
                "closingIssuesReferences": [],
                "commits": [],
                "files": [],
            }
        ]

        payload = release_issues.build_candidates(
            "tisfeng/Easydict",
            "2.22.0",
            prs,
            issue_loader=lambda _repository, number: issue_payload(number),
        )

        self.assertEqual(len(payload["candidates"]), 1)
        self.assertEqual(payload["candidates"][0]["issue_number"], 1201)
        self.assertEqual(
            {
                reference["kind"]
                for reference in payload["candidates"][0]["references"]
            },
            {"linked_issue"},
        )

    def test_build_candidates_aggregates_prs_and_skips_pr_entities(self) -> None:
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

    def test_fixing_pr_defaults_to_resolved_without_reopen_exception(self) -> None:
        candidates = self.candidates()
        decisions = self.decision(candidates)

        result = release_issues.validate_decisions(candidates, decisions)

        self.assertEqual(result[1201]["resolution"], "resolved")

    def test_not_resolved_requires_explicit_linked_negative_evidence(self) -> None:
        candidates = self.candidates()
        decisions = self.decision(
            candidates,
            resolution="not_resolved",
        )

        with self.assertRaisesRegex(
            release_issues.ReleaseIssueError,
            "needs explicit evidence",
        ):
            release_issues.validate_decisions(candidates, decisions)

        decisions = self.decision(
            candidates,
            resolution="not_resolved",
            negative_evidence=[
                {
                    "url": "https://github.com/tisfeng/Easydict/issues/1201#issuecomment-2",
                    "summary": "A post-merge reproduction confirms the bug remains.",
                }
            ],
        )
        result = release_issues.validate_decisions(candidates, decisions)
        self.assertEqual(result[1201]["resolution"], "not_resolved")

    def test_related_only_issue_is_not_applicable(self) -> None:
        candidates = self.candidates()
        decisions = self.decision(
            candidates,
            relationship="related",
            resolution="not_applicable",
            outcome="not_applicable",
        )

        result = release_issues.validate_decisions(candidates, decisions)

        self.assertEqual(result[1201]["resolution"], "not_applicable")

    def test_associations_must_cover_every_source_pr(self) -> None:
        candidates = self.candidates()
        candidates["prs"].append(
            {
                "number": 1222,
                "title": "Second fix",
                "url": "https://github.com/tisfeng/Easydict/pull/1222",
            }
        )
        candidates["candidates"][0]["source_prs"] = [1212, 1222]
        candidates["source_sha256"] = release_issues.stable_hash(candidates)
        decisions = self.decision(candidates)
        decisions["decisions"][0]["source_prs"] = [1212, 1222]

        with self.assertRaisesRegex(
            release_issues.ReleaseIssueError,
            "cover every source PR",
        ):
            release_issues.validate_decisions(candidates, decisions)

    def test_plan_lists_open_resolved_issue_with_markdown_links(self) -> None:
        candidates = self.candidates()
        decisions = self.decision(candidates)
        plan = release_issues.build_plan(
            candidates,
            decisions,
            release_payload(),
            issue_loader=lambda _repo, number: issue_payload(number, "open"),
        )

        self.assertEqual(plan["items"][0]["category"], "close_and_notify")
        summary = release_issues.render_summary(plan)
        self.assertIn("[#1201](https://github.com/tisfeng/Easydict/issues/1201)", summary)
        self.assertIn("[PR #1212](https://github.com/tisfeng/Easydict/pull/1212)", summary)
        self.assertLess(
            summary.index("## 关闭 issue 并已通知"),
            summary.index("## 仅发通知"),
        )
        self.assertLess(
            summary.index("## 仅发通知"),
            summary.index("## 未关闭的相关 issue"),
        )

    def test_related_issue_uses_only_the_fixed_unclosed_category(self) -> None:
        candidates = self.candidates()
        decisions = self.decision(
            candidates,
            relationship="related",
            resolution="not_applicable",
            outcome="not_applicable",
        )
        plan = release_issues.build_plan(
            candidates,
            decisions,
            release_payload(),
            issue_loader=lambda _repo, number: issue_payload(number),
        )

        self.assertEqual(plan["items"][0]["category"], "unresolved_related")
        summary = release_issues.render_summary(plan)
        self.assertEqual(summary.count("## "), 3)
        self.assertIn("未执行关闭", summary)

    def test_rejected_reference_is_machine_audit_only(self) -> None:
        candidates = self.candidates()
        decisions = self.decision(
            candidates,
            relationship="rejected",
            resolution="not_applicable",
            outcome="not_applicable",
        )
        plan = release_issues.build_plan(
            candidates,
            decisions,
            release_payload(),
            issue_loader=lambda _repo, number: issue_payload(number),
        )

        self.assertEqual(plan["items"], [])
        self.assertEqual(plan["audit"][0]["relationship"], "rejected")
        summary = release_issues.render_summary(plan)
        self.assertNotIn("#1201", summary)
        self.assertEqual(summary.count("- 无"), 3)

    def test_open_issue_with_existing_marker_still_needs_close(self) -> None:
        candidates = self.candidates()
        decisions = self.decision(candidates)
        plan = release_issues.build_plan(
            candidates,
            decisions,
            release_payload(),
            issue_loader=lambda _repo, number: issue_payload(
                number,
                "open",
                marker=True,
            ),
        )

        item = plan["items"][0]
        self.assertFalse(item["comment_needed"])
        self.assertTrue(item["close_needed"])
        self.assertEqual(item["category"], "close_and_notify")

    def test_closed_resolved_issue_only_needs_notification(self) -> None:
        candidates = self.candidates()
        decisions = self.decision(candidates)
        plan = release_issues.build_plan(
            candidates,
            decisions,
            release_payload(),
            issue_loader=lambda _repo, number: issue_payload(number, "closed"),
        )

        item = plan["items"][0]
        self.assertTrue(item["comment_needed"])
        self.assertFalse(item["close_needed"])
        self.assertEqual(item["category"], "notify_only")
        summary = release_issues.render_summary(plan)
        self.assertIn("## 仅发通知", summary)
        self.assertIn("计划发布 2.22.0 版本通知", summary)

    def test_apply_does_not_require_an_existing_plan_and_reuses_marker(self) -> None:
        candidates = self.candidates()
        decisions = self.decision(candidates)
        issue = issue_payload(1201, "open", marker=True)
        commands: list[list[str]] = []

        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            candidates_path = root / "candidates.json"
            decisions_path = root / "decisions.json"
            release_path = root / "release.json"
            plan_path = root / "plan.json"
            summary_path = root / "summary.md"
            state_path = root / "actions.json"
            candidates_path.write_text(json.dumps(candidates), encoding="utf-8")
            decisions_path.write_text(json.dumps(decisions), encoding="utf-8")
            release_path.write_text(
                json.dumps(
                    {
                        "tagName": "2.22.0",
                        "isDraft": False,
                        "isPrerelease": True,
                        "url": "https://github.com/tisfeng/Easydict/releases/tag/2.22.0",
                        "name": "2.22.0 release",
                    }
                ),
                encoding="utf-8",
            )
            args = argparse.Namespace(
                repo="tisfeng/Easydict",
                version="2.22.0",
                channel=None,
                candidates=candidates_path,
                decisions=decisions_path,
                plan=plan_path,
                summary=summary_path,
                state=state_path,
                release_json=release_path,
                execute=True,
            )

            with (
                patch.object(release_issues, "fetch_issue", return_value=issue),
                patch.object(
                    release_issues,
                    "run_command",
                    side_effect=lambda command: commands.append(command),
                ),
            ):
                release_issues.apply_command(args)

            self.assertTrue(plan_path.exists())
            self.assertTrue(summary_path.exists())
            self.assertEqual(len(commands), 1)
            self.assertEqual(commands[0][1:3], ["issue", "close"])
            result_plan = json.loads(plan_path.read_text(encoding="utf-8"))
            self.assertTrue(result_plan["executed"])
            self.assertEqual(
                result_plan["items"][0]["result"]["comment"],
                "already_present",
            )

    def test_beta_comments_include_update_setting_in_both_languages(self) -> None:
        english = release_issues.release_comment(
            "2.22.0",
            "beta",
            "https://example.com/release",
            "en",
            "fixed",
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


if __name__ == "__main__":
    unittest.main()
