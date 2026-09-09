# 2026-09-09 BaseOpenAIService 流处理骨架移植

## 状态

已完成

## 用户目标

将 Scoco 提交 `e28514fd0` 的通用 OpenAI 流处理语义适配移植到 Easydict。

## 初始快照

- HEAD：`6933e4c94465d4e9cbc2f80e65f43f8a6df990e8`
- 分支：`refactor/migrate-to-macpaw-openai`
- 工作树与索引：干净

## 范围与边界

- 移植公共请求生命周期与可覆盖 transport/error hook。
- 保留 Easydict 自有 endpoint、认证头、SSE MIME 验证、非流式 fallback 与取消语义。
- 不引入 Scoco 的认证、订阅、账单、模型目录或 Alamofire SSE 后端代码。

## 计划

见[已完成执行计划](../../exec-plans/completed/2026-09-09-base-openai-stream-hooks.md)。

## 完成内容

- `BaseOpenAIService` 将 endpoint/API key 校验、`ChatQuery` 构造、回调式流传输和错误
  副作用拆为可覆盖 hook；公共 runner 保留 delta 映射、UUID 任务协调、streaming 开关和
  非流式 fallback。
- 默认 transport 继续使用 `OpenAIStreamTransport`，保留精确 endpoint、Bearer 与
  `api-key` 双头、SSE MIME 验证与错误响应解析。
- URLSession 的 `URLError.cancelled` 与 `NSURLErrorCancelled` 和 `CancellationError` 一样
  被视为正常结束，避免取消请求触发 provider 的业务错误副作用。
- 删除无调用者的 `chatStreamToContentStream`；新增确定性 hook 测试并同步 Xcode test target。

## 验证记录

- 定向 Xcode 测试通过：`BaseOpenAIServiceStreamHookTests` 4 项、
  `OpenAIStreamTransportTests` 5 项、`OpenAIStreamTaskControlTests` 3 项、
  `OpenAIReasoningEffortTests` 3 项。
- SwiftFormat、SwiftLint、Swift parse、`plutil -lint` 与 `git diff --check` 均通过。
- 独立审查发现 URLSession 取消会误触发 error hook；修复并补充取消测试后进行增量复核。

证明边界：未验证真实第三方 OpenAI 兼容服务、用户账户、网络代理或 GUI 行为。
