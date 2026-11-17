## 2026-10-25 | 任务：刷新 Bing 朗读配置

**Links:** [PR #1368](https://github.com/tisfeng/Easydict/pull/1368)、[C1 原评论](https://github.com/tisfeng/Easydict/pull/1368#discussion_r4355465568)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

修复 C1，运行相关测试验证，完成后本地提交，不 push。

### 变更

- 每次新的 Bing 语音请求开始时，重新读取已持久化的 host、token 和相关配置。
- 传入既有 request ID 的重定向重试沿用当前请求配置。

### 设计意图

翻译请求刷新配置后，后续朗读不再继续信任语音对象初始化时的旧缓存。
通过重新加载配置保持两个请求对象的取消状态独立，避免引入共享可变配置及额外同步机制。
本次为单一请求入口的小范围修复，不创建执行计划。

### 验证

- `xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath "$agent_dd" -only-testing:EasydictTests/BingServiceTests EASYDICT_RELEASE_PACKAGING=YES`：通过，3 个 Swift Testing 用例，0 失败；使用当前 checkout 专用 Agent DerivedData，跳过自动格式化和 lint。
- `git diff --check`：通过。
- `review`：复核配置保存与加载路径、新请求和重定向重试分支、独立取消状态，未发现本次变更引入的可证实缺陷。
- 测试宿主已退出，未遗留本任务启动的 Easydict 实例。

### 受影响文件

- `Easydict/Swift/Service/Bing/BingRequest.swift`
- `docs/histories/2026-10/2026-10-25-refresh-bing-speech-config.md`

### 后续事项

- 现有测试覆盖取消、lookup 失败后的结果保留和重叠网络请求，未直接覆盖翻译刷新配置后再次朗读的场景；本次未新增测试，未运行真实 Bing 语音服务验证。
- 本地提交不推送，GitHub 原评论的线程状态不变。
