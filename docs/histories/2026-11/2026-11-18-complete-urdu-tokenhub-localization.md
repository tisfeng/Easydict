## 2026-11-18 | 任务：补齐 Urdu 的 Tencent TokenHub 条目

**Links:** 无

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

### 用户请求

检查并修复 Xcode 中 Urdu 本地化完成度为 99% 的问题。

### 变更

- 补齐唯一缺失的 `tokenhub_translate` Urdu 条目，沿用品牌名 `Tencent TokenHub`。

### 设计意图

沿用 String Catalog 对品牌名的处理方式，与 Urdu 中同类服务的名称保持一致。

### 验证

- `jq -e . Easydict/App/Localizable.xcstrings` 和 `git diff --check` 通过。
- Xcode String Catalog 将 Urdu 显示为完成，`tokenhub_translate` 显示为已翻译。主目录的 574 个可翻译条目均有完成的 Urdu 文案。
- macOS arm64 Debug 构建通过，构建产物的 `ur.lproj/Localizable.strings` 包含该条目。

### 受影响文件

- `Easydict/App/Localizable.xcstrings`

### 后续事项

- None
