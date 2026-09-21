# 提交信息契约

起草或创建提交时读取。先根据真实 staged diff 审核内容，再生成信息；校验器只验证结构，
不替代语义检查。

## 语言与结构

按以下优先级确定提交信息语言：

1. 用户明确指定的提交信息语言。
2. 当前对话主要使用的自然语言。
3. 系统偏好语言，仅在前两项无法判断时使用。

仍无法判断时使用 English。

英语使用 `english` 模式，只有一个英文区块。非英语使用 `bilingual` 模式，依次为本地
语言区块、空行、严格 70 个字符的分隔线、空行和英文区块：

```text
----------------------------------------------------------------------
```

不添加 `Chinese:` 或 `English:` 等区块标签。中文本地语言区块使用：

```text
type(scope): subject

背景：说明当前背景、问题或动机。

变更：说明本次提交的主要修改。

影响：说明修改后的行为、影响或保留边界。

Optional BREAKING CHANGE: footer when applicable.
```

英文区块以及其他非中文的本地语言区块使用：

```text
type(scope): subject

context: Explain the current context, problem, or motivation.

change: Explain the main change made by this commit.

impact: Explain the resulting behavior, impact, or preserved boundary.

Optional BREAKING CHANGE: footer when applicable.
```

整个提交还可以在所有语言区块之后使用一次可选的 `References:` 尾段；它不属于任一语言区块。

- 使用范围最窄且准确的 Angular `type(scope): subject`，标题不超过 80 个字符。
- `type`、`scope` 和 `!` 在两个区块保持一致；冒号后的 subject 分别使用该区块的语言。
  中文任务的第一个 subject 必须包含中文，第二个 subject 必须使用英文；不得把同一个英文
  subject 同时用于两个区块。其他非英语任务同样先写本地语言 subject，再写英文镜像。
- 英文 subject 使用祈使式小写摘要，结尾无句号；非英文 subject 简洁且无句末标点。
- 每个语言区块恰好三个自然正文段，依次说明背景、变更和影响，通常每段 1–3 句。
- 中文区块依次使用 `背景：`、`变更：`、`影响：`，标记后直接接非空正文；英文标记依次使用
  `context: `、`change: `、`impact: `，冒号后恰好一个空格再接非空正文。
- 同一语言区块不能缺失、错序或混用两套标记；非英文与英文区块的含义、段落数和顺序一致。
- 仅在不兼容变更时使用 `!` 或语言区块末尾的 `BREAKING CHANGE:` footer；footer 不能替代
  三个正文段。全局 `References:` 尾段存在时排在所有语言区块及其 footer 之后。

## 外部引用

当前请求、已采纳的调查证据或 staged 内容包含直接影响本次动机、诊断、设计或验证的外部
PR、Issue、review thread、文档或网页时，在整个提交末尾追加一次引用尾段：

```text
References:
- Apple TN3212: https://developer.apple.com/documentation/technotes/tn3212-adopting-gesture-recognizers-for-sidecar-touch-support
- BetterDisplay #5731: https://github.com/waydabber/BetterDisplay/issues/5731
```

- 固定使用不翻译的 `References:`，其前恰好一个空行；标题与条目之间不留空行。
- 每个条目独占一行，以 `- ` 开头，可使用以 `: ` 分隔的简短标签，并以可直接跳转的绝对
  HTTP(S) URL 结尾。
- 整个提交最多一个引用尾段。按引用在正文中的首次出现顺序排列；正文未提及时，按已采纳
  证据中的首次出现顺序排列，并按 URL 去重。
- PR、Issue 和 review thread 优先使用精确页面或评论的 canonical URL，不使用仓库首页、搜索页
  或只有编号的缩写。目标不能唯一确认时不猜测，先报告缺失的引用信息。
- 正文必须说明引用与变更的关系及证据边界；引用尾段只提供跳转入口，不替代三个正文段，
  也不把“行为一致”夸大为“已确认原因”。
- 不因 staged 内容含有徽章、依赖主页、示例链接或普通文档链接就自动引用；只保留实际影响
  本次决策的最小来源集合。
- 不使用 `Closes:`、`Fixes:` 或 `Resolves:` 代替中性的 `References:`，避免引入 Issue 状态语义。

## Type 指南

- `feat`：新的用户行为或能力。
- `fix`：缺陷、回归或损坏行为的修复。
- `docs`：仅文档。
- `style`：不改变功能的格式或代码风格。
- `refactor`：不改变行为的内部结构改进。
- `perf`：性能或资源改进。
- `test`：仅测试。
- `build`：依赖、打包或构建配置。
- `ci`：CI 工作流。
- `chore`：不属于其他类型的维护。
- `revert`：回滚变更。

scope 优先使用 `parser`、`api` 或 `settings` 等具体模块，避免 `app` 或 `misc` 等宽泛名称。

## 提交前后校验

将与可见预览完全一致的内容写入任务专用消息文件后运行：

```bash
python3 "<git-commit-skill-dir>/scripts/validate-commit-message.py" \
  --file <message-file> --mode <english|bilingual>
```

校验失败时可修正本次生成的信息并重新校验，不因格式修正重新要求提交授权。
但候选内容或用户已要求确认的消息变化时，必须重新展示，并在需要时重新确认。

`git commit` 后、删除消息文件前，使用刚创建的完整 hash 运行：

```bash
python3 "<git-commit-skill-dir>/scripts/validate-commit-message.py" \
  --commit <full-commit-hash> --expected-file <message-file> --mode <english|bilingual>
```

提交后校验失败时保留消息文件，报告 commit hash 和具体错误；不自动 amend。
