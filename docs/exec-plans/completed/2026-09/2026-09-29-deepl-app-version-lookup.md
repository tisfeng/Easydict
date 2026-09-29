# Dynamically resolve the DeepL Web app version

- 状态：completed
- 创建日期：2026-09-29
- 负责人：Unknown
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/pull/1336；https://github.com/OwO-Network/DLX/issues/236

## 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `Unknown`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

## 背景

DeepL oneshot 请求将同一 App 版本放在请求体和 User-Agent 中。当前版本已收敛到单一常量，但 DeepL 发布新 iOS 版本时仍需手动更新。Apple Lookup API 可按 DeepL App 的 track ID 获取当前 App Store 版本；该值是尽力同步来源，不是 DeepL oneshot 接口的版本兼容承诺。

## 目标与范围

- 目标结果：通过 Apple Lookup API 动态获取 DeepL iOS App 版本，并让同一次 oneshot 请求的请求体与 User-Agent 使用同一个版本值；查询失败时使用缓存或内置回退版本。
- 允许修改路径：DeepL 服务源码、Defaults key、DeepL 测试、必要的 Xcode 工程引用、当前 plan 与对应 history。
- 同任务 history：`docs/histories/2026-09/2026-09-29-deepl-app-version-lookup.md`
- 用户限制：实现并验证；不 push、不创建 PR。
- 非目标：更换 DeepL oneshot API、动态解析 DeepL 网页 JavaScript bundle、变更 API 优先级。
- 验收标准：验证 Lookup 响应的 App 身份和版本格式；24 小时缓存、查询失败回退；请求体和 User-Agent 共享一次解析出的版本；真实 `DeepLService.validate()` 测试保留并可构建。

## 工作计划

1. 添加具备输入校验、持久缓存、并发合并和错误回退的版本提供器。
2. 接入 DeepL Web 请求路径，让版本值一次解析并传入请求体和 User-Agent。
3. 为 Lookup 响应解析及版本有效性添加单元测试，保留真实服务验证测试。
4. 更新 Xcode 工程引用、运行 SwiftFormat、测试构建和适用验证；完成代码审查。
5. 写入 history、归档本计划并创建本地提交。

## 风险与决策

- Apple 返回 App Store 发布的 iOS App 版本，不保证与 DeepL 服务端的版本校验策略同步；动态值只作为 best-effort，缓存和内置版本负责兜底。
- 固定使用 US storefront，避免由本地 Store 国家造成结果变化；远端响应必须匹配 track ID `1552407475`、bundle ID `com.linguee.DeepLMobileTranslator` 与开发者 `DeepL SE`。
- 网络故障不得阻止 DeepL 请求；Lookup 调用应限时并缓存，避免逐条翻译产生外部请求。

## 进度

- [x] 添加版本提供器与持久缓存。
- [x] 接入请求版本参数并添加测试。
- [x] 完成构建、验证、审查、history 与本地提交。

## 验证

- `BuildTools/.build/release/swiftformat --lint ... --config .swiftformat`：通过，0 个文件需要格式化。
- `git diff --check`：通过。
- `xcodebuild build-for-testing -workspace Easydict.xcworkspace -scheme Easydict -destination 'platform=macOS,arch=arm64' -derivedDataPath /Users/tisfeng/Library/Developer/Xcode/DerivedData/Easydict-Agent/Documents_Code_Github_Easydict | xcbeautify`：通过，测试目标构建成功，SwiftLint 无违规。
- `xcodebuild test-without-building -workspace Easydict.xcworkspace -scheme Easydict -destination 'platform=macOS,arch=arm64' -derivedDataPath /Users/tisfeng/Library/Developer/Xcode/DerivedData/Easydict-Agent/Documents_Code_Github_Easydict -only-testing:EasydictTests/DeepLServiceTests | xcbeautify`：通过，6 项测试成功，其中 `DeepLService().validate()` 执行真实翻译成功。
- 代码审查：以 `07eda3834087c6479bc2b7377c54261f3b1bc2aa` 为基线审查本任务全部最终变更；补齐 Lookup 等待期间的取消处理后复验，无未修复 finding。
- Apple Lookup 当前返回 DeepL iOS App 版本 `26.52`。接口只提供商店营销版本，不提供 build；`appBuild` 仍固定为 `5443737`，需在 DeepL 改变版本/build 配对时重新验证。

## 完成条件

- 版本解析用例、DeepL 测试构建、真实集成测试和静态检查通过。
- 生产代码 review 无未修复的有效 finding。
- 对应 history 完成并归档计划；仅提交本任务文件并核对工作树状态。
