# BaseOpenAIService 流处理骨架移植

- 状态：completed
- 创建日期：2026-09-09
- 来源提交：Scoco `e28514fd0b0e09fa90676df13a2f84179fa2988e`

## 目标

将 Scoco 提交中通用的流请求生命周期、传输 hook 和错误副作用边界移植到 Easydict，继续
使用项目自有 `OpenAIStreamTransport`，不引入 Scoco 的订阅后端实现。

## 范围

- `Easydict/Swift/Service/OpenAI/BaseOpenAIService.swift`
- `Easydict/Swift/Service/OpenAI/StreamService+AsyncStream.swift`
- `EasydictTests/Service/OpenAI/BaseOpenAIServiceStreamHookTests.swift`
- `Easydict.xcodeproj/project.pbxproj`
- 本计划与同任务 history

## 约束

- 保留 endpoint、Bearer 与 `api-key` 双头、SSE MIME 验证、非流式 fallback 和现有取消协调。
- 不移植 ScocoAI 登录、账单、模型目录、认证 Alamofire SSE 或 Audio 特例。
- 不 push、pull、rebase 或 merge；验证通过后仅创建一个本地提交。

## 实施步骤

1. 在 Base 提取验证、query、transport 和错误 hook，由公共 runner 保留 chunk 映射与取消。
2. 删除没有调用者的 `chatStreamToContentStream`，保留反向转换入口。
3. 新增确定性 hook 测试并登记 Xcode test target。
4. 运行定向 Xcode 测试、静态检查和独立 review；完成后归档本计划并更新 history。

## 验收标准

- 默认 transport 的 HTTP 兼容语义保持不变。
- hook 测试覆盖请求验证、chunk 映射和错误副作用。
- 取消与既有非流式 fallback 回归测试通过。

## 验证结果

- `BaseOpenAIServiceStreamHookTests`：4 项通过。
- `OpenAIStreamTransportTests`：5 项通过。
- `OpenAIStreamTaskControlTests`：3 项通过。
- `OpenAIReasoningEffortTests`：3 项通过。
- SwiftFormat、SwiftLint、Swift parse、`plutil -lint` 与 `git diff --check`：通过。

## 完成情况

- [x] 通过回调式 transport hook 复用公共流 runner，保留 `OpenAIStreamTransport`。
- [x] 将 URLSession 取消归为正常结束，不触发 provider 错误副作用。
- [x] 删除无调用者的 `chatStreamToContentStream`，保留反向转换入口。
- [x] 新增 hook 测试并登记 Xcode test target。
