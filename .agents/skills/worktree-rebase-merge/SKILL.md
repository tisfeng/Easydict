---
name: worktree-rebase-merge
description: >
  Use when the user asks to commit a worktree branch, rebase it onto the
  specified target branch, resolve conflicts, then merge the branch from that
  target checkout. If no target branch is specified, default to the repository
  remote default branch.
---

# Worktree Rebase/Merge Workflow

Use this skill to finish a worktree branch by committing the source branch,
rebasing it onto a target branch, then merging it from the target checkout.
Delegate source-branch commit mechanics to the `git-commit` skill.

## Defaults

- Use the user-named target branch when provided. Otherwise resolve the
  repository remote default branch.
- Resolve the remote default by preferring `origin`; if no `origin` exists and
  exactly one remote exists, use that remote. Read
  `refs/remotes/<remote>/HEAD` with
  `git symbolic-ref --quiet --short refs/remotes/<remote>/HEAD`, then strip the
  `<remote>/` prefix.
- Treat the current checkout as the source branch. If it is detached, create a
  source branch before continuing.
- Do not fetch, pull, or push unless the user explicitly asks.
- Stage only user-selected files, already staged commit files, the single
  `git-commit` empty-index `git add .` pass, or conflict resolutions.

## Preflight

- Resolve the target branch before branch checks. If remote selection is
  ambiguous, the remote HEAD is missing, or the resolved local target branch
  does not exist, stop and ask the user to name a target branch.
- Run `git branch --show-current`, `git branch --list <target-branch>`,
  `git status --short`, and `git worktree list`.
- Stop if source and target resolve to the same branch.
- Locate the target checkout from `git worktree list`. Use that path for the
  final merge when the target is already checked out elsewhere.
- For detached HEAD, infer an Angular-style `<type>/<kebab-slug>` branch name
  from the request, status/diff, or `git log -1 --format=%s`; append a numeric
  suffix if needed, then run `git switch -c <branch-name>`.

## Commit Source

- Use `git-commit` mechanics for staged source changes. Let that skill own
  staged-only scope, the one allowed empty-index `git add .` pass, message
  drafting, commit execution, permission retry, and cleanup, but this workflow
  overrides `git-commit` default-mode reporting order.
- Before creating `commit_message.txt` or running `git commit -F
  commit_message.txt`, send a normal assistant message with the fixed heading
  `提交信息预览` and a fenced `text` code block containing the full actual
  drafted commit message.
- The preview text must exactly match the later `commit_message.txt` content,
  except for Markdown code fences. It must not appear only in tool output,
  terminal output, hidden reasoning, log files, `commit_message.txt`, or final
  Git command output.
- After the body preview is visible, continue automatically unless the user
  explicitly requested confirmation, preview-only, draft-only, no-commit, or
  message changes.
- If `git-commit` reports there is no commit to make, continue only when the
  source worktree has no uncommitted changes. Otherwise stop and report the
  uncommitted state.
- Rerun `git status --short` after the commit step. Rebase only from a clean
  source worktree unless the user explicitly decides otherwise.

## Rebase

- From the source worktree, run `git rebase <target-branch>`.
- On conflicts, inspect `git status --short`, resolve semantically, stage only
  resolved files, and run `git rebase --continue`. Stop for product decisions
  or unsafe conflicts.
- After rebase, require a clean source worktree, run `git diff --check`, and run
  broader validation only when repository rules or touched code require it.

## Merge And Final Response

- Confirm both the rebased source worktree and target checkout are clean.
- Move to the target checkout found during preflight, or switch in the current
  worktree only when the target is not checked out elsewhere.
- Run `git merge <source-branch>` with default Git behavior. Do not force
  `--no-ff`, squash, rebase again, or push unless the user explicitly asks.
- On merge conflicts, use the same semantic resolution rule as rebase, then
  stage resolved files only and run `git merge --continue`.
- Report the source branch, target branch, target checkout path, commit hash,
  merge result, final clean status, any generated detached-HEAD branch name,
  and that no push was performed unless the user asked for one.
- Include a final-response `提交信息预览` fenced `text` code block with the
  actual committed message, so the preview remains visible even if intermediate
  assistant updates are collapsed.
