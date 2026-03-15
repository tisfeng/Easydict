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
   - `git diff --staged`
   - `git branch --show-current`
   - `git log --oneline -10`
2. Stop immediately if there are no staged changes. Ask the user to stage files first.
3. Analyze the staged diff precisely:
   - Identify additions, deletions, and behavior impact.
   - Infer the most accurate `type(scope): subject`.
4. Draft the commit message in English using the format rules below.
5. Prepare a Simplified Chinese preview that fully matches the English message.
6. Present the result using the output rules below and wait for explicit approval.
7. After approval, execute the commit in three separate steps:
   - Write only the English commit message to `commit_message.txt`
   - Run `git commit -F commit_message.txt`
   - Remove `commit_message.txt`

## Hard Rules

- Do not run `git add`.
- Do not run `git push`.
- Do not commit without explicit user authorization.
- Do not include Chinese text in the actual commit message file.
- Do not describe unstaged or unrelated changes.
- Keep the Chinese preview accurate and complete.
- Do not chain `git commit` together with file creation or cleanup in a single shell command.

## Commit Execution Rules

- Treat `git commit` as the only step that needs repository write access. Keep message-file creation and cleanup as separate commands.
- If `git commit` fails with sandbox-style permission errors such as `Operation not permitted` while creating `.git/index.lock`, immediately rerun `git commit -F commit_message.txt` with the required escalation instead of retrying the same non-privileged command.
- When the environment is known to block writes under `.git`, prefer requesting the needed escalation for `git commit` directly after the user approves the message.
- If commit succeeds, remove `commit_message.txt` afterward. If commit fails, keep the file unless cleanup is clearly safe and intentional.

## Angular-Style Commit Format

Use this structure when additional detail is needed:

```text
type(scope): subject

Body paragraph(s) explaining what changed and why.

Footer for breaking changes or special notes when applicable.
```

Apply these formatting rules:

- Use the standard title form: `type(scope): subject`.
- Write the `subject` as an imperative summary, start it with a lowercase letter, and do not end it with a period.
- Keep the title at or below 80 characters.
- Keep the full commit message under 600 characters.
- Use the optional `body` to explain what changed and why, not implementation minutiae.
- The `body` may contain multiple paragraphs, separated by one blank line.
- Use the optional `footer` only for breaking changes or special considerations.

### Breaking Changes

Mark breaking changes with `!`, with a `BREAKING CHANGE:` footer, or with both when the title should signal the break immediately and the footer needs to explain migration impact.

Use `!` after the type or scope in the title:

```text
feat(api)!: send an email to the customer when a product is shipped
```

Use a `BREAKING CHANGE:` footer to describe the compatibility impact:

```text
feat(config)!: allow provided config object to extend other configs

BREAKING CHANGE: `extends` key in the config file now extends other config files
```

## Commit Type Guidance

Choose the narrowest commit `type` that matches the staged diff:

- `feat`: introduce user-facing behavior or a new capability.
- `fix`: correct a bug, regression, or broken behavior.
- `refactor`: improve internal structure without changing behavior.
- `perf`: improve performance or reduce resource usage.
- `docs`: update documentation only.
- `test`: add or adjust tests without changing production behavior.
- `build`: change dependencies, packaging, or build configuration.
- `ci`: update CI workflows or automation pipelines.
- `chore`: make routine maintenance changes that do not fit other types.
- `style`: apply formatting or non-functional code style updates.

Choose `scope` from the touched module, feature, service, or component name whenever possible. Prefer specific scopes such as `openai`, `screenshot`, or `settings` over broad labels like `app` or `misc`.

## Output and Approval Rules

- Present the result using this exact format and wait for explicit approval:

```
{English commit message}
```

```
{Simplified Chinese translation}
```

- Do not create `commit_message.txt` or run `git commit` before explicit approval.
- Write only the English message into `commit_message.txt`.

## Example

```
fix(screenshot): defer overlay capture until view appears

Move screenshot capture out of the overlay initializer so the view hierarchy is stable before capture starts.

This prevents the startup race that caused layout conflicts and crashes during screenshot translation.
```

```
fix(screenshot): 推迟悬浮层截图直到视图出现后再执行

将截图操作从悬浮层初始化方法中移出，待视图层级稳定后再开始截图。

此修改可防止因启动竞态条件引发的布局冲突和截图翻译崩溃问题。
```
