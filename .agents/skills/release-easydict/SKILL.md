---
name: release-easydict
description: >
  Orchestrate Easydict macOS draft, publish, release, and resume workflows by
  reusing scripts/release/release-easydict.sh, curating English GitHub release
  notes and a highlight title, and notifying or closing only verified resolved
  issues after a successful publish. Use for an Easydict version release or
  release recovery, not for release planning alone.
---

# Release Easydict

Use the existing release scripts as the build, notarization, packaging, Git,
GitHub Release, appcast, and verification engine. This skill adds content and
issue orchestration around those scripts.

## Authorization boundary

- A planning, explanation, inspection, or proposal request stays read-only.
- Run remote mutations only when the current user request explicitly asks to
  `draft`, `publish`, `release`, or `resume` a concrete version.
- Once the user has explicitly requested that action, do not ask them to choose
  translations, a highlight, or issue actions. Make the decisions below and
  stop safely on validation failure.
- Never use the existing one-shot `release` action directly. For this skill,
  `release` means `draft`, content curation, issue decision freeze, then
  `publish`, so the public Release cannot precede curation.
- Do not switch or modify the user's current checkout. The repository scripts
  already release from committed local `dev` through isolated worktrees.

## Supported actions

- `draft <version>`: create or recover the verified Draft, curate its English
  body/title, freeze issue decisions, then stop.
- `publish <version>`: curate and freeze an existing verified Draft, publish it,
  refresh the frozen issue evidence, and apply verified issue notifications.
- `release <version>`: run the `draft` behavior followed by the `publish`
  behavior.
- `resume <version-or-run-id>`: inspect skill state and the asc run state,
  continue only the incomplete stage, and preserve idempotency markers.

Default to the repository's `beta` channel unless the user explicitly requests
`stable`. Carry the same channel through every underlying command.

## Required workflow

1. Read `scripts/release/README.md` and verify the requested action, version,
   channel, current release state, and available `.tmp/release/<version>/`
   state. Keep a record of the underlying asc run ID. Read
   [references/commands.md](references/commands.md) before invoking helpers.
2. For a new Draft, run:

   ```bash
   ./scripts/release/release-easydict.sh draft <version> [--channel <channel>]
   ```

   If the Draft already exists, verify it instead of deleting or recreating it.
3. Capture the GitHub-generated body with
   `.agents/skills/release-easydict/scripts/release_content.py capture`.
   Create a curated JSON file that translates every change title into concise
   English and selects one real PR as the highlight. Do not change PR numbers,
   links, authors, contributors, or the changelog range.
4. Run `.agents/skills/release-easydict/scripts/release_content.py render`, then
   apply the validated title and notes to the Draft with
   `.agents/skills/release-easydict/scripts/release_content.py apply --execute`.
   Fetch the Draft again and require an exact title/body match.
5. Run `.agents/skills/release-easydict/scripts/release_issues.py collect` to
   discover same-repository issue candidates from every PR in the Release
   Notes. Read
   [references/issue-decision-policy.md](references/issue-decision-policy.md),
   inspect the issue and PR evidence, and write one decision for every
   candidate. Validate it with
   `.agents/skills/release-easydict/scripts/release_issues.py validate` and
   freeze both files under `.tmp/release/<version>/state/`.
6. For `draft`, report the curated Draft and frozen issue decision summary, then
   stop without publishing or touching issues.
7. For `publish` or `release`, run:

   ```bash
   ./scripts/release/release-easydict.sh publish <version> [--channel <channel>]
   ```

   Do not continue until this command and its remote verification succeed.
8. Refresh the live state and comments of only the frozen issue candidates.
   Re-evaluate negative evidence and allow decisions only to remain unchanged
   or be demoted to `skip`; never add a new issue after publish.
9. Validate the refreshed decisions with the frozen pre-publish decisions as
   `--previous-decisions`. Preview
   `.agents/skills/release-easydict/scripts/release_issues.py apply`, inspect the
   machine-readable plan, then run it with `--execute`. Pass the frozen
   decisions as `--previous-decisions` again. It comments once and closes only
   open issues whose validated decision is `notify_on_release`.
10. Report the Release URL, title, channel, notes path, issue actions, skipped
    candidates with reasons, underlying run IDs, and any resumable state path.

## State files

Keep deterministic orchestration state in `.tmp/release/<version>/state/`:

- `release-content-source.json`: captured GitHub Draft and exact PR entries.
- `release-content-curated.json`: English titles, highlight PR, and Release
  title selected from the captured source.
- `release-notes-en.md`: validated rendered notes applied to the Draft.
- `issue-candidates.json`: frozen pre-publish weak-reference candidates.
- `issue-decisions.json`: frozen pre-publish two-gate decisions.
- `issue-candidates-refreshed.json` and `issue-decisions-refreshed.json`: the
  post-publish snapshots; the decision file may only demote prior actions.
- `issue-actions.json`: per-issue comment and close progress for safe resume.

Never overwrite the frozen candidate or decision files during refresh. Reuse
existing matching state on `resume`; reject mismatched repository, version,
source hash, PR set, or issue set instead of regenerating past a completed
stage.

## Content decisions

- Translate only the human PR title portion of each generated change entry.
  Preserve valid English titles when they are already concise.
- Choose the highlight in this order: security/data-loss/crash fix, major
  user-facing feature, major user-facing fix, smaller product improvement, then
  maintenance only when no product change exists.
- Use `<version> <emoji> <type>: <concise English summary>`, normally `✨ feat`,
  `🐞 fix`, `🔒 security`, `🚀 perf`, or `🔧 chore`.
- Do not select docs, generated assets, dependency bumps, or internal refactors
  while a user-facing feature or fix exists.

## Failure and resume

- A content or decision validation failure leaves the GitHub Release as a Draft.
- A publish failure leaves issue actions untouched and uses the asc run ID for
  recovery.
- An issue follow-up failure does not roll back an already published Release.
  Preserve the action state and retry only the incomplete issue operation.
- An existing release comment marker prevents duplicate comments. If an issue
  was reopened after a completed notification, never close it again.
