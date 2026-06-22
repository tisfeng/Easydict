---
name: review-pr
description: >
  Prepare a GitHub pull request branch locally, add the contributor fork as a
  remote when missing, optionally create a local merged review branch against
  the latest base branch, and produce a rigorous code review based on the PR
  description, linked issues, and actual code changes.
---

# Review PR Workflow

Use this skill when the user asks to review a GitHub pull request, check out a
PR branch locally, or prepare a review from a PR link such as
`tisfeng/Easydict#1173` or `https://github.com/tisfeng/Easydict/pull/1173`.
If the PR reference is missing or ambiguous, ask for it before changing Git
state.

Accepted PR references:

- GitHub URL: `https://github.com/<base-owner>/<base-repo>/pull/<number>`
- Shorthand: `<base-owner>/<base-repo>#<number>`
- PR number only, when the current checkout belongs to the target repository

## Guardrails

- Start with `git status --short --branch`; stop and ask before switching or
  preparing branches when the worktree has uncommitted changes.
- Do not overwrite, delete, rename, rebase, reset, force-update, stash, or
  discard local branches or changes.
- Do not push while preparing, merging, resolving conflicts, or reviewing
  unless the user explicitly asks for a push.
- Name the contributor remote exactly as the PR head repository owner login.
  If that remote name already points elsewhere, stop and ask.
- Keep the normal local branch name exactly the same as the PR head branch
  name.
- For latest-base conflict or update review, use the local-only branch
  `review/pr-<number>-merge-<head-short-sha>` and merge the latest base into
  it. Do not use rebase for remote collaboration PRs.
- Resolve merge conflicts semantically after reading the conflicting code and
  surrounding context. Do not mechanically choose ours/theirs.
- Do not review from the PR description alone. Inspect linked issues, changed
  files, actual diff, relevant surrounding code, and CI state.

## Workflow

### 1. Collect PR Metadata

Normalize GitHub URLs and `<owner>/<repo>#<number>` shorthands to
`<number> --repo <owner>/<repo>` when running manual `gh` commands.

```bash
git status --short --branch
gh pr view <number> [--repo <base-owner>/<base-repo>] \
  --json number,title,url,body,baseRefName,headRefName,headRefOid,headRepository,headRepositoryOwner,closingIssuesReferences
```

Record the head owner, fork repository, head branch, head SHA, base branch, PR
URL, and linked issues. Let the helper script add remotes, fetch branches, and
set upstream tracking in the normal path.

### 2. Choose Branch Preparation Path

Inspect mergeability before branch preparation:

```bash
gh pr view <number> [--repo <base-owner>/<base-repo>] \
  --json mergeable,mergeStateStatus,isDraft,state,updatedAt,headRefOid,baseRefOid
```

Use the latest-base merge path when the user asks to update to latest base or
resolve conflicts, or when GitHub reports `mergeable: CONFLICTING` or
`mergeStateStatus: DIRTY`. Otherwise, start with the normal helper path:

```bash
bash .agents/skills/review-pr/scripts/prepare-pr-branch.sh <pr-ref>
```

If GitHub reports an unknown or clean merge state, fetch the latest base after
normal preparation and check whether the PR already contains it:

```bash
git merge-base --is-ancestor <base-remote>/<base-branch> HEAD
```

If that check fails, use the latest-base merge helper instead. Treat
`baseRefName` as the target branch; do not hard-code `dev`.

```bash
bash .agents/skills/review-pr/scripts/prepare-pr-branch.sh --merge-latest <pr-ref>
```

The merge helper creates `review/pr-<number>-merge-<head-short-sha>` from the PR
head, fetches the PR base, runs `git merge --no-edit <base-remote>/<base-branch>`,
and never pushes.

### 3. Handle Merge Conflicts

If the merge helper stops with conflicts, inspect the actual conflict before
editing:

```bash
git status --short
git diff --name-only --diff-filter=U
git diff --cc
```

After semantic conflict resolution, stage only resolved conflict files and
finish the merge:

```bash
git add <resolved-files>
git commit --no-edit
```

Stop and report a blocker if a conflict requires a product decision or cannot
be resolved safely from local code and PR context. Do not present a complete
review from a partially merged tree.

### 4. Verify Checkout And Review Context

After preparation, verify the local state:

```bash
git branch --show-current
git status --short
git branch -vv
```

For normal preparation, require a clean branch named exactly like the PR head
branch with upstream set to `<owner>/<branch>`. For latest-base merge
preparation, require a clean local review branch named
`review/pr-<number>-merge-<head-short-sha>`.

Read PR and issue context before reviewing code:

```bash
gh pr view <number> [--repo <base-owner>/<base-repo>] \
  --comments \
  --json number,title,url,body,baseRefName,headRefName,files,commits,closingIssuesReferences,comments,reviews
gh issue view <issue-url-or-number> --comments
```

Confirm the base repository remote before using `origin`. Fetch the true base
branch, then inspect the diff and surrounding code:

```bash
git fetch <base-remote> <base-branch>
git diff --stat <base-remote>/<base-branch>...HEAD
git diff --name-status <base-remote>/<base-branch>...HEAD
git diff <base-remote>/<base-branch>...HEAD
```

Use `rg` for surrounding source, tests, configuration, generated files, and
documentation. Do not run `xcodebuild` during PR review unless the user
explicitly asks for a local build. Inspect PR checks when validation status
matters:

```bash
gh pr checks <number> [--repo <base-owner>/<base-repo>]
```

Run lightweight local checks such as `git diff --check` when relevant.

## Review Focus

Check whether the implementation actually solves the PR description and linked
issues. Prioritize bugs, regressions, edge cases, concurrency issues,
persistence mistakes, localization gaps, platform-version problems, API
contract drift, missing verification, and unrelated churn.

## Output Format

Write the final review in the user's preferred system language unless the user
asks otherwise. Preferred system language means the first language in macOS
`AppleLanguages`; if it cannot be read, use the language from the current
conversation.

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
- State whether the latest-base merge path was triggered. If it was, list the
  local review branch name, conflict files, conflict resolution status, and
  confirm that no push was performed.
- If merge conflicts could not be resolved safely, report that blocker here and
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
