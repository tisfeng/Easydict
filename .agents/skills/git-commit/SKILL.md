---
name: git-commit
description: >
  Create staged-only Angular-style commits and derive Conventional task branch
  names for calling workflows. Supports explicit delivery and protected
  automatic implementation delivery, writes bilingual messages for non-English
  users, and never pushes.
---

# Git Commit Workflow

Create accurate Angular-style Git commits from staged changes only.

## Required Workflow

1. Collect context:
   - `git status`
   - staged raw patch:
     `GIT_PAGER=cat git --no-pager diff --staged --no-ext-diff --no-textconv --unified=5`
   - `git branch --show-current`
   - `git log --oneline -10`
2. In explicit `/git commit` delivery mode, if the initial staged diff is empty,
   run `git add .` once, then re-run `git status` and the staged raw patch command
   before continuing.
3. If staged changes already existed, do not run `git add`; keep the commit
   limited to the current staged scope.
4. Stop if the staged diff is still empty after the single allowed `git add .`.
   Ask the user to stage files first.
5. Analyze the staged raw patch as the only source of truth. For a single path,
   reuse the same command shape and append `-- <path>`.
6. Draft the English commit message, then draft a matching local-language block
   only when `{USR_PREFERRED_LANGUAGE}` is not English.
7. Use default mode unless the user explicitly asks to confirm first, preview
   only, generate only a message, draft only, or avoid committing.
8. In default mode, or after approval in confirmation mode, execute exactly:
   - Write the full actual commit message to `commit_message.txt`
   - Run `git commit -F commit_message.txt`
   - Remove `commit_message.txt` after a successful commit
9. After a successful commit, follow **Post-Commit Report**. A successful Git
   command is not a complete delivery until that user-visible report is shown.

## Automatic Implementation Delivery

This mode is invoked only after the repository rules classify the task as
`implementation` and the automatic local-commit conditions are satisfied. It
is a finalization step, not a per-edit action. Planning, discussion, analysis,
and changes limited to plans or histories do not enter this mode. Agent
documentation implementation tasks may enter when repository rules allow it.

Before the first write, capture:

- `initial_staged_paths`
- `initial_unstaged_paths`
- `initial_untracked_paths`
- `task_allowed_paths`

Skip automatic delivery when `initial_staged_paths` is non-empty, when the
current index is no longer empty before Agent staging, when an Agent path
overlaps an existing user change, when the index has a conflict, or when
required validation fails. Keep the user's staged boundary unchanged in all
of these cases.

When automatic delivery is eligible:

1. Confirm that the task changed product code, tests, build configuration,
   runtime resources, or Agent documentation and that no automatic commit has
   already occurred.
2. Stage only the exact Agent-owned paths with `git add -- <paths>`; never use
   `git add .` in this mode.
3. Re-read the staged raw patch and confirm it contains only the task scope.
4. Use this skill's commit-message contract and run one local `git commit`.
5. Follow **Post-Commit Report**. Do not push, pull, rebase, merge, or create a
   branch.

If path ownership cannot be separated safely, leave the changes available for
manual delivery and report the protected condition. A failed commit keeps the
staged changes and follows the existing commit-failure rules.

## Commit Message Contract

Resolve `{USR_PREFERRED_LANGUAGE}` from the first available source:

1. Explicit language preference in the current request or conversation.
2. Readable locale such as macOS `AppleLanguages`, POSIX `LC_ALL`,
   `LC_MESSAGES`, `LANG`, `locale`, or Windows PowerShell culture output.
3. The language the user is already using in the current conversation.

Treat English variants as English. English users get one English message block.
Non-English users get the local-language block first, this exact 70-character
separator, then the English block:

```text
----------------------------------------------------------------------
```

Place one blank line before and after the separator. Do not add labels such as
`Chinese:` or `English:`. The displayed message text must match
`commit_message.txt` exactly, except for Markdown code fences.

Use this structure for every language block:

```text
type(scope): subject

First body paragraph explaining the current context or motivation.

Second body paragraph explaining the main change.

Third body paragraph explaining the result or impact.

Optional footer for breaking changes or special notes when applicable.
```

- Use the narrowest accurate `type(scope): subject`.
- Keep the title at or below 80 characters.
- Write English subjects as imperative summaries starting with a lowercase
  letter and no final period.
- Write non-English subjects as concise target-language summaries without final
  sentence punctuation.
- Every language block must include exactly three natural body paragraphs.
- The three body paragraphs must cover context, main change, and impact in
  that order.
- Keep each paragraph concise, usually 1-3 sentences.
- Do not use labels such as `Problem:`, `Change:`, or `Summary:`.
- Focus on behavior and intent rather than low-level implementation detail.
- Keep non-English and English blocks aligned in meaning, paragraph count, and
  paragraph order.
- Use `!` and/or a `BREAKING CHANGE:` footer only for incompatible changes.
  The footer never replaces the required three body paragraphs.

## Change Statistics

After a successful commit, run:

```bash
python3 .agents/skills/git-commit/scripts/commit-change-stats.py <full-commit-hash>
```

The script reports only text files and partitions them into two mutually
exclusive categories:

- `docs`: files under a `docs` or `Documentation` directory; files named
  `AGENTS.md` or `SKILL.md`; names beginning with `README` or `CHANGELOG`; and
  `.md`, `.mdx`, `.rst`, or `.adoc` files.
- `code`: every other text file, including product and test source, build and
  runtime configuration, resources, localization catalogs, and skill scripts.

Binary numstat entries are intentionally skipped. Do not count them and do not
mention binary files in the user-facing report.

Before reporting, require each total to equal the sum of `code` and `docs` for
file count, insertions, deletions, and net change. Treat a script failure or an
inconsistent result as a reporting failure and do not invent statistics.

For a multi-commit integration range, a calling workflow may instead run:

```bash
python3 .agents/skills/git-commit/scripts/commit-change-stats.py \
  --range <target-commit>...<source-commit>
```

## Post-Commit Report

After every successful commit, collect the authoritative result with:

- `git rev-parse HEAD` for the full hash;
- `git show -s --format=%B HEAD` for the complete actual message;
- `git branch --show-current` for the branch;
- `git status --short` for the final worktree state; and
- **Change Statistics** for the committed text changes.

For a Chinese-language task, use this structure. Translate the labels for an
English-language task, but preserve the same fields and ordering.

````markdown
提交结果

- 动作：已创建提交
- Commit：`<full-hash>`
- 分支：`<branch>`
- 工作树：`干净` or `保留未提交变更`
- Push：未执行

变动统计

- 总变动：<files> 个文件，新增 <insertions> 行，删除 <deletions> 行，净增加/减少 <net> 行
- 代码变动：<files> 个文件，新增 <insertions> 行，删除 <deletions> 行，净增加/减少 <net> 行
- 文档变动：<files> 个文件，新增 <insertions> 行，删除 <deletions> 行，净增加/减少 <net> 行

实际提交信息

```text
<exact output of git show -s --format=%B HEAD>
```
````

Use `无变化` when a net value is zero. Never replace the complete report with
a short hash and subject. The message in the fenced block must match Git
exactly, except for the code fence.

A calling workflow that reuses an existing commit may change only the action
line to state that it did not create a commit in the current run. It must keep
the full hash, statistics, actual message, final status, and push state. Use the
reused hash instead of `HEAD` in the collection commands.

## Execution Rules

- Do not run `git push`.
- Do not describe unstaged or unrelated changes.
- Treat a `git-commit` request as authorization to commit unless confirmation
  mode was explicitly requested.
- In confirmation mode, do not create `commit_message.txt` or run `git commit`
  before explicit approval.
- Write exactly the same message text into `commit_message.txt`, without
  Markdown code fences.
- Do not chain `git commit` together with message-file creation or cleanup in a
  single shell command.
- Treat `git commit` as the only step that needs repository write access.
- If `git commit` fails with sandbox-style permission errors such as
  `Operation not permitted` while creating `.git/index.lock`, immediately rerun
  `git commit -F commit_message.txt` with the required escalation.
- When the environment is known to block writes under `.git`, request the
  needed escalation for `git commit` directly at the commit step.
- If commit fails, keep `commit_message.txt` unless cleanup is clearly safe and
  intentional.
- In default mode, commit first, then follow **Post-Commit Report**. In
  confirmation mode, show only the actual message text and wait for approval.

## Type Guidance

Choose the narrowest commit type that matches the staged diff:

- `feat`: introduce user-facing behavior or a new capability.
- `fix`: correct a bug, regression, or broken behavior.
- `docs`: update documentation only.
- `style`: apply formatting or non-functional code style changes.
- `refactor`: improve internal structure without changing behavior.
- `perf`: improve performance or reduce resource usage.
- `test`: add or adjust tests without changing production behavior.
- `build`: change dependencies, packaging, or build configuration.
- `ci`: update CI workflows or automation pipelines.
- `chore`: make routine maintenance changes that do not fit another type.
- `revert`: roll back a previous change.

Choose `scope` from the touched module, feature, service, or component whenever
possible. Prefer specific scopes such as `openai`, `screenshot`, or `settings`
over broad labels like `app` or `misc`.

## Branch Name Guidance

Use this guidance only when another workflow needs a task branch name before a
commit exists:

1. Inspect the task and read-only diff evidence without staging files.
2. Use **Type Guidance** to infer the narrowest Angular `type`, then summarize
   the primary intent in concise English.
3. Convert the summary to lowercase kebab-case and form
   `<type>/<kebab-case-summary>`. Omit Angular scope punctuation from the
   branch name.

This guidance derives a name only. It does not authorize staging, committing,
or creating a branch. The calling workflow owns those Git operations, name
collision handling, and state validation.

## Examples

English-only commit message:

```text
fix(screenshot): defer overlay capture until view appears

Overlay capture started before the view hierarchy was stable, creating a startup race in screenshot translation. When layout was still settling, that early capture could trigger conflicts or crashes.

Move screenshot capture out of the overlay initializer. Start it after the view appears and layout is ready so the capture path observes stable UI state.

This restores stable screenshot translation startup. It also reduces layout timing risk without changing the user-facing capture flow.
```

Non-English bilingual commit message. Write these blocks and the separator to
`commit_message.txt` in this order, without Markdown code fences:

```text
fix(screenshot): 推迟悬浮层截图直到视图出现后再执行

悬浮层在视图层级尚未稳定时就启动截图，导致截图翻译启动阶段出现竞态。布局仍在变化时，过早截图可能触发布局冲突或崩溃。

将截图操作从悬浮层初始化方法中移出。改为在视图出现且布局就绪后再开始截图，让截图流程读取稳定的 UI 状态。

此修改恢复了截图翻译启动流程的稳定性。同时降低布局时序风险，并且不改变用户可见的截图流程。
```

```text
----------------------------------------------------------------------
```

```text
fix(screenshot): defer overlay capture until view appears

Overlay capture started before the view hierarchy was stable, creating a startup race in screenshot translation. When layout was still settling, that early capture could trigger conflicts or crashes.

Move screenshot capture out of the overlay initializer. Start it after the view appears and layout is ready so the capture path observes stable UI state.

This restores stable screenshot translation startup. It also reduces layout timing risk without changing the user-facing capture flow.
```
