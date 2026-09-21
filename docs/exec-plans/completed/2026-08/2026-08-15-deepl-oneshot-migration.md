## DeepL Web oneshot 协议迁移

**Status:** completed
**Created:** 2026-08-15
**Updated:** 2026-08-15
**Owner:** tisfeng
**Links:** https://github.com/OwO-Network/DLX/issues/216、https://github.com/OwO-Network/DLX/pull/217

## 目标

将 Easydict 的 DeepL Web 翻译从已失效的 `www2.deepl.com/jsonrpc` 迁移到
DeepL oneshot JSON 接口，同时保留 DeepL 官方 API Key 路径和现有回退策略。

## 范围

- 包含范围：Web 请求端点、请求头、请求体、语言代码、响应解析、协议单元测试和
  变更记录。
- 不包含范围：DeepL 官方 API Key 请求、服务配置 UI、其他翻译服务和远程 Git 操作。

## 背景

- 当前 Web 路径使用 `LMT_handle_texts` JSON-RPC 请求，用户报告该路径返回 503。
- DLX issue #216 后续的 #217 迁移到 `oneshot-free.www.deepl.com/v1/translate`，
  使用 `Authorization: None` 和 `translations` 响应结构。
- Easydict 使用 Alamofire，Web 和官方 Key 路径共享同一个服务类。

## 风险与缓解

- 风险：oneshot 接口使用非公开协议，客户端信息字段可能随 DeepL 更新。
  - 缓解措施：集中定义协议常量和 Codable 请求模型，并用无网络测试锁定字段。
- 风险：自动检测或中英文区域代码不符合 oneshot 要求。
  - 缓解措施：自动检测时省略 `source_lang`，并显式规范目标语言代码。
- 风险：官方 Key 回退被 Web 迁移误伤。
  - 缓解措施：保持 `deepLTranslate` 独立，仅复用响应解析。

## 里程碑

- [x] 确认范围和约束。
- [x] 实现 oneshot 请求和响应适配。
- [x] 添加协议单元测试并验证工程配置。
- [x] 验证行为和文档，归档本计划。

## 验证

- `swiftformat --lint`：3 个修改的 Swift 文件均无需格式化。
- `swiftc -typecheck`：DeepL Codable 请求/响应模型通过 Xcode beta Swift 编译器类型检查。
- `plutil -lint Easydict.xcodeproj/project.pbxproj`：通过。
- `git diff --check`：通过。
- 手动 HTTP 验证：oneshot endpoint 返回 HTTP 200，`translations[0].text` 为“测试”。
- `xcodebuild test -only-testing:EasydictTests/DeepLServiceTests`：未完成；Xcode beta
  先后受现有 `ShortcutManager+Validator.swift` 的 `KeyCombo` Optional 错误和缺失本地
  CocoaPods Masonry headers 阻断，未发现 DeepL 文件独立编译诊断。

## 决策记录

- 2026-08-15：只替换 Web 路径；官方 API Key 路径保留原有端点和配置行为。
- 2026-08-15：采用 DLX 当前 oneshot 请求形状，包括 `usage_type`、`app_information`
  和 `x-app-*` 请求头；不复制 Go 客户端专用的 TLS 指纹逻辑。

## 进度记录

- 2026-08-15：确认当前工作树干净，阅读仓库规则，核对现有 DeepL 实现和 DLX 迁移方案。
- 2026-08-15：完成实现、工程测试引用、协议单元测试和实际 oneshot 请求验证。
