# Changelog

本目录保存 Easydict 各版本的 GitHub Release 正文，也是 Sparkle 应用内更新日志的唯一
Markdown 来源。

## 文件约定

- 文件名必须为 `<version>.md`，例如 `2.22.0.md`；版本使用 `x.y.z` 格式。
- 正文使用 UTF-8 和 LF 换行，不添加 YAML front matter 或 Release 标题。
- GitHub Release 标题独立维护；Release 正文必须与对应 Markdown 内容一致。
- 可以在发布开始前直接编辑 Markdown；编辑后重新运行验证。发布状态冻结后发生的改动会
  触发哈希不一致，必须重新开始或明确重建 Draft，不能静默沿用旧 appcast。

## 发布关系

```text
changelog/<version>.md
├── GitHub Release body（原始 Markdown）
└── Sparkle appcast description（确定性渲染后的 HTML）
```

发布脚本会校验文件、固定其 SHA-256，并在 Draft、publish、resume 和远程验证阶段检查
内容没有漂移。正文比较只规范化 GitHub 的 CRLF/LF 和单个文件结尾换行，其他字符和空白
必须一致。Markdown 渲染依赖见 `scripts/release/requirements.txt`。

已发布版本如果需要修订，先修改并提交对应 Markdown；随后应在明确授权的维护任务中同步
GitHub Release 和 appcast。不要只手动修改其中一个发布表面，发布校验会把这种状态视为
内容漂移。
