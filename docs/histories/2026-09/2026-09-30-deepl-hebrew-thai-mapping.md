# 补全 DeepL 希伯来语与泰语语言映射

- 日期：2026-09-30
- 状态：completed
- 关联 Issue/PR：none
- 执行计划：none

## 执行上下文

- **Agent Name:** `ZCode`
- **Model:** `account:zai-start-plan/GLM-5.3-Flash`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

## 用户请求

双向补齐 Easydict 与 Scoco 的 DeepL 语言表差异：Scoco 已于 2026-09-26 补全 he/th
（见其 `docs/histories/2026-09/2026-09-26-deepl-hebrew-thai-mapping.md`），上游 DeepL 语言表
仍缺这两个语言码，本次在 Easydict 仓库补齐。

## 设计意图

DeepL 于 2025-06-24 与越南语同期新增希伯来语与泰语。`EZLanguageHebrew`、`EZLanguageThai`
已存在于语言模型，Google、Bing、百度、NiuTrans 等服务均已映射，唯独 DeepL 的
`supportLanguagesDictionary()` 与 `languageCode(for:)` 缺失，导致两者无法作为 DeepL 的
源语言或目标语言使用。

边界：沿用 Scoco 已验证的写法，在越南语之后成对追加；不改动 `oneshotLanguageCode` 与
`removeLanguageVariant`，两者的 `default` 分支已对无变体语言码原样透传。

## 主要变更

- `Easydict/Swift/Service/DeepL/DeepLService.swift` 的 `supportLanguagesDictionary()` 在
  `Language.vietnamese, "vi"` 之后、`NSNull()` 之前增加 `Language.hebrew, "he"` 与
  `Language.thai, "th"`。
- 同文件 `languageCode(for:)` 在 `case .vietnamese` 之后增加 `case .hebrew: return "he"` 与
  `case .thai: return "th"`。

两处必须成对修改：只改其一会出现"UI 可选但查询失败"的半成品状态。

## 验证

- 数组配对奇偶性：追加两对映射后 `stride(to: count - 1, by: 2)` 边界不变。
- `swiftformat --lint` 通过（0/1 文件需要格式化）；`git diff --check` 通过。
- `xcodebuild build-for-testing` 返回 `** TEST BUILD SUCCEEDED **`（Easydict-Agent 专用
  DerivedData）。
- `test-without-building -only-testing:EasydictTests/DeepLServiceTests` 6/6 用例通过，其中
  真网集成用例（3.1s）继续通过；现有测试不覆盖语言映射，证明的是编译与既有行为未回归。

## 后续事项

- oneshot 私有接口对 `he`/`th` 的接受情况无法离线确认，需真机各跑一次希伯来语、泰语与中文
  互译，覆盖 oneshot 与 authKey 两条路径（与 Scoco 侧 2026-09-26 记录的待办相同）。
