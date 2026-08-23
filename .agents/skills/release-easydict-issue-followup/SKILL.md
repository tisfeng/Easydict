---
name: release-easydict-issue-followup
description: >
  Plan, apply, or resume Easydict GitHub issue notifications and closures after
  a verified version publish. Use for release-to-PR-to-issue follow-up, including
  existing weak PR references; not for building or publishing the app itself.
---

# Release Easydict Issue Follow-up

Handle the issue stage after an Easydict GitHub Release is publicly available.
Discover issue references only from PRs listed in that Release, associate every
user-visible issue with its PR, publish one version notification, close resolved
open issues, and emit a fixed Markdown summary.

## Authorization boundary

- `plan` is read-only. It may query GitHub and write ignored local state, but it
  never comments on or closes an issue.
- `apply` and `resume` mutate GitHub only when the user explicitly requests that
  action for a concrete version, or when `release-easydict` delegates `apply`
  after the same request successfully publishes that version.
- Do not publish, edit, delete, or change the prerelease state of a GitHub
  Release. This skill owns only issue follow-up.
- Do not ask the user to classify individual issues. Apply the policy below and
  stop before mutation when required evidence is missing or invalid.

## Supported actions

- `plan <version>`: regenerate candidates and decisions from current GitHub
  evidence, write a fresh read-only action plan, render the fixed summary, then
  stop.
- `apply <version>`: perform the complete `plan` behavior first, then execute
  that fresh plan. A prior `plan` invocation is optional and is never trusted as
  the execution source.
- `resume <version>`: reuse the frozen candidates and decisions from an
  interrupted `apply`, refresh current issue state, and retry only operations
  that are still incomplete.

Default to the Release's actual channel. A published prerelease is `beta`; a
published non-prerelease is `stable`. Reject a caller-supplied channel that does
not match GitHub.

## Required workflow

Read [references/decision-policy.md](references/decision-policy.md) before
creating decisions and [references/commands.md](references/commands.md) before
running the helper.

### `plan`

1. Require a published GitHub Release for the exact version and capture its PR
   entries with the parent skill's `release_content.py capture` helper.
2. Run `release_issues.py collect` to fetch every listed merged PR, resolve weak
   same-repository issue references, and exclude entities that are PRs.
3. Inspect every candidate against every source PR. Write exactly one validated
   schema-v2 decision per candidate. A fixing association defaults to
   `resolved`; use `not_resolved` only with explicit negative evidence and its
   GitHub URL. Reopen history is irrelevant.
4. Run `release_issues.py plan`. Save both JSON and Markdown output under the
   isolated state directory, report the fixed three categories, and stop.

### `apply`

1. Repeat the full `plan` collection and decision process against current
   GitHub state, replacing an older unexecuted plan.
2. Freeze the resulting candidates, decisions, and plan as one execution batch.
3. Run `release_issues.py apply` without `--execute` as a deterministic local
   validation, then run the same command with `--execute`.
4. The helper posts at most one marker-bearing notification per version. It
   closes every currently open issue whose fixing PR is resolved, including an
   issue that was previously closed and reopened.
5. Verify the final per-issue results and report the generated Markdown summary.

### `resume`

1. Require an existing schema-v2 batch under the state directory. Never import
   or overwrite legacy issue state stored directly in `state/`.
2. Validate the frozen source and decisions, then rerun `release_issues.py apply
   --execute` with those files.
3. Existing release markers prevent duplicate comments. Current open state,
   not reopen history or prior local `closed` flags, determines whether the
   helper closes an issue.

## State

Use `.tmp/release/<version>/state/issue-followup/` exclusively:

- `release-content.json`: current published Release and exact PR entries.
- `candidates.json`: frozen PR, reference, issue, and comment snapshot.
- `decisions.json`: validated per-PR associations and resolution decisions.
- `plan.json`: deterministic current execution batch.
- `summary.md`: fixed three-category Markdown report.
- `actions.json`: per-issue remote progress for safe retry.

Schema v1 files directly under `.tmp/release/<version>/state/` are legacy audit
data. Do not reuse, migrate, or delete them automatically.

## Fixed report contract

Always render these headings in this order, including `- 无` for an empty group:

1. `关闭 issue 并已通知`
2. `仅发通知`
3. `未关闭的相关 issue`

Every listed issue and PR must be a Markdown link. The third group must contain
a concrete reason derived from the validated decision. Rejected number
collisions and unrelated references remain in `plan.json` machine audit only;
do not expose additional user-visible categories.

## Failure behavior

- A collection, decision, or plan failure performs no GitHub mutation.
- An `apply` failure preserves the published Release and all completed issue
  actions. Report that publishing succeeded but issue follow-up is incomplete,
  then provide `$release-easydict-issue-followup resume <version>`.
- Never roll back a Release, comment, or issue close from this skill.
