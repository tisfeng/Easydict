## 2026-10-19 | 任务：隔离词典 CSS 嵌入预算与缓存

**Links:** [执行计划](../../exec-plans/completed/2026-10/2026-10-19-css-embedding-budget.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.1 (27A9275)`

### 用户请求

移植 Scoco CSS 预算与缓存修复，验证和 review 通过后本地提交，不 push。

### 变更

- 来源为 Scoco 本地提交 `fde8e3db77be9e4e6a4ae5ddcf25d3dc59cb5fc7`；目标基线为 `b9514c9f3b292d1068396d24512f56b8fc5560c7`。
- 外部 CSS 在 ResourceEmbeddingState 临时副本中解析子资源；外层只累计最终 CSS data URL 的体积，避免重复计费。
- 最终 CSS 通过预算检查后才合并资源缓存；失败时不改变外层预算、缓存和递归状态。
- 保留路径与符号链接边界、字体/文件上限、重复引用计费、片段和循环/深度保护。未移植 `b03e9ac38` 无结果修复：目标渲染器已有空词条提前返回保护。
- 未新增或扩写测试；更新并归档同任务执行计划。

### 设计意图

适配 Easydict 现有资源处理流程，利用值语义隔离临时工作；成功时仅合并 dataURLs，不提交临时 embeddedBytes 或 loadingURLs。避免为局部缺陷引入第二套资源加载器或改变全局资源限额。

### 验证

- arm64 Debug、checkout 专属 Agent DerivedData 下 `xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath <checkout-agent-derived-data> -disableAutomaticPackageResolution -only-testing:EasydictTests/AppleDictionaryTests`：通过。xcresult 确认 5 项测试、6 次执行，0 失败、0 跳过、0 runtime warning；覆盖相同配置的构建集成。
- SwiftFormat 0.63.0 lint、Swift frontend parse 和 `git diff --check`：通过。
- Review：冻结初始 HEAD 和生产文件摘要，检查完整 raw diff、相关调用链、现有测试、CSS 嵌套/失败/缓存复用与递归状态；无有效 finding。原有值类型状态足够完成隔离，无需扩大重构。
- 测试与 review 后生产 SHA-256 保持 `a02d0c4a817648d29e1280b37c454d63d62242e2eb666786fd00f1dde48d0bad`，未影响主 checkout。
- 手动检查：未运行真实词典 UI。

### 受影响文件

- `Easydict/Swift/Service/Dictionary/AppleDictionary/AppleDictionary.swift`
- `docs/exec-plans/completed/2026-10/2026-10-19-css-embedding-budget.md`
- `docs/histories/2026-10/2026-10-19-css-embedding-budget.md`

### 后续事项

- 现有 suite 没有嵌套 CSS 和预算失败的专属断言，相关边界已作语义审查；未做真实词典 UI 验收。补充专属测试需另行获得新增测试授权。
- 本次在独立任务分支本地提交，未合并到 dev，不 push。
