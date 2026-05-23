---
name: review-pr
description: >
  Prepare a GitHub pull request branch locally, add the contributor fork as a
  remote when missing, and produce a rigorous code review based on the PR
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
- Name the contributor remote exactly as the PR head repository owner login.
- Do not overwrite, delete, rename, rebase, reset, or force-update an existing
  local branch.
- Do not push anything while preparing or reviewing the PR.
- Do not stash or discard local changes automatically. Stop and ask the user if
  the worktree is dirty before preparing or switching branches.
- If a remote with the intended contributor name already exists but points to a
  different repository, stop and ask the user how to proceed.
- Do not review from the PR description alone. Inspect the linked issues,
  changed files, actual diff, and relevant surrounding code.
- Follow the repository's normal review stance: lead with PR context, then
  findings. Prioritize bugs and regressions, include file and line references,
  then list open questions, verification, and a short summary.

## Step 1: Resolve PR Metadata and Remote

Collect PR metadata with GitHub CLI before changing branches:

```bash
gh pr view <pr-ref> \
  --json number,title,url,body,baseRefName,headRefName,headRepository,headRepositoryOwner,closingIssuesReferences
```

Extract these fields:

- `headRepositoryOwner.login`, for the remote name.
- `headRepository.name`, for the fork repository name.
- `headRefName`, for the PR branch name.
- `baseRefName`, for the base branch used during diff review.
- `closingIssuesReferences`, for issue context.

If the contributor remote is missing, add it as:

```bash
git remote add <head-owner> https://github.com/<head-owner>/<head-repo>.git
```

If it already exists and points to the same repository, reuse it.

## Step 2: Fetch and Switch to the PR Branch

Prefer the bundled helper script for branch preparation:

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

After it finishes, verify the checkout:

```bash
git branch --show-current
git status --short
git branch -vv
```

If the branch is dirty, detached, missing upstream, or not named exactly like
the PR head branch, stop and fix that state before reviewing.

## Step 3: Review Context

Read PR context and issue context first:

```bash
gh pr view <pr-ref> \
  --comments \
  --json number,title,url,body,baseRefName,headRefName,files,commits,closingIssuesReferences,comments,reviews
```

For every linked issue in `closingIssuesReferences`, inspect the issue body and
comments:

```bash
gh issue view <issue-url-or-number> --comments
```

Then inspect the code changes against the PR base branch. Fetch the base branch
from the base repository remote if necessary, then compare with three-dot diff:

```bash
git fetch origin <base-branch>
git diff --stat origin/<base-branch>...HEAD
git diff --name-status origin/<base-branch>...HEAD
git diff origin/<base-branch>...HEAD
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
gh pr checks <pr-ref>
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
- [P0-P3] [path:line] Describe each issue, trigger condition, risk, and
  suggested change.

## Open Questions
- List correctness-affecting questions, or say clearly that there are no
  meaningful open questions.

## Verification
- List commands and checks performed, or explain why validation was not run.

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
