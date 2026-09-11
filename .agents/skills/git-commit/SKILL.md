---
name: git-commit
description: 根据已暂存内容创建 Angular-style 提交，并为调用方工作流推导 Conventional 任务分支名。支持显式交付，以及在仓库规则明确授权时安全自动提交；为非英语用户生成双语提交信息，且不推送。
---

# Git 提交流程

根据经过范围校验的内容创建 Angular-style Git 提交。实际提交及其回执以 staged diff 和 Git
中的真实提交为准；只读预览可以使用尚未暂存的候选，但必须明确标为草稿。

`<git-commit-skill-dir>` 指实际加载的本 Skill 目录；使用该目录中的脚本，不假设安装路径。

## 组合任务

本 Skill 不依赖其他 Skill。调用方以任务、允许范围和已有证据表达需要的能力，不引用内部
章节或复制执行步骤；脚本路径从当前加载目录解析。支持以下任务：

| 任务 | 必要输入与结果 |
| --- | --- |
| 起草或预览提交 | 根据指定 staged 内容或获准候选返回草稿，不写 Git 或消息文件。 |
| 创建提交 | 在有效提交授权下完成范围判断、预览、暂存、提交和校验，返回实际提交回执。 |
| 推导任务分支名 | 根据指定任务、diff 或已有提交及命名约定返回候选名，不暂存、提交或创建分支。 |
| 汇报已有提交 | 根据明确的提交或范围读取真实结果与统计，不因当前还有改动而启动新提交。 |

调用方只消费真实结果和限制；字段与展示格式由本 Skill 维护。为已提交内容生成回执时，不
反向要求满足新提交的消息格式或任务初始状态，也不宣称执行过本轮没有运行的提交后校验。

## 先确定模式

- **仅命名或汇报已有提交**：只执行相应组合任务，Git 读取使用 `GIT_OPTIONAL_LOCKS=0`；
  不进入新提交准备。未指定提交引用时先明确对象，不把当前 staged 内容当作已有提交。
- **仅预览、仅起草或只读**：只检查并展示草稿，不暂存、不创建消息文件、不提交或改变 Git 状态。
  Git 读取使用 `GIT_OPTIONAL_LOCKS=0`。已有 staged 时只使用其内容；索引为空时使用获准范围内
  的 unstaged 和 untracked 候选。
- **确认模式**：先展示完整预览并等待批准。只有已经明确获准的暂存动作可以提前执行；否则从
  只读候选起草，批准后再暂存和复验。
- **默认模式**：明确调用本 Skill 或已有宿主自动提交授权时，按下文准备、预览后直接提交。
  预览本身不增加确认门槛。
- 用户的禁止、范围和暂缓要求持续有效；“不提交”不自动授权暂存。没有提交授权时只完成已获准
  的准备工作，不进入默认模式。

## 快速执行协议

保持本 Skill 的完整范围判断、raw patch 审核、提交信息预览、逐命令权限、提交前后校验和完整
回执；优化的是正常成功路径的模型往返，不是删除检查或合并 Git 权限边界。

- 运行时支持在一次模型调用中编排多个工具时，优先使用程序化工具调用。首次预检在一个程序中
  并行读取互不依赖的 HEAD、分支、status、staged/unstaged diff、untracked 路径和最近提交；
  只向模型返回一次完整 raw patch 及紧凑的结构化事实。运行时不支持时继续使用普通工具调用，
  但仍并行无依赖的只读检查并避免重复输出。
- 模型只在模式、范围、内容归属、提交信息语义、可见预览和真实异常上作判断。预览后内容未变的
  正常路径，在一次程序化调用中依次等待写前复验、唯一暂存、staged 一致性检查、消息文件写入、
  提交前校验、`git commit`、提交后校验、清理和回执采集；每条命令仍是独立工具调用，不拼接为
  一个 shell 命令，也不通过通用脚本取得整段写权限。
- 按实际工具契约确认命令完成且退出码为 0 才能继续（例如返回 `exit_code: 0`）。返回运行中会话、缺少退出码、
  审批未完成或非零退出码都不是命令成功；继续等待真实结果，或者停止程序并把当前阶段、命令、
  退出码和必要状态返回模型。不得用会把 `undefined` 当成成功的 truthy/falsy 判断。消息文件写入
  等非命令工具按其原生成功与错误契约判断，明确报错或 `isError` 时停止，不能要求它提供进程退出码。
- 首次语义审查后冻结 HEAD、index、候选路径及内容证据。后续相同事实只返回 `unchanged`；发现
  漂移时返回变化字段和相关原始证据，不重复打印未变化的全量 status、diff 或 log。untracked
  摘要不能代替暂存后的 raw patch 等价检查，mode、删除、rename、symlink、filter 和部分暂存
  仍按真实 Git 内容复验。
- 需要用户确认、候选或消息发生变化、范围无法证明、校验失败、Git hook 改写结果、审批拒绝或
  其他需要语义判断的情况立即返回模型。不得为了维持快速路径自动重试写入、扩大暂存、amend 或
  清理现场。

正常路径以“合并模型往返、保留命令边界”为原则：一次程序化调用不等于一次 Git 事务，也不
等于一次宽泛审批。已经加载且未变化的 Skill、规则和回执模板不要重复读取；最终报告仍完整输出。

## 准备与暂存

1. 记录调用目录，用 `git rev-parse --show-toplevel` 定位仓库根目录。用户提供的相对路径先按
   原调用目录解析；后续 Git 检查和暂存从仓库根目录执行，避免 `git add .` 漏掉其他目录。
2. 读取 HEAD、当前分支、`git status --short`、最近提交和相关 untracked 内容。分别检查：

   ```bash
   git --no-pager diff --cached --no-ext-diff --no-textconv --unified=5
   git --no-pager diff --no-ext-diff --no-textconv --unified=5
   git ls-files --others --exclude-standard
   ```

3. 按下表确定范围，记录候选路径、raw patch 和未跟踪文件内容摘要。预览/确认限制优先于任何
   暂存策略。准备写入时复验 HEAD、索引与候选内容；非预期变化或冲突存在时停止并保留现场。
4. 获准后只执行一次选定的暂存动作，比较 staged paths 与 raw patch 是否和候选完全一致。
   不一致时停止，不用第二次 `git add` 修正范围；没有可提交差异时不创建空提交。

| 情况 | 暂存动作 |
| --- | --- |
| 已有索引（`existing-index`） | 不运行 `git add`，只提交既有 staged 内容；超出用户范围时停止。 |
| 显式交付、空索引、限定路径（`explicit-paths`） | 获准后一次 `git add -- <selected-paths>`。 |
| 显式交付、空索引、未限定路径（`explicit-worktree-once`） | 未禁止暂存且非 staged-only 时，在仓库根目录一次 `git add .`。 |
| 宿主授权自动提交（`auto-exact`） | 一次 `git add -- <expected_commit_paths>`，禁止 `git add .`。 |

`worktree-rebase-merge` 创建源提交时复用本节。禁止暂存或要求 staged-only 且索引为空时，
不生成提交；纯预览仍可报告候选或范围缺口。

## 宿主授权的自动提交

自动提交只在获准任务收尾时执行，是否启用及是否需要 history 由宿主规则决定。第一次写入前
记录 `initial_head`、初始 staged/unstaged/untracked 路径、`task_allowed_paths` 和内容归属。
完成实现和必要验证后，冻结本次实际修改的 `agent_owned_paths` 与 `expected_commit_paths`；
后者必须属于允许范围，不能混入用户原有内容。

这些名称是内部证据记录，不是宿主必填变量或配置。根据当前有效请求、已有项目政策和任务
记录确定授权及范围；已有的等价起点证据可以复用。缺少真实起点或无法区分内容归属时，只
停止自动提交路径，不用当前状态补造初始快照，也不要求项目改写 Agent 文档。用户明确授权的
staged-only 提交仍按其范围独立判断；没有宿主自动提交政策时，不从实现请求自行推导提交授权。

初始索引非空、唯一暂存前出现非 Agent staged 内容、HEAD 非预期变化、归属无法分离、存在冲突、
验证失败或仍有禁止/确认/暂缓要求时，不自动提交。保护用户的暂存边界，报告具体原因。
按 `auto-exact` 完成唯一暂存后，预期的非空索引不使自动提交失效；此后遵循同一提交流程，
每项任务只自动提交一次。自动模式不创建分支，也不 push、pull、rebase 或 merge。

## 提交与可见预览

1. 已有索引时依据 staged diff 起草；尚未获准暂存的预览或确认模式可使用只读候选。实际提交前
   必须核对 staged 内容与候选一致。先起草英文，再按 **提交信息契约** 生成用户语言区块。
2. 在主对话发送 `提交信息预览`，用 `text` 代码围栏展示完整拟定消息。不能只写入工具输出或文件。
   纯预览到此结束；确认模式等待批准；默认模式直接继续。
3. 如获准后才暂存，先按冻结候选完成唯一暂存和复验。拟提交内容变化时重新起草并展示；用户
   要求确认的消息发生变化时重新取得确认，不复用旧批准。
4. 将与预览完全相同的消息写入 `commit_message.txt`，不包含 Markdown 围栏。不要覆盖已有的
   无关文件；文件冲突时使用本任务独有的消息路径，并在后续命令中一致替换。
5. 按下文分别执行提交前校验、`git commit -F commit_message.txt`、实际提交与消息文件的
   提交后校验。每一步成功后再进入下一步，不串联为单个 shell 命令；符合 **快速执行协议**时，
   可以在同一次程序化调用中连续等待这些独立命令。
6. 提交后校验成功才删除本任务消息文件，并按 **Post-Commit Report** 完整交付。失败时保留
   现场与消息文件，不自动 amend，不把 Git 命令成功等同于交付完成。

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

仅请求已有多提交范围的结果时，冻结范围两端，按 `git log` 列出各完整哈希和 subject，并按
**变动统计**生成该范围的统计表；注明没有创建新提交、未执行提交后校验，以及实际分支、
工作树和 push 状态。范围没有单一实际提交信息，不把某一条 message 作为整个范围的 message。

## 执行规则

- 本 Skill 不运行 `git push`；提交信息不包含候选范围外的变更。
- `git add` 和 `git commit` 都需要仓库写入权限。已知 `.git` 受限时，直接为已授权命令请求
  必要提权；普通权限因沙箱限制失败时保留现场，按所需权限重试，不扩大业务授权。
- 暂存或提交失败时不自动清理用户状态。提交前校验可修正本任务消息后重试；提交后校验失败的
  后续处置遵循 **提交信息校验**。

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

用户明确给出的名称或项目已有命名约定优先；未给出时使用下面的 Conventional 默认值。
候选必须是 Git 支持的字面分支名，不使用 `@{-1}` 等会展开为其他引用的表达式。

1. 在不暂存文件的前提下检查任务和只读 diff 证据。
2. 使用 **Type 指南**推断范围最窄的 Angular `type`，再用简洁英文概括主要意图。
3. 将摘要转换为小写 kebab-case，形成 `<type>/<kebab-case-summary>`。分支名中省略
   Angular scope 标点。

本指南只推导名称，不授权暂存、提交或创建分支。调用方工作流负责这些 Git 操作、名称
冲突处理和状态验证。

需要了解最终用户可见的完整交付格式时，读取
[完整提交回执示例](references/post-commit-report-example.md)。回执字段、统计格式和提交
信息一致性要求以 **Post-Commit Report** 为准。
