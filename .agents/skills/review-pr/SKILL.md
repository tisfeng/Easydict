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
  name. The only automatic exception is the collision fallback branch
  `review/pr-<number>-<head-short-sha>` created when the exact name is
  unusable.
- Treat the PR metadata `headRefOid` as the only valid normal-review HEAD. A
  same-named local branch may fast-forward to that SHA, but it must not contain
  additional local commits or diverge from it.
- On a branch-name collision, automatically fall back to the local review
  branch `review/pr-<number>-<head-short-sha>` and continue. Never bypass by
  checking out a remote-tracking ref, entering detached HEAD, or reviewing the
  fetched ref in place. Keep the colliding branch untouched.
- Stop instead of falling back only when the worktree is dirty, the
  contributor remote points elsewhere, the fetched head differs from
  `headRefOid`, or an existing review branch is incompatible.
- Do not create any other differently named local branch unless the user
  explicitly requests an isolated worktree or latest-base integration review.
- If normal preparation refuses an existing branch for any other reason, do not
  bypass it; preserve the branch and ask how to proceed.
- In explicit worktree mode, use `review/pr-<number>-<head-short-sha>` for a
  normal review and `review/pr-<number>-merge-<head-short-sha>` for a
  latest-base review. Keep the worktree under
  `../.review-pr-worktrees/<repo>/pr-<number>[-merge]-<head-short-sha>`.
- Keep the prepared branch or worktree after review so the user can run and
  debug it. Never remove a review worktree automatically.
- For an explicitly requested latest-base conflict or update review, use the
  local-only branch `review/pr-<number>-merge-<head-short-sha>` and merge the
  latest base into it. Do not use rebase for remote collaboration PRs.
- Do not treat `mergeable: CONFLICTING`, `mergeStateStatus: DIRTY`, or a base
  branch that is ahead of the PR as permission to merge. These states are
  review context unless the user explicitly requests a latest-base integration
  review or conflict resolution.
- Resolve merge conflicts semantically after reading the conflicting code and
  surrounding context. Do not mechanically choose ours/theirs.
- Do not review from the PR description alone. Inspect linked issues, changed
  files, actual diff, relevant surrounding code, and CI state.
- For exact inline review context, unresolved comments, or a `discussion_r...`
  id, use `gh api` / GraphQL so `isResolved`, `isOutdated`, path, and line stay
  visible. Do not rely only on `gh pr view --json`.
- Treat every review thread with `isResolved == false` as an open review
  comment that must be enumerated and individually assessed, including comments
  from bots, comments with replies, and comments marked `isOutdated == true`.
  Never omit an open thread because it looks plausible, is automated, or is not
  independently identified as a new finding.
- Treat PR feedback as live state. Opening a PR, marking a draft ready, bot
  workflows, and manual review requests can add reviews or threads while the
  local review is in progress. Never assume the initial comment snapshot is
  still current when writing the final response.
- For every open comment assessed as `reasonable` or `partially reasonable`,
  provide a separate `Suggested Fix` grounded in the actual diff, surrounding
  code, and project patterns. Recommend the smallest concrete change that
  resolves the issue, including the affected logic, expected behavior, and
  targeted verification when relevant. This requirement applies even when the
  comment came from a bot. Keep the complete assessment and fix in
  `Open Review Comments`; do not repeat the same issue in `Findings`.
- Give every independent finding the same concrete `Suggested Fix` treatment.
  Only an issue with a distinct trigger, risk, and remediation from all open
  comments may appear in `Findings`.
- Do not use vague advice such as "fix this issue." When multiple approaches are
  valid, recommend one and state the important tradeoff. If the fix depends on
  a product decision, give conditional options and surface that decision in
  `Open Questions`.
- Treat fix suggestions as review guidance. Do not modify the PR unless the
  user explicitly asks; include a short code example only when it makes the
  proposed change materially clearer.

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

Use normal preparation for a review even when GitHub reports
`mergeable: CONFLICTING` or `mergeStateStatus: DIRTY`. Check out the PR head on
the same-named local branch, inspect the PR as submitted, and report the merge
state without changing its history.

Use the latest-base merge path only when the user explicitly asks to update to
the latest base, resolve conflicts, or review the integrated result. Before
running it, state that it will create the local-only branch
`review/pr-<number>-merge-<head-short-sha>` and a local merge commit. If the
request did not already explicitly include one of those actions, stop and ask
before creating the branch.

If the PR head branch name collides with the base branch, a protected local
branch name, or an existing same-named branch with a different upstream, the
helper automatically creates the local review branch
`review/pr-<number>-<head-short-sha>` and continues. The colliding branch is
never rebound, renamed, or deleted. The helper reuses an existing
`review/pr-<number>-<head-short-sha>` only when it is clean, at `headRefOid`,
and tracking `<owner>/<branch>`; otherwise it stops and asks you to inspect or
remove it. Do not select latest-base mode solely to avoid the branch-name
collision.

After normal checkout, fetch the latest base and check whether the PR already
contains it:

```bash
git merge-base --is-ancestor <base-remote>/<base-branch> HEAD
```

If that check fails, report that the PR is behind the latest base instead of
merging automatically. When GitHub reports conflicts, use `git merge-tree` as
a read-only conflict signal when useful:

```bash
merge_base=$(git merge-base <base-remote>/<base-branch> HEAD)
git merge-tree "$merge_base" <base-remote>/<base-branch> HEAD
```

Treat `baseRefName` as the target branch; do not hard-code `dev`. Only after an
explicit latest-base request, run:

```bash
bash .agents/skills/review-pr/scripts/prepare-pr-branch.sh --merge-latest <pr-ref>
bash .agents/skills/review-pr/scripts/prepare-pr-branch.sh --worktree --merge-latest <pr-ref>
```

The merge helper creates `review/pr-<number>-merge-<head-short-sha>` from the PR
head, fetches the PR base, runs `git merge --no-edit <base-remote>/<base-branch>`,
and never pushes.

Normal preparation updates only an exact match or a branch that can fast-forward
to `headRefOid`. When an existing local PR branch is ahead of or diverged from
the fetched head, the helper automatically falls back to
`review/pr-<number>-<head-short-sha>`; it never mutates the diverged branch or
improvises a detached checkout.

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
git rev-parse HEAD
git status --short
git branch -vv
```

For normal preparation, require a clean branch named exactly like the PR head
branch with upstream set to `<owner>/<branch>`, and require `HEAD` to equal the
recorded `headRefOid`. A matching upstream alone is insufficient because the
local branch may contain commits that are not in the PR. When a collision
fallback occurred, require the clean local review branch
`review/pr-<number>-<head-short-sha>` at `headRefOid` with upstream
`<owner>/<branch>` instead. For latest-base merge preparation, require a clean
local review branch named `review/pr-<number>-merge-<head-short-sha>`.

For worktree preparation, require the reported worktree to be clean and on its
SHA-specific review branch. Require a normal worktree branch to track
`<owner>/<head-branch>`; keep a merged worktree branch local-only. Confirm the
source checkout branch, HEAD, and file status were unchanged, then run every
remaining review command with that worktree as its working directory.

Snapshot PR and issue context before reviewing code:

```bash
gh pr view <number> [--repo <base-owner>/<base-repo>] \
  --comments \
  --json number,title,url,body,baseRefName,headRefName,headRefOid,updatedAt,files,commits,closingIssuesReferences,comments,reviews
gh issue view <issue-url-or-number> --comments
```

Record `headRefOid`, `updatedAt`, the latest review `submittedAt`, and the full
inline review-thread set. The `comments` and `reviews` fields do not contain
complete inline thread content, so always use GraphQL `reviewThreads` as well.
For every thread, retain its id, `isResolved`, `isOutdated`, path, line, and all
comments with database id, URL, body, author, timestamps, and commit OID.
Paginate until `pageInfo.hasNextPage` is false instead of assuming the first
page contains every thread.

Before reviewing the diff as a whole, build an inventory of every open review
thread (`isResolved == false`). Include unresolved outdated threads and all
replies in the inventory; label `isOutdated` explicitly rather than silently
discarding the thread. Review each inventory item against the current PR head,
the changed diff, the relevant call chain, and surrounding code. The reviewer
must decide whether the comment is `reasonable`, `partially reasonable`,
`unreasonable`, `outdated/not applicable`, or requires a product decision.

For `reasonable` and `partially reasonable` comments, identify the exact
behavioral risk and provide a concrete `Suggested Fix`, expected behavior, and
targeted verification. For `unreasonable` or `outdated/not applicable`
comments, explain the code evidence that rejects or supersedes the concern.
For a product-decision comment, recommend one option, include its
`Suggested Fix`, and repeat the unresolved choice under `Open Questions`.
Assign every reviewed issue to exactly one output section. If an issue is
raised by an open review comment, keep its assessment and fix only in `Open
Review Comments`; do not repeat it in `Findings`. Reserve `Findings` for
additional issues with a distinct trigger, risk, and remediation. If the
inventory is empty, report `No open review comments` separately. If no
additional issues remain after the assignment, report `No additional findings`.

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

### 5. Refresh Live PR State Before Finalizing

Immediately before writing the final response, refresh all mutable review
state even when the initial checks were green:

```bash
gh pr view <number> [--repo <base-owner>/<base-repo>] \
  --json headRefOid,updatedAt,state,mergeStateStatus,comments,reviews
gh pr checks <number> [--repo <base-owner>/<base-repo>]
```

Repeat the same fully paginated GraphQL `reviewThreads` query used for the
initial snapshot, then compare the two snapshots, including the open-thread
inventory, comment replies, `isResolved`, and `isOutdated` state.

- If `headRefOid` changed, stop finalization, update the prepared checkout to
  the new head, inspect the new diff against the true base, and revalidate both
  earlier findings and new changes.
- If a new review, thread, reply, or resolution/outdated-state change appeared,
  read its exact content, validate it against the current head and surrounding
  code, add or update its individual entry in `Open Review Comments`, and only
  update `Findings` when the re-review identifies a distinct additional issue.
  Update `Open Questions` and `Verification` before finalizing.
  Reassess any existing item whose reply or resolution/outdated state changed.
  Treat automated and human feedback the same way.
- If analyzing new activity leaves enough time for another review to arrive,
  refresh again. Finish only when the latest snapshot contains no uninspected
  feedback.
- If the final refresh is unavailable, report that limitation and do not claim
  that every current comment or thread was inspected. A final response is
  complete only when the latest open-comment inventory has no uninspected item.

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

Keep section headings, `PR Context` subheadings, priority labels, and
`Suggested Fix` labels exactly as written. Use this structure exactly:

For `Open Review Comments`, prefer a compact summary line followed by one
Markdown card per thread. Put the comment permalink in the card title instead
of showing a long raw URL. Keep path, line, author, and status on one metadata
line; translate raw GraphQL flags such as `isResolved=false` and
`isOutdated=false` into short natural-language status labels in the preferred
output language. Use separate paragraphs for the issue, evidence/impact,
assessment, and fix. Include a `Thread Replies` block only when replies exist.
Do not pack all metadata and prose into one list item, and do not use a table or
large quote block for review content.

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

## Open Review Comments

Open threads: <count> · Reasonable: <count> · Partially reasonable: <count> · Outdated: <count>

### C1 — [Comment title](comment-permalink)

`path:line` · `author`
Status: unresolved · current

**Issue**

Summarize the comment's concern and the trigger condition.

**Evidence / Impact**

Explain the current-code evidence and the user or system impact.

**Assessment**

`reasonable`

**Suggested Fix:**

Describe the smallest concrete remediation, expected behavior, and targeted
verification.

**Thread Replies**

- [Author](reply-permalink): Summarize this reply. Use one bullet per reply
  and retain the reply permalink.

### C2 — [Another comment title](comment-permalink)

`path:line` · `author`
Status: unresolved · current

**Issue**

...

**Evidence / Impact**

...

**Assessment**

`outdated/not applicable`

- Explain why the current code no longer requires a change. Do not invent a
  `Suggested Fix` for this assessment.

If there are no open review threads, write `No open review comments`.

## Findings

### [P1] `path:line` — Finding title

**Evidence / Impact**

Describe the distinct trigger, risk, and impact. This must not repeat an issue
already represented in `Open Review Comments`.

**Suggested Fix:**

Describe the smallest concrete change, expected behavior, and targeted
verification.

If there are no additional issues, write `No additional findings`. Do not
duplicate an open-comment assessment or invent a second fix for it.

## Open Questions
- List correctness-affecting questions, or say clearly that there are no
  meaningful open questions.

## Verification
- List commands and checks performed, or explain why validation was not run.
- State whether local or worktree preparation was used. For local preparation,
  include the checkout branch and upstream when applicable. For worktree
  preparation, include its absolute path, review branch, upstream or local-only
  status, and confirm the source checkout remained unchanged.
- When a collision fallback was used, name the
  `review/pr-<number>-<head-short-sha>` branch and the collision reason.
- State whether the latest-base merge path was triggered. If it was, list the
  local review branch name, conflict files, conflict resolution status, and
  confirm that no push was performed.
- Report the final live-state refresh: final `headRefOid`, PR `updatedAt`, and
  whether new reviews, threads, replies, or thread-state changes appeared after
  the initial snapshot. Report the final open-comment inventory, whether any
  additional findings remain, and state that every new or changed item was
  individually assessed, or describe the remaining limitation.
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
