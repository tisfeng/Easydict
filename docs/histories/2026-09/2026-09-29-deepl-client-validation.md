## 2026-09-29 | 任务：统一 DeepL 客户端版本并验证真实服务

**Links:** [PR #1336](https://github.com/tisfeng/Easydict/pull/1336) · [DLX issue #236](https://github.com/OwO-Network/DLX/issues/236)

### 执行上下文

- **Agent Name:** Unknown
- **Model:** Unknown
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

### 用户请求

统一 DeepL 客户端版本号，并移除只验证手动构造请求 fixture 的测试，改为调用真实的 `DeepLService.validate()`。

### 变更

- 将 `kDeepLWebAppVersion` 作为单一版本来源，User-Agent 通过字符串插值复用该值，请求体继续引用同一常量。
- 删除手动构造请求并断言其序列化结果的测试，新增带 `.integration` 标签的 `DeepLService.validate()` 实际翻译验证；保留响应解析单元测试。

### 设计意图

确保 User-Agent 与请求体使用同一 DeepL app version，并让集成用例经过服务实际翻译路径，避免测试只覆盖自造 fixture。

### 验证

- `xcodebuild build-for-testing -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath /Users/tisfeng/Library/Developer/Xcode/DerivedData/Easydict-Agent/Documents_Code_Github_Easydict`：通过；测试目标已编译。
- `git diff --check`：通过。
- 实际联网 `DeepLService.validate()` 测试未运行：当前 `Easydict-debug` 测试宿主已在运行，仓库规则禁止并发启动同 bundle id 的测试宿主。
- 手动检查：生产代码中 `26.52` 仅保留一个字面值；User-Agent 与请求体均从该值生成。

### 受影响文件

- `Easydict/Swift/Service/DeepL/DeepLService+Translate.swift`
- `EasydictTests/Service/DeepLServiceTests.swift`
- `docs/histories/2026-09/2026-09-29-deepl-client-validation.md`

### 后续事项

- 动态读取 App Store 版本及缓存回退未纳入此次改动；仍需另行决定运行时自动更新策略。
