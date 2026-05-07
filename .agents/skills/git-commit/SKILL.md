---
name: git-commit
description: Draft Angular-style Git commit messages from staged changes and execute `git commit` safely after explicit approval. Use for commit message generation, staged-diff review for commit wording, and Chinese previews of English commit messages.
---

# Git Commit Workflow

Generate accurate Angular-style Git commit messages from staged changes only.

## Required Workflow

Follow this sequence exactly:

1. Collect context with:
   - `git status`
   - staged raw patch command:
     `GIT_PAGER=cat git --no-pager diff --staged --no-ext-diff --no-textconv --unified=5`
   - `git branch --show-current`
   - `git log --oneline -10`
2. If there are no staged changes, run `git add .` once, then collect
   `git status` and the staged raw patch command again before continuing.
3. If there were already staged changes in step 1, do not run `git add`. Keep
   the workflow limited to the current staged scope.
4. Stop immediately if there are still no staged changes after the single
   allowed `git add .`. Ask the user to stage files first.
5. Analyze the staged diff precisely:
   - Treat the raw patch command above as the only source of truth for staged
     scope. Do not rely on external diff, textconv, or pager formatting.
   - If you need to inspect a single staged path, reuse the same command shape
     and append `-- <path>` instead of falling back to bare `git diff --staged`.
   - Identify additions, deletions, and behavior impact.
   - Infer the most accurate `type(scope): subject`.
6. Draft the commit message in English using the format rules below.
7. Prepare a Simplified Chinese preview that fully matches the English message.
8. Present the result using the output rules below and wait for explicit approval.
9. After approval, execute the commit in three separate steps:
   - Write only the English commit message to `commit_message.txt`
   - Run `git commit -F commit_message.txt`
   - Remove `commit_message.txt`

## Hard Rules

- Run `git add .` only when the initial staged diff is empty, and only once.
- Do not run `git add` when staged changes already exist.
- Do not run `git push`.
- Do not commit without explicit user authorization.
- Do not include Chinese text in the actual commit message file.
- Do not describe unstaged or unrelated changes.
- Keep the Chinese preview accurate and complete.
- A commit message is incomplete unless it includes a body explaining what changed and why.
- Every commit message is incomplete unless the body uses exactly three natural
  paragraphs.
- The three body paragraphs must cover the current context, the main change,
  and the resulting impact in that order.
- Do not chain `git commit` together with file creation or cleanup in a single shell command.

## Commit Execution Rules

- Treat `git commit` as the only step that needs repository write access. Keep message-file creation and cleanup as separate commands.
- If `git commit` fails with sandbox-style permission errors such as `Operation not permitted` while creating `.git/index.lock`, immediately rerun `git commit -F commit_message.txt` with the required escalation instead of retrying the same non-privileged command.
- When the environment is known to block writes under `.git`, prefer requesting the needed escalation for `git commit` directly after the user approves the message.
- If commit succeeds, remove `commit_message.txt` afterward. If commit fails, keep the file unless cleanup is clearly safe and intentional.

## Angular-Style Commit Format

Use this structure for every commit:

```text
type(scope): subject

First body paragraph explaining the current context or motivation.

Second body paragraph explaining the main change.

Third body paragraph explaining the result or impact.

Optional footer for breaking changes or special notes when applicable.
```

Apply these formatting rules:

- Use the standard title form: `type(scope): subject`.
- Write the `subject` as an imperative summary, start it with a lowercase letter, and do not end it with a period.
- Keep the title at or below 80 characters.
- Keep the full commit message under 600 characters.
- The `body` is required for every commit and must use exactly three short
  paragraphs separated by one blank line.
- The first paragraph should explain the current issue, context, or motivation.
- The second paragraph should explain the main change and how it responds to
  that context.
- The third paragraph should explain the result, impact, or risk reduction.
- Do not use explicit labels such as `Problem:`, `Change:`, or `Summary:`.
- Keep each paragraph concise, usually one sentence and at most two when
  needed.
- Focus on behavior and intent rather than low-level implementation minutiae.
- Use the optional `footer` only for breaking changes or special considerations.

### Three-Paragraph Body Structure

Every commit must use three short natural paragraphs in this order:

1. Describe the current background, problem, or motivation for the commit.
2. Describe the main change and how it responds to that context.
3. Summarize the result, user impact, compatibility effect, or reduced risk.

### Breaking Changes

- Mark breaking changes with `!`, with a `BREAKING CHANGE:` footer, or with
  both when the title should signal the break immediately and the footer needs
  to explain migration impact.
- Use `!` after the type or scope in the title when the incompatible change
  should be visible at a glance.
- Use a `BREAKING CHANGE:` footer when migration work, removed behavior, or
  compatibility impact needs explicit explanation.
- Keep the full commit structure intact for breaking changes: title, three
  body paragraphs, and then the optional footer. The footer explains the
  compatibility impact, but it does not replace the required body paragraphs.

## Commit Type Guidance

Choose the narrowest commit `type` that matches the staged diff:

- `feat`: introduce user-facing behavior or a new capability. Focus the three
  paragraphs on the missing capability, the feature added, and the user-facing
  benefit or rollout impact.
- `fix`: correct a bug, regression, or broken behavior. Focus the three
  paragraphs on the broken behavior, the fix approach, and the restored
  outcome or reduced risk.
- `docs`: update documentation only. Focus the three paragraphs on the reader
  gap, the documentation update, and the clarity or maintenance benefit.
- `style`: apply formatting or non-functional code style updates. Focus the
  three paragraphs on the readability issue, the style cleanup, and the
  consistency benefit.
- `refactor`: improve internal structure without changing behavior. Focus the
  three paragraphs on the structural pain point, the code reorganization, and
  the maintainability gain while preserving behavior.
- `perf`: improve performance or reduce resource usage. Focus the three
  paragraphs on the bottleneck, the optimization, and the measured or expected
  efficiency gain.
- `test`: add or adjust tests without changing production behavior. Focus the
  three paragraphs on the coverage gap, the test update, and the regression
  protection gained.
- `build`: change dependencies, packaging, or build configuration. Focus the
  three paragraphs on the build or dependency context, the configuration
  change, and the resulting build or release impact.
- `ci`: update CI workflows or automation pipelines. Focus the three
  paragraphs on the pipeline issue, the workflow change, and the resulting
  reliability or maintenance improvement.
- `chore`: make routine maintenance changes that do not fit other types. Focus
  the three paragraphs on the maintenance need, the housekeeping change, and
  the resulting repository health benefit.
- `revert`: roll back a previous change. Focus the three paragraphs on why the
  earlier change must be undone, what is being reverted, and the restored or
  stabilized state afterward.

Choose `scope` from the touched module, feature, service, or component name whenever possible. Prefer specific scopes such as `openai`, `screenshot`, or `settings` over broad labels like `app` or `misc`.

## Output and Approval Rules

- Present the result using this exact format and wait for explicit approval:

```
{English commit message}
```

```
{Simplified Chinese translation}
```

- Keep the Simplified Chinese preview aligned with the English message in
  paragraph count, paragraph order, and meaning for every commit type.
- Do not create `commit_message.txt` or run `git commit` before explicit approval.
- Write only the English message into `commit_message.txt`.

## Example

This example shows the required complete format for a compliant commit message.

```
fix(screenshot): defer overlay capture until view appears

Overlay capture started before the view hierarchy was stable, which caused a startup race and could crash screenshot translation.

Move screenshot capture out of the overlay initializer and begin it only after the view appears and layout is ready.

This restores stable screenshot translation startup and prevents the layout conflicts caused by the race.
```

```
fix(screenshot): 推迟悬浮层截图直到视图出现后再执行

悬浮层在视图层级尚未稳定时就启动截图，触发了启动阶段的竞态，并可能导致截图翻译崩溃。

将截图操作从悬浮层初始化方法中移出，改为在视图出现且布局就绪后再开始执行。

此修改恢复了截图翻译启动流程的稳定性，并避免了该竞态导致的布局冲突问题。
```
