---
name: worktree-rebase-merge
description: >
  Use when the user asks to commit a worktree branch, rebase it onto the
  specified target branch, resolve conflicts, then merge the branch from that
  target checkout. If no target branch is specified, default to dev.
---

# Worktree Rebase/Merge Workflow

Use this skill to finish a worktree feature branch by committing staged work,
rebasing the branch onto the target branch, then merging it from the target
branch checkout.

## Defaults

- Use the target branch explicitly named by the user. If none is named, use
  `dev`; if the local `dev` branch does not exist, stop and ask the user to
  name or create a target branch before proceeding.
- Treat the branch checked out in the current worktree as the source branch. If
  detached, create a source branch first, then continue this workflow.
- Do not fetch, pull, or push unless the user explicitly asks.
- If the source worktree has no staged changes when entering the commit step,
  run `git add .` once before deciding whether there is anything to commit.
- Outside that automatic empty-staging-area pass, only stage files explicitly
  selected by the user, files already staged for the commit workflow, or
  resolved conflict files during rebase and merge.

## Initial Checks

Before changing Git state:

1. Run `git branch --show-current`, `git branch --list <target-branch>`,
   `git status --short`, and `git worktree list`.
2. If detached, run the detached source branch setup below first. Stop only if
   the source branch is still missing, the resolved target branch is missing, or
   the source branch is the same as the target branch. If the missing target is
   the fallback `dev`, tell the user that the local `dev` branch does not exist
   and stop before proceeding.
3. Locate the target branch checkout from `git worktree list`. If the target
   branch is checked out in another worktree, use that path for the final
   merge instead of switching the current worktree to the target branch.

## Detached Source Branch Setup

Run this only when `git branch --show-current` returns no branch name.

- Infer the branch topic from the user request, current status or diff, and, if
  needed, the current `git log -1 --format=%s` subject.
- Name the branch with an Angular-style type and kebab-case slug:
  `<type>/<kebab-slug>`.
- If that branch name already exists, append an incrementing numeric suffix
  until it is unique.
- Run `git switch -c <branch-name>`, then use that branch as the source branch.

## Commit Source Branch

- If staged changes exist, use the `git-commit` skill and follow its staged-only
  approval workflow exactly.
- If no staged changes exist, run `git add .` once, then rerun
  `git status --short` and inspect the staged diff. If files were staged, use
  the commit skill and follow its staged-only approval workflow exactly.
- If `git add .` still leaves no staged changes, continue only if there is no
  commit needed; otherwise stop and report that there is nothing to commit.
- After any commit, rerun `git status --short`. Do not start the rebase while
  the source worktree still has uncommitted changes unless the user explicitly
  decides how to handle them.

## Rebase Onto Target

From the source branch worktree, run `git rebase <target-branch>`.

When conflicts occur:

- Inspect `git status --short` and the conflicted files before editing.
- Resolve conflicts semantically using the current code and docs. Do not choose
  `--ours` or `--theirs` wholesale unless the user asked for that outcome or
  the conflict is clearly mechanical.
- Stage only resolved conflict files, then run `git rebase --continue`.
- If a conflict requires a product decision or cannot be resolved safely, stop
  and ask the user.

After the rebase completes, run `git status --short` and `git diff --check`.
Run broader validation only when the touched code or repository rules require
it.

## Merge From Target Checkout

Before merging:

1. Confirm the rebased source branch worktree is clean.
2. Confirm the target branch worktree is clean.
3. Move to the target branch checkout path found from `git worktree list`, or
   switch to the target branch in the current worktree only if it is not already
   checked out elsewhere.

Run `git merge <source-branch>` using Git's default merge behavior. Do not force
`--no-ff`, squash, rebase again, or push unless the user explicitly asks.

If merge conflicts occur, resolve them with the same conflict rules as the
rebase step, stage only resolved conflict files, and run `git merge --continue`.

## Final Response

Report the source branch, target branch, target worktree path, commit or merge
result, and final clean status. If the workflow created a source branch from
detached HEAD, report the generated branch name. State clearly when no push was
performed.
