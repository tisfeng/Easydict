---
name: release-easydict
description: >
  Orchestrate Easydict macOS draft, publish, release, and resume workflows,
  curate English GitHub Release content, and plan, apply, or resume
  post-publish issue follow-up from released PR associations. Use for concrete
  Easydict release operations and issue-followup actions, not general release
  design discussions.
---

# Release Easydict

Use the repository release scripts as the build, notarization, packaging, Git,
GitHub Release, appcast, and verification engine. This skill adds deterministic
Release content and post-publish Issue orchestration around those scripts.

## Action routing

Release lifecycle actions:

- `draft <version>`: create or recover a verified Draft, curate its English
  body and highlight title, then stop.
- `draft <version> --replace-draft`: safely rebuild the newest matching
  unpublished Draft from synchronized committed local `dev`.
- `publish <version>`: curate an existing verified Draft, publish and verify it,
  then run the internal Issue follow-up `apply` behavior.
- `release <version>`: perform the skill's `draft` behavior followed by its
  `publish` behavior.
- `resume <version-or-run-id>`: continue only the incomplete release lifecycle
  stage using existing skill and asc state.

Read `scripts/release/README.md` and
[references/commands.md](references/commands.md) for these actions.

Post-publish Issue actions use an explicit namespace:

- `issue-followup plan <version>`
- `issue-followup apply <version>`
- `issue-followup resume <version>`

Read [references/issue-followup.md](references/issue-followup.md) and
[references/issue-followup-policy.md](references/issue-followup-policy.md) for
these actions. The namespace keeps Issue recovery distinct from asc workflow
`resume`.

## Authorization boundary

- A planning, explanation, inspection, or proposal request stays read-only.
- `issue-followup plan` may query GitHub and write ignored local state, but it
  never comments on or closes an Issue.
- Run remote mutations only when the user explicitly requests `draft`,
  `publish`, `release`, release `resume`, `issue-followup apply`, or
  `issue-followup resume` for a concrete version or run.
- An explicitly requested `publish` or `release` also authorizes its internal
  `issue-followup apply` stage after that same version passes remote release
  verification. Do not request another confirmation for translations,
  highlights, comments, or closing resolved Issues.
- Never use the repository script's one-shot `release` action directly. For
  this skill, `release` means skill-managed Draft creation, content curation,
  publish, remote verification, then Issue follow-up.
- Do not switch or modify the user's current checkout. Repository scripts
  release committed local `dev` through isolated worktrees.

## Release workflow

Default to the repository's `beta` channel unless the user explicitly requests
`stable`. Carry the same channel through every underlying release command.

1. Verify the requested version, channel, current GitHub Release state,
   `.tmp/release/<version>/` state, and relevant asc run ID.
2. For a new Draft, run:

   ```bash
   ./scripts/release/release-easydict.sh draft <version> [--channel <channel>]
   ```

   If the Draft already exists, verify it instead of deleting or recreating it.
   Use the following only when the user explicitly requests replacement:

   ```bash
   ./scripts/release/release-easydict.sh draft <version> \
     --replace-draft [--channel <channel>]
   ```

   The existing Release must be the newest GitHub entry, remain a Draft on the
   same channel, match local and remote Tag identity and local release state,
   and be absent from the public appcast. Never combine `--replace-draft` with
   `--build-number`.
3. Capture GitHub-generated notes with
   `.agents/skills/release-easydict/scripts/release_content.py capture`. Create
   a curated JSON document that
   translates every human change title into concise English and selects one
   real PR as the highlight. Preserve PR numbers, links, authors, contributors,
   and the changelog range.
4. Run the same helper's `render` action, preview its `apply` action, then run
   that apply command with `--execute`. Fetch the Draft again and require an
   exact title and body match.
5. For `draft`, report the curated Draft and stop without publishing or touching
   Issues.
6. For `publish` or `release`, run:

   ```bash
   ./scripts/release/release-easydict.sh publish <version> [--channel <channel>]
   ```

   Do not continue until publishing, appcast installation, and remote
   verification all succeed.
7. Continue inside this skill with the `issue-followup apply <version>` behavior
   from [references/issue-followup.md](references/issue-followup.md). It creates
   a fresh plan immediately before mutation and never relies on a prior
   standalone `plan`.
8. Report the Release URL, title, channel, notes path, fixed three-category Issue
   summary, underlying run IDs, and resumable state paths.

## State

Release content state remains under `.tmp/release/<version>/state/`:

- `release-content-source.json`
- `release-content-curated.json`
- `release-notes-en.md`

Issue state remains isolated under
`.tmp/release/<version>/state/issue-followup/` and retains schema v2. Files
stored directly under `state/` by the older schema-v1 implementation remain
audit data and are never reused, migrated, or deleted automatically.

For `--replace-draft`, old content and Issue files are rollback data only. The
repository workflow temporarily moves the complete old state aside, chooses
`max(old Draft build, current project build, public appcast build) + 1`, and
rebuilds from synchronized committed local `dev`. Capture and curate only after
the new Draft is verified. Never copy old curated notes or Issue state into the
new generation. Resume an unfinished replacement by asc run ID instead of
starting another replacement.

## Content decisions

- Translate only the human PR title portion of each generated change entry;
  preserve concise English titles.
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
  and Tag untouched. Later transition failures preserve local rollback data;
  successful verification removes that temporary backup.
- A publish failure leaves Issue actions untouched and uses the asc run ID for
  recovery.
- An Issue follow-up failure never rolls back an already published Release,
  comment, or Issue close. Report “发布成功，但 issue 后续处理未完成” and use:

  ```text
  $release-easydict issue-followup resume <version>
  ```

- Comment idempotency, current-open-state closing, fixed reporting, and Issue
  decision validation are defined by the Issue follow-up references and
  enforced by
  `.agents/skills/release-easydict/scripts/release_issues.py`.
