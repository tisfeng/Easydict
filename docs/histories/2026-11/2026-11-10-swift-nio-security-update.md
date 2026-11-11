## 2026-11-10 | 任务：更新 SwiftNIO 安全修复版本

**Links:** [执行计划](../../exec-plans/completed/2026-11/2026-11-10-swift-nio-security-update.md) · [Dependabot 告警](https://github.com/tisfeng/Easydict/security/dependabot)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B52)`

### 用户请求

优先修复 Dependabot 报告的 SwiftNIO 相关问题。

### 变更

- 将 SwiftNIO、SwiftNIO Extras 和 SwiftNIO HTTP/2 分别锁定到 `2.100.0`、`1.34.1` 和 `1.44.0`，并在 Xcode 工程中声明对应的最低版本。
- 随 Extras 更新 Swift HTTP Types 和 Swift Async Algorithms，并加入 Swift HTTP Structured Headers 和 Swift Service Lifecycle。

### 设计意图

覆盖六条现有告警所需的最低修复版本。仅更新锁文件时，Xcode 自动解析将 Extras 回退到 `1.26.0`。工程约束防止重新解析时选中受影响版本，同时允许兼容更新。

### 验证

- GitHub Dependabot 告警 #10、#18、#19、#20、#22、#26 的最低修复版本均已满足，锁定 revision 与上游标签一致。
- `xcodebuild build` 使用 `Easydict` scheme、arm64 Debug、独立 DerivedData 和 `-onlyUsePackageVersionsFromResolvedFile` 构建成功。构建前后的锁文件字节一致。
- 实际 Debug 应用通过回环 HTTP/1.1 检查，覆盖首页、gzip 请求语言检测、Apple Dictionary 查词，以及普通和流式翻译路由的 HTTP 400 响应。验证后退出测试实例并恢复临时偏好。
- 工程和锁文件格式检查、`git diff --check` 通过。审查最终依赖差异未发现可操作问题。

### 受影响文件

- `Easydict.xcodeproj/project.pbxproj`
- `Easydict.xcworkspace/xcshareddata/swiftpm/Package.resolved`

### 后续事项

- 本次验证未覆盖外部模型的成功 SSE 流、HTTP/2 入站和其他 macOS 版本。
