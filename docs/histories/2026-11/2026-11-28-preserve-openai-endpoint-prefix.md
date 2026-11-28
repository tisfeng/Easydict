## 2026-11-28 | 任务：保留自定义 OpenAI 端点的编码前缀

<!-- 文件名：2026-11-28-preserve-openai-endpoint-prefix.md；命名规则见 docs/histories/README.md 的“命名与 slug”。 -->

**Links:** [PR #1420](https://github.com/tisfeng/Easydict/pull/1420) · [审查意见](https://github.com/tisfeng/Easydict/pull/1420#discussion_r4726135644)

### 执行上下文

- **Agent Name:** `Junior`
- **Model:** `Unknown`
- **Environment:** `macOS 26.1 / Xcode 26.0.1 (17A400)`

### 用户请求

修复切换自定义 OpenAI API 类型时编码路由前缀被改写的问题，并更新现有 PR。

### 变更

- 在 `percentEncodedPath` 上仅替换已知 API 后缀；保留路由前缀、查询和片段。

### 设计意图

网关可能把 `%2F` 视为单个路径段的数据，而不是分隔符。API 类型切换不应改变网关所选的路由。

### 验证

- Swift 6.2 本地检查：旧实现通过 6/10，修复后通过 10/10。覆盖双向切换、编码前缀、原查询与片段、裸版本路径和未知路径。
- `git diff --check`：通过。
- `xcodebuild test`：默认缓存路径不可用；使用隔离缓存重试时，因磁盘剩余空间不足在依赖解析阶段停止，未运行 Xcode 测试。

### 受影响文件

- `Easydict/Swift/Service/OpenAI/OpenAIAPIType.swift`

### 后续事项

- 未操作真实网关或更改本机应用的服务设置。
