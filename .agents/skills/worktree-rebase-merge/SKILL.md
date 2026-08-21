---
name: worktree-rebase-merge
description: >
  Use when the user asks to finish worktree changes by attaching a detached
  checkout to an automatically named Conventional branch when needed,
  committing, rebasing onto the specified target, resolving conflicts, and
  merging from that target branch worktree. Also use it to commit changes
  already on the target branch. Default to the repository remote default
  branch.
---

# Worktree Rebase/Merge Workflow

Use this skill to finish a worktree branch by committing the source branch,
rebasing it onto a target branch, then merging it from a worktree checked out to
that target branch. When the current branch is already the resolved target
branch, skip the rebase/merge path and commit directly via the `git-commit`
skill. Delegate all source-branch and direct-commit mechanics to `git-commit`.

## Defaults

- Use the user-named target branch when provided. Otherwise resolve the
  repository remote default branch.
- Resolve the remote default by preferring `origin`; if no `origin` exists and
  exactly one remote exists, use that remote. Query the live remote HEAD with
  `git ls-remote --symref <remote> HEAD`, read the
  `ref: refs/heads/<branch> HEAD` line, then strip the `refs/heads/` prefix.
  This read-only query is not a fetch or pull.
- If the live remote HEAD query fails or has no branch ref, do not silently
  trust the cached `refs/remotes/<remote>/HEAD`. You may read that symbolic ref
  only to report a fallback candidate, then stop and ask the user to name or
  confirm the target branch.
- Treat the current checkout as the source branch. If it is detached, create a
  source branch before continuing.
- Do not fetch, pull, or push unless the user explicitly asks.
- Stage only user-selected files, already staged commit files, the single
  `git-commit` empty-index `git add .` pass, or conflict resolutions.

## Preflight

- Resolve the target branch before branch checks. If remote selection is
  ambiguous, the live remote HEAD is unavailable or unparseable, or the
  resolved local target branch does not exist, stop and ask the user to name
  or confirm a target branch.
- Run `git branch --show-current`, `git branch --list <target-branch>`,
  and `git status --short`.
- For detached HEAD, follow **Attach Detached HEAD** before selecting direct or
  normal rebase/merge mode.
- If source and target resolve to the same branch, enter direct commit mode.
- For normal rebase/merge mode, run `git worktree list`.
- Locate any existing target worktree from `git worktree list` whose branch is
  exactly `<target-branch>`. Use that path for the final merge when present.
- Do not require the user's main checkout to currently be on `<target-branch>`.
  If no worktree is already checked out to the target branch, plan to create a
  temporary target worktree for the merge step instead of switching another
  checkout's branch.
- If multiple worktrees are checked out to `<target-branch>`, use the first
  clean one. If all target worktrees are dirty, record each dirty target path
  and its `git status --short` output. Do not touch the target worktrees or stop
  yet; finish the source branch creation and source commit first, then use the
  dirty-target pause flow below.

## Attach Detached HEAD

When `git branch --show-current` is empty, create a source branch automatically
without staging files or changing the current commit:

1. Record `git rev-parse HEAD` and the exact `git status --short` output.
2. Infer the work's primary intent from the first useful source below. Inspect
   later sources only when an earlier source is empty or ambiguous:
   - staged diff;
   - unstaged diff and the contents of relevant untracked files;
   - commits in `git log <target-branch>..HEAD`.
3. If all three sources are empty, report that there is nothing to commit or
   merge and stop without creating a branch.
4. Apply the `git-commit` skill's **Branch Name Guidance** to derive the
   candidate from the evidence above. Derive the name only; do not enter that
   skill's staging or commit workflow yet.
5. Validate the candidate with
   `git check-ref-format --branch <branch-name>`.
6. Resolve local name collisions without overwriting branches:
   - If the candidate does not exist, run `git switch -c <branch-name>`.
   - If it points to the recorded detached commit and is not checked out in
     another worktree, run `git switch <branch-name>` and reuse it.
   - Otherwise, append `-2`, `-3`, and so on until an unused valid name is
     found, then run `git switch -c <numbered-branch-name>`.
   Use `git show-ref --verify` and `git worktree list --porcelain` to distinguish
   these cases. Never reset or move an existing branch.
7. Verify the selected source branch, confirm `git rev-parse HEAD` still matches
   the recorded commit, and require `git status --short` to preserve the exact
   staged, unstaged, and untracked state. Stop if attachment changes content.

Do not stage files solely to generate the branch name. Continue with the normal
commit, rebase, and merge workflow after attachment.

## Direct Target-Branch Commit

- Use direct commit mode only when the current source branch and the resolved
  target branch are the same branch.
- In direct commit mode, delegate completely to the `git-commit` skill:
  staging scope, the single empty-index `git add .` pass, message drafting,
  commit execution, permission retry, and cleanup all follow `git-commit`.
- Do not create a temporary source branch, run `git rebase`, run `git merge`,
  locate a target worktree, create a temporary target worktree, fetch, pull, or
  push.
- After the commit step, use the `git-commit` **Post-Commit Report** and state
  that no rebase, merge, or push was performed.

## Commit Source

- Use `git-commit` mechanics for staged source changes. Let that skill own
  staged-only scope, the one allowed empty-index `git add .` pass, message
  drafting, commit execution, permission retry, and cleanup. In normal
  rebase/merge mode, this workflow overrides `git-commit` default-mode
  reporting order; in direct commit mode, follow `git-commit` reporting.
- Record the source `HEAD` before the commit step. Classify the source result as
  `created-this-run` only when the commit step changes `HEAD`; otherwise, when
  the source is already committed and clean, classify it as
  `preexisting-source-commit`.
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
  source worktree has no uncommitted changes. Mark the result as
  `preexisting-source-commit`; otherwise stop and report the uncommitted state.
- Rerun `git status --short` after the commit step. Rebase only from a clean
  source worktree unless the user explicitly decides otherwise.

## Dirty Target Pause

- If preflight found only dirty worktrees for `<target-branch>`, finish the
  source commit through `git-commit` and require a clean source worktree, then
  stop before scope inspection, rebase, merge, or push.
- Never stage, commit, stash, restore, clean, or otherwise modify a dirty target
  worktree as part of this recovery path.
- Report the source branch and commit hash, every dirty target path and dirty
  file, and that the source changes are committed while the target worktrees
  remain untouched. Explicitly state that rebase, merge, and push have not run.
- Ask the user to clean the target worktree and reply `继续`. On continuation,
  rerun target resolution, `git worktree list`, and target cleanliness checks.
  Reuse the existing clean source commit unless the source gained new changes;
  if it did, commit those changes through `git-commit` before rebasing.
- If every target worktree is still dirty on continuation, report the remaining
  dirty state and pause again without creating another source commit.

## Rebase

- Before rebasing, inspect the complete integration scope with
  `git log --oneline <target-branch>..<source-branch>` and
  `git diff --stat <target-branch>...<source-branch>`.
- Compare that range with the current request and the source commits handled by
  this workflow. When the target was inferred and the range contains unrelated
  or unexpectedly broad pre-existing history, stop and ask the user to confirm
  the target branch. A successful or no-op rebase is not scope validation.
- From the source worktree, run `git rebase <target-branch>`.
- On conflicts, inspect `git status --short`, resolve semantically, stage only
  resolved files, and run `git rebase --continue`. Stop for product decisions
  or unsafe conflicts.
- After rebase, require a clean source worktree, run
  `git diff --check <target-branch>...HEAD`, and run broader validation only
  when repository rules or touched code require it.

## Merge And Final Response

- Confirm the rebased source worktree is clean.
- If an existing target worktree was found during preflight, confirm it is clean
  and run the merge from that path.
- If no existing target worktree was found, create a temporary target worktree
  outside the repository, such as
  `/tmp/worktree-rebase-merge-<repo>-<target>-<pid>`, with
  `git worktree add <temporary-path> <target-branch>`. Confirm the temporary
  worktree is on `<target-branch>` and clean before merging.
- Do not switch the user's main checkout merely to reach `<target-branch>`.
- Do not update the target branch with low-level ref commands such as
  `git update-ref`, `git branch -f`, or other worktree-bypassing operations.
  Use a real target worktree so Git keeps the branch, index, and files in an
  understandable state.
- Run `git merge <source-branch>` with default Git behavior. Do not force
  `--no-ff`, squash, rebase again, or push unless the user explicitly asks.
- On merge conflicts, use the same semantic resolution rule as rebase, then
  stage resolved files only and run `git merge --continue`. If the conflict
  happens in a temporary target worktree, keep that worktree and report its path
  for follow-up resolution instead of deleting it.
- After a successful merge in a temporary target worktree, remove it with
  `git worktree remove <temporary-path>`.
- Report the source branch, target branch, target checkout path, source commit
  count, target merge mode (`existing-target-worktree` or
  `temporary-target-worktree`), temporary target worktree path when one was
  created, merge result, and final clean status. For an attached checkout, also
  report the original detached commit and whether the source branch was created
  or reused. State that no push was performed unless the user asked for one.
- If the integration contains exactly one source commit, finish with the
  `git-commit` **Post-Commit Report** for that commit. Use `已创建提交` for
  `created-this-run`; for `preexisting-source-commit`, use
  `本次未创建新提交；合并的是源分支已有提交`.
- If the integration contains multiple source commits, list each full hash and
  subject, then use the statistics script with `--range
  <target-commit>...<source-commit>` to report aggregate total, code, and
  documentation text changes. Do not present one commit message as the message
  for the whole range.
