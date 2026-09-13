# 提交信息契约

起草或创建提交时读取。先根据真实 staged diff 审核内容，再生成信息；校验器只验证结构，
不替代语义检查。

## 语言与结构

按顺序使用第一个可用的用户首选语言：

1. 当前请求或对话中明确的语言偏好。
2. 可读取的 locale，例如 macOS `AppleLanguages`、POSIX `LC_ALL`、`LC_MESSAGES`、
   `LANG`、`locale` 或 Windows PowerShell culture。
3. 当前对话已使用的语言。

英语使用 `english` 模式，只有一个英文区块。非英语使用 `bilingual` 模式，依次为本地
语言区块、空行、严格 70 个字符的分隔线、空行和英文区块：

```text
----------------------------------------------------------------------
```

不添加 `Chinese:` 或 `English:` 等标签。每个语言区块使用：

```text
type(scope): subject

First body paragraph explaining the current context or motivation.

Second body paragraph explaining the main change.

Third body paragraph explaining the result or impact.

Optional BREAKING CHANGE: footer when applicable.
```

- 使用范围最窄且准确的 Angular `type(scope): subject`，标题不超过 80 个字符。
- 英文 subject 使用祈使式小写摘要，结尾无句号；非英文 subject 简洁且无句末标点。
- 每个语言区块恰好三个自然正文段，依次说明上下文、主要变更和结果，通常每段 1–3 句。
- 不使用 `Problem:`、`Change:` 或 `Summary:` 等标签；非英文与英文区块的含义、段落数和顺序一致。
- 仅在不兼容变更时使用 `!` 或最终 `BREAKING CHANGE:` footer；footer 不能替代三个正文段。

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
