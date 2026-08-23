---
name: release-easydict
description: >
  Orchestrate Easydict macOS draft, publish, release, and resume workflows by
  reusing scripts/release/release-easydict.sh, curating English GitHub release
  notes and a highlight title, then delegating published issue follow-up to
  release-easydict-issue-followup. Use for an Easydict version release or
  release recovery, not for release planning alone.
---

# Release Easydict

Use the existing release scripts as the build, notarization, packaging, Git,
GitHub Release, appcast, and verification engine. This skill curates Release
content and delegates the independent post-publish issue stage.

## Authorization boundary

- A planning, explanation, inspection, or proposal request stays read-only.
- Run remote mutations only when the current user request explicitly asks to
  `draft`, `publish`, `release`, or `resume` a concrete version.
- Once the user has explicitly requested that action, do not ask them to choose
  translations, a highlight, or issue actions. Make the content decisions below
  and let the issue follow-up skill apply its own deterministic policy.
- Never use the existing one-shot `release` action directly. For this skill,
  `release` means `draft`, content curation, then `publish`, so the public
  Release cannot precede curation.
- Do not switch or modify the user's current checkout. The repository scripts
  already release from committed local `dev` through isolated worktrees.

## Supported actions

- `draft <version>`: create or recover the verified Draft, curate its English
  body/title, then stop.
- `draft <version> --replace-draft`: discard the latest matching unpublished
  Draft and its Tag only after rebuilding the same version from synchronized
  local `dev`; curate and freeze only the newly created Draft.
- `publish <version>`: curate an existing verified Draft, publish and verify it,
  then delegate a fresh issue follow-up `apply` batch.
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
   When the user explicitly requests `--replace-draft`, run:

   ```bash
   ./scripts/release/release-easydict.sh draft <version> \
     --replace-draft [--channel <channel>]
   ```

   Do not add this flag implicitly. It is valid only when the existing Release
   is the newest GitHub Release entry, remains a Draft on the same channel, has
   matching local and remote Tag identity, has matching local release state,
   and is absent from the public appcast. Never combine it with
   `--build-number`.
3. Capture the GitHub-generated body with
   `.agents/skills/release-easydict/scripts/release_content.py capture`.
   Create a curated JSON file that translates every change title into concise
   English and selects one real PR as the highlight. Do not change PR numbers,
   links, authors, contributors, or the changelog range.
4. Run `.agents/skills/release-easydict/scripts/release_content.py render`, then
   apply the validated title and notes to the Draft with
   `.agents/skills/release-easydict/scripts/release_content.py apply --execute`.
   Fetch the Draft again and require an exact title/body match.
5. For `draft`, report the curated Draft and stop without publishing or touching
   issues.
6. For `publish` or `release`, run:

   ```bash
   ./scripts/release/release-easydict.sh publish <version> [--channel <channel>]
   ```

   Do not continue until this command and its remote verification succeed.
7. After the publish command and all remote verification succeed, invoke
   `$release-easydict-issue-followup apply <version>`. This delegated action
   performs its own fresh read-only plan immediately before issue mutation; do
   not require or reuse a prior standalone plan.
8. Report the Release URL, title, channel, notes path, the delegated fixed
   three-category issue summary, underlying run IDs, and any resumable state
   path.

## State files

Keep deterministic orchestration state in `.tmp/release/<version>/state/`:

- `release-content-source.json`: captured GitHub Draft and exact PR entries.
- `release-content-curated.json`: English titles, highlight PR, and Release
  title selected from the captured source.
- `release-notes-en.md`: validated rendered notes applied to the Draft.

The delegated issue skill owns `.tmp/release/<version>/state/issue-followup/`.
Legacy schema-v1 issue files directly under `state/` remain audit data and are
never reused by the new stage.

For `--replace-draft`, old content and issue files are rollback data only. The
repository workflow temporarily moves the complete old state aside, chooses
`max(old Draft build, current project build, public appcast build) + 1`, and
rebuilds from synchronized committed local `dev`. Capture and curate content
only after the new Draft is verified. Never copy old curated notes or issue
follow-up state into the new state. A new replacement request must stop when
an unfinished replacement exists; use the asc run ID with `resume` instead.

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

- A content validation failure leaves the GitHub Release as a Draft.
- A `--replace-draft` build or notarization failure leaves the old remote Draft
  and Tag untouched. A later transition failure preserves the temporary local
  rollback backup and resumes only incomplete markers. After the new Draft is
  verified, the workflow deletes that temporary backup automatically.
- A publish failure leaves issue actions untouched and uses the asc run ID for
  recovery.
- A delegated issue follow-up failure does not roll back an already published
  Release. Report “发布成功，但 issue 后续处理未完成” and continue with
  `$release-easydict-issue-followup resume <version>`.
- The issue follow-up skill owns comment idempotency, current-open-state closing,
  and its fixed Markdown report contract. Do not reproduce those rules here.
