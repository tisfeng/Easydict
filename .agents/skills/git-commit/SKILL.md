---
name: git-commit
description: >
  仅根据已暂存内容创建 Angular-style 提交，并为调用方工作流推导 Conventional
  任务分支名。支持显式交付和受保护的 implementation 自动交付，为非英语用户生成
  双语提交信息，并且绝不推送。
---

# Git 提交流程

仅根据已暂存变更创建准确的 Angular-style Git 提交。

## 必需流程

1. 收集上下文：
   - `git status`
   - staged raw patch:
     `GIT_PAGER=cat git --no-pager diff --staged --no-ext-diff --no-textconv --unified=5`
   - `git branch --show-current`
   - `git log --oneline -10`
2. 在显式 `/git commit` 交付模式下，如果初始暂存 diff 为空且用户未限定路径或禁止
   暂存，只运行一次 `git add .`，再重新运行 `git status` 和暂存区原始 patch 命令。
   用户限定路径且允许暂存时只暂存指定路径；禁止暂存或仅要求提交已有暂存内容时，
   报告无可提交内容，不扩大范围。
3. 如果已经存在已暂存变更，不运行 `git add`；提交范围仅限当前暂存内容。
   当前 staged 内容超出用户指定范围时，保留索引并报告范围冲突，不自动重写暂存边界。
4. 如果唯一允许的一次 `git add .` 后暂存 diff 仍为空，则停止并要求用户先暂存文件。
5. 将暂存区原始 patch 作为唯一事实来源进行分析。针对单个路径时复用同一命令形式，
   并追加 `-- <path>`。
6. 先起草英文提交信息；仅当 `{USR_PREFERRED_LANGUAGE}` 不是英语时，再起草含义一致的
   本地语言区块。
7. 除非用户明确要求先确认、仅预览、仅生成提交信息、仅起草或不要提交，否则使用
   默认模式。
8. 在默认模式下，或在确认模式获得批准后，严格执行：
   - 将完整的实际提交信息写入 `commit_message.txt`。
   - 根据 **提交信息契约** 解析出的语言模式运行提交前校验：英语用户使用
     `english`，非英语用户使用 `bilingual`。
   - 只有提交前校验成功后，才运行 `git commit -F commit_message.txt`。
   - 提交成功后，读取实际 commit 并同时校验结构及其与
     `commit_message.txt` 的一致性。
   - 只有提交后校验成功后，才删除 `commit_message.txt`。
9. 提交成功后遵循 **Post-Commit Report**。在向用户展示该报告之前，即使 Git 命令
   成功但提交后校验失败，也不算完成交付。

## Implementation 自动交付

只有当仓库规则将任务分类为 `implementation` 且满足自动本地提交条件后，才调用此
模式。这是收尾步骤，不是在每次编辑后执行。规划、讨论、分析以及仅修改计划或历史
文档的任务不进入此模式。仓库规则允许时，Agent 文档 implementation 任务可以进入。

第一次写入前记录：

- `initial_staged_paths`
- `initial_unstaged_paths`
- `initial_untracked_paths`
- `task_allowed_paths`

当 `initial_staged_paths` 非空、Agent 暂存前当前索引已不再为空、Agent 路径与用户现有
变更重叠、索引存在冲突或必要验证失败时，跳过自动交付。在所有这些情况下都保持用户
的暂存边界不变。

符合自动交付条件时：

1. 确认任务修改了产品代码、测试、构建配置、运行时资源或 Agent 文档，并且尚未执行
   自动提交。
2. 只使用 `git add -- <paths>` 暂存 Agent 明确拥有的路径；此模式下绝不使用
   `git add .`。
3. 重新读取暂存区原始 patch，确认它只包含任务范围。
4. 使用本 skill 的提交信息契约及提交前后校验流程，并执行一次本地 `git commit`。
5. 遵循 **Post-Commit Report**。不要 push、pull、rebase、merge 或创建分支。

如果无法安全分离路径归属，则保留变更供手动交付，并报告 protected 状态。提交失败时
保留已暂存变更，并遵循现有提交失败规则。

## 提交信息契约

按顺序从第一个可用来源解析 `{USR_PREFERRED_LANGUAGE}`：

1. 当前请求或对话中明确的语言偏好。
2. 可读取的 locale，例如 macOS `AppleLanguages`、POSIX `LC_ALL`、
   `LC_MESSAGES`、`LANG`、`locale` 或 Windows PowerShell culture 输出。
3. 用户当前对话已经使用的语言。

将英语变体都视为英语，并据此设置 `{COMMIT_MESSAGE_MODE}`：英语为 `english`，其他
语言为 `bilingual`。英语用户只获得一个英文提交信息区块。非英语用户依次获得本地
语言区块、以下严格 70 个字符的分隔线和英文区块：

```text
----------------------------------------------------------------------
```

分隔线前后各保留一个空行。不要添加 `Chinese:` 或 `English:` 等标签。除 Markdown
代码围栏外，显示的提交信息必须与 `commit_message.txt` 完全一致。

每个语言区块都使用以下结构：

```text
type(scope): subject

First body paragraph explaining the current context or motivation.

Second body paragraph explaining the main change.

Third body paragraph explaining the result or impact.

Optional BREAKING CHANGE: footer when applicable.
```

- 使用范围最窄且准确的 `type(scope): subject`。
- 标题不超过 80 个字符。
- 英文 subject 使用祈使式摘要，以小写字母开头，结尾不加句号。
- 非英文 subject 使用简洁的目标语言摘要，结尾不加句末标点。
- 每个语言区块必须恰好包含三个自然的正文段落。
- 三个正文段落依次说明上下文、主要变更和影响。
- 每段保持简洁，通常为 1–3 句。
- 不使用 `Problem:`、`Change:` 或 `Summary:` 等标签。
- 聚焦行为和意图，不沉迷于底层实现细节。
- 非英文与英文区块的含义、段落数量和段落顺序必须一致。
- 仅在不兼容变更时使用 `!` 和/或最终的 `BREAKING CHANGE:` footer。校验器不接受
  其他 footer；footer 不能替代必需的三个正文段落。

## 提交信息校验

写入 `commit_message.txt` 后、运行 `git commit` 前，必须执行：

```bash
python3 .agents/skills/git-commit/scripts/validate-commit-message.py \
  --file commit_message.txt \
  --mode "${COMMIT_MESSAGE_MODE}"
```

提交前校验失败时停止提交，保留 `commit_message.txt`；可以修正本次生成的消息并重新
校验，通过后继续，不因可修复的格式错误要求用户重新授权。校验器
只检查可确定的结构：Angular 标题、80 字符限制、恰好三个正文段落、双语分隔线、两个
语言区块一致的 type/scope/breaking 标记，以及可选的最终 `BREAKING CHANGE:` footer。
它不判断翻译质量或三个正文段落的语义是否准确，Agent 仍须按真实 staged diff 审核内容。

`git commit` 成功后、删除消息文件前，必须使用刚创建的完整 commit hash 执行：

```bash
python3 .agents/skills/git-commit/scripts/validate-commit-message.py \
  --commit "${COMMIT_HASH}" \
  --expected-file commit_message.txt \
  --mode "${COMMIT_MESSAGE_MODE}"
```

提交后校验会读取 Git 中的实际消息并与预期文件比较。失败时进入 protected 状态：不要
自动 amend，不要删除 `commit_message.txt`，不要声称交付完成；报告 commit hash 和具体
错误，等待用户或调用方决定后续动作。

## 变动统计

提交成功后运行：

```bash
python3 .agents/skills/git-commit/scripts/commit-change-stats.py <full-commit-hash>
```

脚本只报告文本文件，并将它们划分为两个互斥类别：

- `docs`：位于 `docs` 或 `Documentation` 目录下的文件；名为 `AGENTS.md` 或
  `SKILL.md` 的文件；名称以 `README` 或 `CHANGELOG` 开头的文件；以及 `.md`、
  `.mdx`、`.rst` 或 `.adoc` 文件。
- `code`：其他所有文本文件，包括产品和测试源码、构建和运行时配置、资源、本地化
  catalog 以及 skill 脚本。

有意跳过二进制 numstat 条目。不要统计它们，也不要在面向用户的报告中提及二进制文件。

报告前，文件数、新增行、删除行和净变动的总计都必须等于 `code` 与 `docs` 之和。
脚本失败或结果不一致都视为报告失败，不得编造统计数据。

对于多提交集成范围，调用方工作流可以改为运行：

```bash
python3 .agents/skills/git-commit/scripts/commit-change-stats.py \
  --range <target-commit>...<source-commit>
```

## Post-Commit Report

每次提交成功后，使用以下命令收集权威结果：

- `git rev-parse HEAD`：完整哈希。
- `git show -s --format=%B HEAD`：完整的实际提交信息。
- `git branch --show-current`：当前分支。
- `git status --short`：最终工作树状态。
- **变动统计**：已提交文本变更的统计结果。

中文任务使用以下结构。英文任务翻译其中标签，但保留相同字段和顺序。

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

净变动为零时使用 `无变化`。不得用短哈希和标题取代完整报告。除代码围栏外，围栏内的
提交信息必须与 Git 完全一致。

调用方工作流复用已有提交时，只能修改动作行以说明本次运行没有创建提交。仍须保留完整
哈希、统计、实际提交信息、最终状态和 push 状态。在收集命令中使用被复用的哈希而不是
`HEAD`。

## 执行规则

- 不运行 `git push`。
- 不描述未暂存或无关的变更。
- 除非用户明确要求确认模式，否则将 `git-commit` 请求视为提交授权。
- 在确认模式下，获得明确批准前不要创建 `commit_message.txt` 或运行 `git commit`。
- 写入 `commit_message.txt` 的提交信息必须完全相同，且不包含 Markdown 代码围栏。
- 不要在单个 shell 命令中将 `git commit` 与提交信息文件的创建或清理串联起来。
- 不要在单个 shell 命令中将提交前校验、`git commit`、提交后校验或消息文件清理
  串联起来；每一步成功后再进入下一步。
- 暂存与提交都需要对应 Git 写入权限；按实际工具权限请求提权，不将权限请求误当作
  缺少用户的任务授权。
- 如果 `git commit` 在创建 `.git/index.lock` 时因 `Operation not permitted` 等
  sandbox 权限错误失败，立即使用所需提权重新运行
  `git commit -F commit_message.txt`。
- 已知环境会阻止写入 `.git` 时，在提交步骤直接为 `git commit` 请求所需提权。
- 提交前校验、提交或提交后校验任一步失败时都保留 `commit_message.txt`，除非清理
  操作明确安全且有意执行。
- 默认模式先提交，再遵循 **Post-Commit Report**。确认模式只展示实际提交信息并
  等待批准。

## Type 指南

选择与暂存 diff 匹配且范围最窄的提交类型：

- `feat`：引入面向用户的行为或新能力。
- `fix`：修复缺陷、回归或损坏的行为。
- `docs`：只更新文档。
- `style`：应用格式或不改变功能的代码风格修改。
- `refactor`：在不改变行为的情况下改进内部结构。
- `perf`：提升性能或减少资源使用。
- `test`：添加或调整测试，不改变生产行为。
- `build`：修改依赖、打包或构建配置。
- `ci`：更新 CI 工作流或自动化流水线。
- `chore`：进行不属于其他类型的日常维护。
- `revert`：回滚此前变更。

尽量根据涉及的模块、功能、服务或组件选择 `scope`。优先使用 `parser`、`api` 或
`settings` 等具体 scope，而不是 `app` 或 `misc` 等宽泛标签。

## Branch Name Guidance

仅当其他工作流需要在提交产生前获得任务分支名时，才使用本指南：

1. 在不暂存文件的前提下检查任务和只读 diff 证据。
2. 使用 **Type 指南**推断范围最窄的 Angular `type`，再用简洁英文概括主要意图。
3. 将摘要转换为小写 kebab-case，形成 `<type>/<kebab-case-summary>`。分支名中省略
   Angular scope 标点。

本指南只推导名称，不授权暂存、提交或创建分支。调用方工作流负责这些 Git 操作、名称
冲突处理和状态验证。

## 示例

仅英文提交信息：

```text
fix(ui): defer rendering until view appears

UI rendering started before its container was ready, creating a startup race. When layout was still settling, early rendering could trigger conflicts or produce blank content.

Move rendering out of the initializer. Start it after the view appears and layout is ready so the UI observes stable state.

This restores stable UI startup and reduces layout timing risk without changing the user-facing flow.
```

非英文双语提交信息。按以下顺序将这些区块和分隔线写入 `commit_message.txt`，不要包含
Markdown 代码围栏：

```text
fix(ui): 推迟渲染直到视图出现后再执行

界面容器尚未准备就绪时就开始渲染，导致启动阶段出现竞态。布局仍在变化时，过早渲染可能触发冲突或出现空白内容。

将渲染操作从初始化流程中移出，改为在视图出现且布局就绪后再开始，让界面读取稳定状态。

此修改恢复了稳定的界面启动流程，降低布局时序风险，并且不改变用户可见流程。
```

```text
----------------------------------------------------------------------
```

```text
fix(ui): defer rendering until view appears

UI rendering started before its container was ready, creating a startup race. When layout was still settling, early rendering could trigger conflicts or produce blank content.

Move rendering out of the initializer. Start it after the view appears and layout is ready so the UI observes stable state.

This restores stable UI startup and reduces layout timing risk without changing the user-facing flow.
```
