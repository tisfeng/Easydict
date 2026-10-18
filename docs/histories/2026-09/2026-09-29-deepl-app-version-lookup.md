## 2026-09-29 | 任务：动态获取 DeepL Web App 版本

<!-- 文件名：YYYY-MM-DD-<slug>.md；命名规则见 docs/histories/README.md 的“命名与 slug”。 -->

**Links:** [PR #1336](https://github.com/tisfeng/Easydict/pull/1336)；[DLX issue #236](https://github.com/OwO-Network/DLX/issues/236)；[执行计划](../../exec-plans/completed/2026-09/2026-09-29-deepl-app-version-lookup.md)

### 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `Unknown`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

### 用户请求

从 Apple Lookup API 动态获取 DeepL iOS App 版本，避免版本号在请求体和 User-Agent 中重复维护；保留真实 `DeepLService.validate()` 验证。

### 变更

- 新增 `DeepLWebAppVersionProvider`，校验 App Store 响应身份与版本格式，使用 24 小时持久缓存、15 分钟失败重试间隔、3 秒请求超时，并在失败时回退到 `26.52`。
- DeepL oneshot 请求将同一次解析的版本传给请求体和 User-Agent。
- 版本查询等待期间支持取消，避免取消后仍发送翻译请求。
- 在 `DeepLServiceTests` 保留真实服务验证，并添加 Lookup 响应校验用例。

### 设计意图

Apple Lookup 可按固定 track ID 查询商店当前营销版本，不依赖解析 DeepL 的网页资源；缓存与固定回退让商店接口临时不可用时仍可翻译。Apple API 不返回 App build，因此 `appBuild = 5443737` 仍为固定值，版本/build 配对变化仍需验证 DeepL oneshot 的兼容性。

### 验证

- `BuildTools/.build/release/swiftformat --lint ... --config .swiftformat`：通过，0 个文件需要格式化。
- `git diff --check`：通过。
- `xcodebuild build-for-testing -workspace Easydict.xcworkspace -scheme Easydict -destination 'platform=macOS,arch=arm64' -derivedDataPath /Users/tisfeng/Library/Developer/Xcode/DerivedData/Easydict-Agent/Documents_Code_Github_Easydict | xcbeautify`：通过，测试目标构建成功，SwiftLint 无违规。
- `xcodebuild test-without-building -workspace Easydict.xcworkspace -scheme Easydict -destination 'platform=macOS,arch=arm64' -derivedDataPath /Users/tisfeng/Library/Developer/Xcode/DerivedData/Easydict-Agent/Documents_Code_Github_Easydict -only-testing:EasydictTests/DeepLServiceTests | xcbeautify`：通过，6 项测试成功，包括真实 `DeepLService.validate()` 翻译。
- 代码审查以 `07eda3834087c6479bc2b7377c54261f3b1bc2aa` 为基线，覆盖本任务全部变更；取消时序 finding 已修复并重新构建、测试，无未解决 finding。
- Apple Lookup 当前版本为 `26.52`；marketing version 可动态读取，build number 无法从该接口获取。

### 受影响文件

- `Easydict/Swift/Service/DeepL/DeepLWebAppVersionProvider.swift`
- `Easydict/Swift/Service/DeepL/DeepLService+Translate.swift`
- `Easydict/Swift/Feature/Configuration/Defaults.Keys+Extension.swift`
- `EasydictTests/Service/DeepLServiceTests.swift`
- `Easydict.xcodeproj/project.pbxproj`
- `docs/exec-plans/completed/2026-09/2026-09-29-deepl-app-version-lookup.md`

### 后续事项

- `appBuild` 仍固定为 `5443737`；当 DeepL 发布新的 App 版本时，验证 marketing version 与 build 配对是否仍兼容 oneshot 接口。
