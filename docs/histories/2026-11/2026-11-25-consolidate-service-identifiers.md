## 2026-11-25 | 任务：统一服务 ID 解析并补齐服务总览

**Links:** [执行计划](../../exec-plans/completed/2026-11/2026-11-25-consolidate-service-identifiers.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `gpt-6.2-astra`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

### 用户请求

补齐中英文服务总览，合并服务 ID 解析，移除查询等级未使用的英文分支，验证并本地提交。

### 变更

- 两份总览都增加内置的「这是什么」（Explain），以及使用本机 CLI 的 GitHub Copilot 和配置指南链接。
- 服务工厂和配置存储共用 `ServiceIdentifier` 取得基础类型和实例 ID。
- 查询次数日志和统计事件直接使用已有中文等级标题。

### 设计意图

只把第一个 `#` 作为分隔符，保留实例 ID 中的其他字符。旧配置键继续使用显式传入的实例 ID，
让各窗口能够读到原有服务配置。

### 验证

- 对照工厂注册表和两份总览：每份均列出 31 个服务 ID，各出现一次，相对链接和锚点可达。
- 用 Swift 对照修改前后的实现：13 组 ID、117 组配置键、63 组服务去重判断、14 组等级标题及
  30 组查询次数边界全部一致。
- macOS Debug 的 `Default` 计划定向运行 GitHub Copilot 服务、Claude Code 工厂注册和 Codex
  配置迁移测试。`xcresult` 记录 12 项通过、0 项失败、0 项跳过。
- `git diff --check` 通过。审查了服务创建与去重、旧配置读取和统计调用方，未发现需修复的问题。

### 受影响文件

- `Easydict/Swift/Service/Model/QueryServiceFactory.swift`
- `Easydict/Swift/Service/Model/Storage/LocalStorage.swift`
- `Easydict/Swift/Service/Model/Storage/QueryUsageStore.swift`
- `docs/user-docs/en/SERVICES.md`
- `docs/user-docs/zh/SERVICES.md`

### 后续事项

None
