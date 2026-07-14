---
name: review-pr
description: >
  Prepare a GitHub pull request on a local branch by default or in an isolated
  worktree when explicitly requested, optionally merge the latest base branch,
  and produce a rigorous review from PR context and actual code changes. Use
  for local PR checkout, worktree review, parallel review, or concurrent review.
---

# Review PR Workflow

Use the local checkout by default. Use an isolated Git worktree only when the
user explicitly asks for a worktree, parallel review, or concurrent review. If
the PR reference is missing or ambiguous, ask for it before changing Git state.

Accepted PR references:

- GitHub URL: `https://github.com/<base-owner>/<base-repo>/pull/<number>`
- Shorthand: `<base-owner>/<base-repo>#<number>`
- PR number only, when the current checkout belongs to the target repository

## Guardrails

- Start with `git status --short --branch`. In default local mode, stop before
  switching branches when the checkout has uncommitted changes. Explicit
  worktree mode may proceed from a dirty checkout because it must not switch or
  modify that checkout.
- Do not overwrite, delete, rename, rebase, reset, force-update, stash, or
  discard local branches, worktrees, or changes.
- Do not push while preparing, merging, resolving conflicts, or reviewing
  unless the user explicitly asks for a push.
- Name the contributor remote exactly as the PR head repository owner login.
  If that remote name already points elsewhere, stop and ask.
- Keep the normal local branch name exactly the same as the PR head branch
  name.
- In explicit worktree mode, use `review/pr-<number>-<head-short-sha>` for a
  normal review and `review/pr-<number>-merge-<head-short-sha>` for a
  latest-base review. Keep the worktree under
  `../.review-pr-worktrees/<repo>/pr-<number>[-merge]-<head-short-sha>`.
- Keep the prepared branch or worktree after review so the user can run and
  debug it. Never remove a review worktree automatically.
- For latest-base conflict or update review, use the local-only branch
  `review/pr-<number>-merge-<head-short-sha>` and merge the latest base into
  it. Do not use rebase for remote collaboration PRs.
- Resolve merge conflicts semantically after reading the conflicting code and
  surrounding context. Do not mechanically choose ours/theirs.
- Do not review from the PR description alone. Inspect linked issues, changed
  files, actual diff, relevant surrounding code, and CI state.
- For exact inline review context, unresolved comments, or a `discussion_r...`
  id, use `gh api` / GraphQL so `isResolved`, `isOutdated`, path, and line stay
  visible. Do not rely only on `gh pr view --json`.

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

Use local branch preparation unless the user explicitly requests a worktree or
parallel review. Do not infer worktree mode only because the current checkout
is dirty. For a normal PR, run one of:

```bash
bash .agents/skills/review-pr/scripts/prepare-pr-branch.sh <pr-ref>
bash .agents/skills/review-pr/scripts/prepare-pr-branch.sh --worktree <pr-ref>
```

Use the latest-base merge path only when the user asks to update to latest base
or resolve conflicts, when GitHub reports `mergeable: CONFLICTING` or
`mergeStateStatus: DIRTY`, or when the PR head branch name collides with the
base branch or a protected local branch name. Worktree mode isolates protected
head names with its unique review branch, but does not otherwise change the
latest-base decision.

If GitHub reports an unknown or clean merge state, use normal preparation first.
After checkout, fetch the latest base and check whether the PR already contains
it:

```bash
git merge-base --is-ancestor <base-remote>/<base-branch> HEAD
```

If that check fails but the PR is otherwise clean, report that it is behind the
latest base instead of merging automatically. Treat `baseRefName` as the target
branch; do not hard-code `dev`. When latest-base merge is required, run:

```bash
bash .agents/skills/review-pr/scripts/prepare-pr-branch.sh --merge-latest <pr-ref>
bash .agents/skills/review-pr/scripts/prepare-pr-branch.sh --worktree --merge-latest <pr-ref>
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

For worktree mode, run every conflict command in the reported worktree path,
for example `git -C <worktree-path> status --short`. Do not resolve the merge
from the original checkout.

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

For worktree preparation, require the reported worktree to be clean and on its
SHA-specific review branch. Require a normal worktree branch to track
`<owner>/<head-branch>`; keep a merged worktree branch local-only. Confirm the
source checkout branch, HEAD, and file status were unchanged, then run every
remaining review command with that worktree as its working directory.

Read PR and issue context before reviewing code:

```bash
gh pr view <number> [--repo <base-owner>/<base-repo>] \
  --comments \
  --json number,title,url,body,baseRefName,headRefName,files,commits,closingIssuesReferences,comments,reviews
gh issue view <issue-url-or-number> --comments
```

For old or stale PRs, check linked issue history, later replacement PRs, and the
live base tree before deciding whether the branch should still exist. Use
`git merge-tree <merge-base> <base-remote>/<base-branch> HEAD` as a read-only
obsolescence or conflict signal when mergeability is central to the review.

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

When the user asks whether an old PR is still worth keeping, answer the
keep/modify/close decision first. Then explain the code findings that support
that decision.

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
- State whether local or worktree preparation was used. For local preparation,
  include the checkout branch and upstream when applicable. For worktree
  preparation, include its absolute path, review branch, upstream or local-only
  status, and confirm the source checkout remained unchanged.
- State whether the latest-base merge path was triggered. If it was, list the
  local review branch name, conflict files, conflict resolution status, and
  confirm that no push was performed.
- Confirm that no push was performed unless the user explicitly asked for one.
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
