## 2026-11-11 | 任务：补齐乌尔都语 OCR 文案

**Links:** [PR #1391 审查评论](https://github.com/tisfeng/Easydict/pull/1391#issuecomment-6775533749)

### 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-6
- **Environment:** macOS 27.2 / Xcode 27.2 (27B52)

### 用户请求

补齐 PR 审查指出的五条乌尔都语翻译。

### 变更

- 为隐私页自动本地保存开关、说明和三条图片错误提示补充乌尔都语。

### 设计意图

乌尔都语界面使用对应翻译，避免显示英文回退文案。

### 验证

- JSON 与 Git 差异检查通过。Debug 构建通过。
- 核对 Debug 应用包中的五条乌尔都语字符串。在应用隐私页实测开关和说明的显示。
- 三条错误提示核对了打包资源。

### 受影响文件

- `Easydict/App/Localizable.xcstrings`

### 后续事项

- None
