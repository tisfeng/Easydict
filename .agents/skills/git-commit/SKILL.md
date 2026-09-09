---
name: git-commit
description: 根据已暂存内容创建 Angular-style 提交，并为调用方工作流推导 Conventional 任务分支名。支持显式交付，以及在仓库规则明确授权时安全自动提交；为非英语用户生成双语提交信息，且不推送。
---

# Git 提交流程

根据经过范围校验的暂存变更创建准确的 Angular-style Git 提交。显式交付可按下述决策创建一次
暂存快照；提交信息与最终提交始终只以 staged raw patch 为准。

下文的 `<git-commit-skill-dir>` 表示当前加载的 `git-commit/SKILL.md` 所在目录。
运行随 skill 分发的脚本时，先解析该实际目录；不要假设 skill 安装在某个固定的
Agent 或项目路径中。

## 必需流程

1. 收集上下文：
   - `git status`
   - staged raw patch:
     `GIT_PAGER=cat git --no-pager diff --staged --no-ext-diff --no-textconv --unified=5`
   - unstaged raw patch:
     `GIT_PAGER=cat git --no-pager diff --no-ext-diff --no-textconv --unified=5`
   - untracked paths: `git ls-files --others --exclude-standard`
   - `git branch --show-current`
   - `git log --oneline -10`
2. 根据 **暂存决策** 冻结唯一可用的暂存策略，再执行该策略并重新运行 `git status` 和
   staged raw patch 命令。
3. 如果暂存后的路径或 raw patch 与冻结候选不一致，停止并保留索引；不得通过第二次
   `git add` 修正范围。
4. 如果唯一允许的一次暂存后 staged diff 仍为空，则停止，不创建空提交。
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

## 暂存决策

执行者只能选择以下一种策略；预检冻结策略、候选路径和相应 raw patch 后，写入阶段必须重新
读取并完全匹配。`worktree-rebase-merge` 在创建源提交时复用本节，不另设空索引停止规则。

- **existing-index**：初始索引非空时，不运行 `git add`；只复验既有 staged paths 与 staged raw
  patch。若它超出用户范围，保留索引并报告冲突。
- **explicit-paths**：用户明确调用 `git-commit` 或 `worktree-rebase-merge`，初始索引为空且限定
  路径、并允许暂存时，只运行一次 `git add -- <selected-paths>`。
- **explicit-worktree-once**：用户明确调用上述任一交付工作流，初始索引为空、未限定路径，且未
  禁止暂存或要求 staged-only 时，只运行一次 `git add .`。预检必须先冻结完整未暂存 raw patch、
  任务相关未跟踪文件摘要和候选路径；暂存后 staged paths 与 staged raw patch 必须与该快照一致。
- **auto-exact**：仓库规则授权的 `auto-local-commit` 只运行一次
  `git add -- <expected_commit_paths>`，并要求最终 staged paths 与该冻结集合完全相等；绝不使用
  `git add .`。
- 禁止暂存、仅要求提交已有 staged 内容、策略无法确定、候选内容漂移或存在冲突时，不暂存并进入
  protected。

## 经仓库规则授权的自动交付

只有仓库规则或调用方已明确授权自动本地提交时，才调用此模式。这是收尾步骤，不是在每次
编辑后执行。规划、讨论和分析不进入此模式；已授权 implementation 是否包含仅修改计划、history
或其他 Agent 文档的任务由宿主仓库规则决定。

第一次写入前记录：

- `initial_head`
- `initial_staged_paths`
- `initial_unstaged_paths`
- `initial_untracked_paths`
- `task_allowed_paths`
- `agent_owned_paths`

实现完成后冻结 `expected_commit_paths`。它是本次实际要提交的 Agent-owned 路径集合，必须属于
`task_allowed_paths`；允许范围可以比实际修改集合更宽，不能据此暂存未修改路径。

当 `initial_staged_paths` 非空、Agent 暂存前当前索引已不再为空、Agent 路径与用户现有
变更重叠、索引存在冲突或必要验证失败时，跳过自动交付。在所有这些情况下都保持用户
的暂存边界不变。

“Agent 暂存前”指本次自动交付唯一暂存步骤开始之前。`git-delivery` 在同一 apply 中按冻结快照
完成该步骤后，非空索引是预期结果，不得再次暂存，也不应据此反向判定自动交付失效。

符合自动交付条件时：

1. 确认任务属于仓库规则允许自动交付的类别，已有明确授权且没有禁止自动提交的约束，
   修改了授权范围内的文件，并且尚未执行自动提交。
2. 重新读取 `HEAD`、`git status --short` 和冲突状态。如果 `initial_head`、用户归属内容、
   非预期索引或冲突状态发生变化，立即跳过自动交付并进入 protected；Agent 在允许路径内产生的
   预期 implementation 差异不属于初始状态漂移。
3. 只使用 `git add -- <expected_commit_paths>` 暂存冻结的 Agent-owned 路径；此模式下绝不使用
   `git add .`。
4. 重新读取 `git diff --cached --name-only` 和暂存区原始 patch，确认路径集合与
   `expected_commit_paths` 完全一致，并且后者属于 `task_allowed_paths`。
5. 使用本 skill 的提交信息契约及提交前后校验流程，并执行一次本地 `git commit`。
6. 遵循 **Post-Commit Report**。不要 push、pull、rebase、merge 或创建分支。

如果无法安全分离路径归属，则保留变更供手动交付并说明原因。提交失败时保留已暂存变更，
并遵循现有提交失败规则。

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
python3 "<git-commit-skill-dir>/scripts/validate-commit-message.py" \
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
python3 "<git-commit-skill-dir>/scripts/validate-commit-message.py" \
  --commit "${COMMIT_HASH}" \
  --expected-file commit_message.txt \
  --mode "${COMMIT_MESSAGE_MODE}"
```

提交后校验会读取 Git 中的实际消息并与预期文件比较。失败时停止自动处置：不要自动 amend，
不要删除 `commit_message.txt`，不要声称交付完成；报告 commit hash 和具体错误，等待用户或
调用方决定后续动作。

## 变动统计

提交成功后运行：

```bash
python3 "<git-commit-skill-dir>/scripts/commit-change-stats.py" <full-commit-hash>
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

统计数字以脚本输出的 JSON 为准。在面向用户的最终回复中，按本 Skill 定义的 Markdown
表格展示；不要修改脚本默认输出为 Markdown。

对于多提交集成范围，调用方工作流可以改为运行：

```bash
python3 "<git-commit-skill-dir>/scripts/commit-change-stats.py" \
  --range <target-commit>...<source-commit>
```

## Post-Commit Report

每次提交成功后，使用以下命令收集权威结果：

- `git rev-parse HEAD`：完整哈希。
- `git show -s --format=%B HEAD`：完整的实际提交信息。
- `git branch --show-current`：当前分支。
- `git status --short`：最终工作树状态。
- **变动统计**：已提交文本变更的统计结果。

以下是用户可见、不可省略的完整交付回执。它必须出现在面向用户的最终回复中；终端输出、
工具输出、子 Agent 返回、短哈希、`hash + subject` 或仅有一行总结均不能替代该回执。
调用方可在回执前后补充本次工作流的结果，但适用字段必须完整保留。

中文任务使用以下结构。英文任务翻译其中标签，但保留相同字段和顺序。

````markdown
提交结果

- 动作：已创建提交
- Commit：`<full-hash>`
- 分支：`<branch>`
- 提交后校验：`<validation-status>`
- 工作树：`干净` or `保留未提交变更`
- Push：未执行

变动统计

| 类别 | 文件数 | 新增行 | 删除行 | 净变动 |
| --- | ---: | ---: | ---: | ---: |
| 总计 | <files> | <insertions> | <deletions> | <signed-net> |
| 代码 | <files> | <insertions> | <deletions> | <signed-net> |
| 文档 | <files> | <insertions> | <deletions> | <signed-net> |

实际提交信息

```text
<exact output of git show -s --format=%B HEAD>
```
````

正净变动使用 `+N`，负值使用 `-N`，零值使用 `0（无变化）`。英文任务翻译表头和零值
说明，但保留相同字段、行顺序和数字。代码块中的提交信息必须与 Git 中保存的信息完全一致。
本次创建提交且提交后校验实际通过时使用 `通过`；复用已有提交而本次未运行提交后校验时使用
`未执行（本次复用已有提交）`。不得把只读 message 检查写成提交后一致性校验。

调用方工作流复用已有提交时，可以修改动作行和提交后校验状态以如实说明本次没有创建或
校验提交；仍须保留完整哈希、统计、实际提交信息、最终状态和 push 状态。在收集命令中
使用被复用的哈希而不是 `HEAD`。

## 执行规则

- 不运行 `git push`。
- 不描述未暂存或无关的变更。
- 除非用户明确要求确认模式，否则将 `git-commit` 请求视为提交授权。
- 在确认模式下，获得明确批准前不要创建 `commit_message.txt` 或运行 `git commit`。
- 写入 `commit_message.txt` 的提交信息必须完全相同，且不包含 Markdown 代码围栏。
- 不要在单个 shell 命令中将 `git commit` 与提交信息文件的创建或清理串联起来。
- 不要在单个 shell 命令中将提交前校验、`git commit`、提交后校验或消息文件清理
  串联起来；每一步成功后再进入下一步。
- 将 `git add` 和 `git commit` 都视为需要仓库写入权限的步骤；任何暂存或提交失败都保留
  当前现场。
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

需要了解最终用户可见的完整交付格式时，读取
[完整提交回执示例](references/post-commit-report-example.md)。回执字段、统计格式和提交
信息一致性要求以 **Post-Commit Report** 为准。
