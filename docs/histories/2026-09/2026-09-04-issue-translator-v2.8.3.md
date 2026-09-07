# Issue Translator Action v2.8.3 更新

- 日期：2026-09-04
- 状态：completed
- 上游 tag：`tisfeng/issues-translate-action@v2.8.3`
- 上游提交：`fc86486959aad3c51b4903044534e6cdc09468a3`

## 用户请求

将 Easydict 的 Issue 翻译 workflow 更新到 `issues-translate-action` 的 `v2.8.3`。

## 变更

- 将 `.github/workflows/issue-translator.yml` 中固定的 Action 引用从 `v2.8.2` 更新为 `v2.8.3`。
- 保持现有事件、inputs 和 `node24` 运行时不变。

## 设计意图

`v2.8.3` 在语言识别前忽略 Markdown 图片和链接中的 HTTP(S) URL，避免含中文正文的评论被误判为英文并跳过翻译；实际翻译仍使用完整原文。Easydict 继续固定引用明确的 patch tag，而不依赖分支。

## 验证

- 上游 `v2.8.3^{}` 在更新前解析到 `fc86486959aad3c51b4903044534e6cdc09468a3`。
- 上游 `action.yml` 的 inputs、`runs.using: node24` 与 `dist/index.js` 入口均与 `v2.8.2` 兼容。
- 本地 YAML 解析、`git diff --check` 和引用范围审计：通过；运行时 workflow 引用唯一且为 `v2.8.3`。

## 后续事项

- 不执行推送；下一次自然发生的中文 Issue、评论或 PR review comment 将在 GitHub Runner 验证真实翻译行为。
