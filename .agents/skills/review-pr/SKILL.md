---
name: review-pr
description: >
  Prepare a GitHub pull request branch locally, add the contributor fork as a
  remote when missing, optionally create a local rebased review branch against
  the latest base branch, and produce a rigorous code review based on the PR
  description, linked issues, and actual code changes.
---

# Review PR Workflow

Use this skill when the user asks to review a GitHub pull request, check out a
PR branch locally, or prepare a review from a PR link such as
`tisfeng/Easydict#1173` or `https://github.com/tisfeng/Easydict/pull/1173`.

## Required Input

The user must provide one PR reference:

- GitHub URL: `https://github.com/<base-owner>/<base-repo>/pull/<number>`
- Shorthand: `<base-owner>/<base-repo>#<number>`
- PR number only, when the current checkout belongs to the target repository

If the PR reference is missing or ambiguous, ask for it before changing Git
state.

## Hard Rules

- Keep the local branch name exactly the same as the PR head branch name.
- Exception: when using the latest-base rebase review path, use the local
  review branch name `review/pr-<number>-<head-short-sha>` instead of the PR
  head branch name. This avoids clobbering local branches when the PR head is
  named like `dev`.
- Name the contributor remote exactly as the PR head repository owner login.
- Do not overwrite, delete, rename, rebase, reset, or force-update an existing
  local branch.
- Do not push anything while preparing, rebasing, resolving conflicts, or
  reviewing the PR unless the user explicitly asks for a push.
- Do not stash or discard local changes automatically. Stop and ask the user if
  the worktree is dirty before preparing or switching branches.
- If a remote with the intended contributor name already exists but points to a
  different repository, stop and ask the user how to proceed.
- Resolve rebase conflicts semantically after reading the conflicting code and
  surrounding context. Do not mechanically choose ours/theirs.
- Do not review from the PR description alone. Inspect the linked issues,
  changed files, actual diff, and relevant surrounding code.
- Follow the repository's normal review stance: lead with PR context, then
  findings. Prioritize bugs and regressions, include file and line references,
  then list open questions, verification, and a short summary.

## Step 1: Check Worktree and Resolve PR Metadata

Check the current worktree before changing Git state:

```bash
git status --short --branch
```

If the worktree has uncommitted changes, stop and ask the user before preparing
or switching branches.

Collect PR metadata with GitHub CLI before branch preparation. For a GitHub URL
or `<owner>/<repo>#<number>` shorthand, convert it to `<number> --repo
<owner>/<repo>` when running manual `gh` commands. For example,
`owner/repo#123` becomes `gh pr view 123 --repo owner/repo`:

```bash
gh pr view <number> [--repo <base-owner>/<base-repo>] \
  --json number,title,url,body,baseRefName,headRefName,headRefOid,headRepository,headRepositoryOwner,closingIssuesReferences
```

Extract these fields:

- `headRepositoryOwner.login`, for the remote name.
- `headRepository.name`, for the fork repository name.
- `headRefName`, for the PR branch name.
- `headRefOid`, for the local rebased review branch suffix.
- `baseRefName`, for the base branch used during diff review.
- `closingIssuesReferences`, for issue context.

Do not add or update the contributor remote manually in the normal path. Let the
helper script prepare the remote, fetch, local branch, and upstream tracking.

## Step 2: Decide Whether To Rebase Latest Base

Before branch preparation, inspect the PR's merge state:

```bash
gh pr view <number> [--repo <base-owner>/<base-repo>] \
  --json mergeable,mergeStateStatus,isDraft,state,updatedAt,headRefOid,baseRefOid
```

Use the latest-base rebase review path when any of these are true:

- The user explicitly asks to rebase, update to latest `dev`, or resolve
  conflicts.
- `mergeable` is `CONFLICTING`.
- `mergeStateStatus` is `DIRTY`.

When one of those conditions is true, do not run the normal helper first. This
matters when the PR head branch is named like the local base branch, such as
`dev`.

If GitHub reports an unknown or clean mergeability state, use the normal helper
first, fetch the latest base branch, then check whether the prepared PR branch
already contains the latest base:

```bash
git merge-base --is-ancestor <base-remote>/<base-branch> HEAD
```

If that check fails, run the latest-base rebase helper from the clean prepared
PR branch. Treat `baseRefName` as the latest target branch; do not hard-code
`dev`.

## Step 3: Prepare the PR Branch

Use the bundled helper script as the default branch preparation path when the
latest-base rebase path is not needed:

```bash
bash .agents/skills/review-pr/scripts/prepare-pr-branch.sh <pr-ref>
```

The helper script:

- Parses a GitHub PR URL, `<owner>/<repo>#<number>`, or PR number.
- Reads the PR head owner, fork repository, and branch from `gh pr view`.
- Adds the contributor remote only when missing.
- Fetches the exact PR head branch into `refs/remotes/<owner>/<branch>`.
- Creates or switches to a local branch whose name exactly matches the PR head
  branch, and skips switching when that branch is already current.
- Sets the local branch upstream to `<owner>/<branch>`.
- Uses fast-forward-only integration when the local branch already exists.

When the latest-base rebase path is needed, use:

```bash
bash .agents/skills/review-pr/scripts/prepare-pr-branch.sh --rebase-latest <pr-ref>
```

The rebase helper:

- Fetches the exact PR head branch and latest PR base branch.
- Creates a local-only branch named `review/pr-<number>-<head-short-sha>` from
  the PR head.
- Stops if that local review branch already exists.
- Rebases the local review branch onto `<base-remote>/<base-branch>`.
- Never pushes to the contributor remote.

If the rebase stops with conflicts, inspect:

```bash
git status --short
git diff --name-only --diff-filter=U
git diff --cc
```

Resolve conflicts semantically by reading the conflicting files, relevant
surrounding code, tests, configuration, generated files, and documentation.
Stage only resolved conflict files, then continue:

```bash
git add <resolved-files>
git rebase --continue
```

Stop and report a blocker if a conflict requires a product decision or cannot be
resolved safely from local code and PR context. Do not present a complete review
from a partially rebased tree.

Use manual remote, fetch, and switch commands only as a fallback when the helper
script is unavailable or fails for a reason unrelated to PR state. In fallback
mode, normalize URL and shorthand PR refs the same way as Step 1, add the
contributor remote only when missing, verify any existing same-name remote points
to the expected fork, fetch the exact head branch, and then prepare either the
normal PR branch or the `review/pr-<number>-<head-short-sha>` rebased review
branch according to the same rules above.

After it finishes, verify the checkout:

```bash
git branch --show-current
git status --short
git branch -vv
```

For normal preparation, if the branch is dirty, detached, missing upstream, or
not named exactly like the PR head branch, stop and fix that state before
reviewing. For the latest-base rebase path, require the clean local review
branch `review/pr-<number>-<head-short-sha>` after rebase completion.

## Step 4: Review Context

Read PR context and issue context first, using the normalized PR number and
`--repo` arguments from Step 1 when needed:

```bash
gh pr view <number> [--repo <base-owner>/<base-repo>] \
  --comments \
  --json number,title,url,body,baseRefName,headRefName,files,commits,closingIssuesReferences,comments,reviews
```

For every linked issue in `closingIssuesReferences`, inspect the issue body and
comments:

```bash
gh issue view <issue-url-or-number> --comments
```

Then inspect the code changes against the PR base branch. Use `origin` as
`<base-remote>` only after confirming it points to the PR base repository. If it
does not, use the correct base repository remote or stop and ask the user.
Fetch the base branch from the base repository remote if necessary. After a
normal preparation, compare the PR branch against the base remote with a
three-dot diff. After a latest-base rebase preparation, compare the local
rebased review branch against the latest fetched base remote:

```bash
git fetch <base-remote> <base-branch>
git diff --stat <base-remote>/<base-branch>...HEAD
git diff --name-status <base-remote>/<base-branch>...HEAD
git diff <base-remote>/<base-branch>...HEAD
```

Read relevant surrounding source files, tests, configuration, generated files,
and documentation before making claims. Use `rg` for fast code search.

## Review Focus

Check the PR against the actual problem it claims to solve:

- Does the implementation fully address the PR description and linked issues?
- Are there behavior regressions, edge cases, concurrency issues, persistence
  mistakes, localization gaps, or platform-version problems?
- Are public contracts, model names, defaults, migrations, and UI states still
  coherent?
- Are tests or manual verification sufficient for the changed behavior?
- Does the code match local project patterns, naming, style, and architecture?
- Are unrelated refactors, generated churn, or accidental changes present?

Do not run `xcodebuild` during PR review unless the user explicitly asks for a
local build. When validation status matters, inspect PR checks instead:

```bash
gh pr checks <number> [--repo <base-owner>/<base-repo>]
```

Always run lightweight local checks such as `git diff --check` when they are
relevant.

## Output Format

Write the final review in the user's preferred system language unless the user
asks otherwise.

Preferred system language means the first language in macOS `AppleLanguages`.
Read it with `defaults read -g AppleLanguages` and use the first list entry.
If the current agent environment cannot read that value, write in the language
the user is already using in the current conversation.

Keep section headings, `PR Context` subheadings, and priority labels exactly as
written. Use this structure exactly:

```markdown
## PR Context

**Purpose and Scope**

Describe what the PR is trying to achieve, which issue or workflow it targets,
and the boundary of the change.

**Key Changes**

Describe the main implementation changes and the important code paths touched.

**Review Focus**

Describe the expected impact, important risks, compatibility concerns, or areas
reviewers should inspect.

---

## Findings
- [P1] path:line - Describe each issue, trigger condition, risk, and suggested
  change.
- If there are no findings, say so clearly.

## Open Questions
- List correctness-affecting questions, or say clearly that there are no
  meaningful open questions.

## Verification
- List commands and checks performed, or explain why validation was not run.
- State whether the latest-base rebase path was triggered. If it was, list the
  local review branch name, conflict files, conflict resolution status, and
  confirm that no push was performed.
- If rebase conflicts could not be resolved safely, report that blocker here and
  do not claim that a full review was completed.

## Summary
Short neutral summary of the overall review result without repeating the PR
context.
```

Build `PR Context` from the inspected PR title and body, linked issues, actual
diff, and relevant surrounding code. Do not merely restate the PR description.
Write one natural paragraph of 2-4 sentences under each subheading.

Priority values:

- `P0`: data loss, crashes, security flaws, or broken core workflows.
- `P1`: likely user-visible regression or incorrect behavior.
- `P2`: edge-case bug, missing compatibility, or incomplete issue coverage.
- `P3`: maintainability, clarity, or test/documentation gap worth fixing.
