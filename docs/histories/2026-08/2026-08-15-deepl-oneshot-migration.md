## 2026-08-15 | 任务：迁移 DeepL Web oneshot 接口

**Links:** [DLX issue #216](https://github.com/OwO-Network/DLX/issues/216)、[DLX PR #217](https://github.com/OwO-Network/DLX/pull/217)、[执行计划](../../exec-plans/completed/2026-08-15-deepl-oneshot-migration.md)

### 用户请求

修复 DeepL Web 翻译因旧网页 JSON-RPC 接口异常导致的 503，并参考 DLX 的新 oneshot 方案。

### 变更

- 将 Web 翻译切换到 `oneshot-free.www.deepl.com/v1/translate`，增加匿名授权、iOS 客户端 profile 和 oneshot 请求体。
- 复用 `translations` 响应解析，保留官方 API Key 路径和原有回退策略。
- 添加请求/响应协议单元测试，并更新工程文件、执行计划和变更历史。

### 设计意图

只替换受影响的 Web 协议边界，不改变官方 API Key 端点、服务配置或其他翻译服务；自动检测时省略 `source_lang`，避免向 oneshot 发送不支持的 `auto`。

### 验证

- `swiftformat --lint`：通过。
- `swiftc -typecheck` DeepL Codable 模型：通过。
- `plutil -lint Easydict.xcodeproj/project.pbxproj`、`git diff --check`：通过。
- 实际无密钥 oneshot 请求：HTTP 200，返回译文“测试”。
- 定向 Xcode 测试：被现有 `KeyCombo` 编译错误及缺失 Masonry headers 阻断，未发现 DeepL 独立诊断。

### 受影响文件

- `Easydict/Swift/Service/DeepL/DeepLService+Translate.swift`
- `Easydict/Swift/Service/DeepL/DeepLTranslateResponse.swift`
- `EasydictTests/Service/DeepLServiceTests.swift`
- `Easydict.xcodeproj/project.pbxproj`
- `docs/exec-plans/completed/2026-08-15-deepl-oneshot-migration.md`

### 后续事项

- DeepL oneshot 是非公开协议；后续若客户端 profile 或字段变化，需要同步更新请求模型和测试。
