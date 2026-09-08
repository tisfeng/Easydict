# 2026-09-08 按提交移植 Scoco OpenAI 语义

## 状态

进行中

## 用户目标

按 Scoco 的四个连续提交逐个将语义移植到 Easydict，每完成一个阶段就创建一个独立本地
提交，再继续下一阶段。

## 初始状态

- 分支：`dev`
- HEAD：`f61433859af9a6053a6fe63414e1efff8f4b6e1e`
- 工作树和索引均为空。

## 当前进展

- 已完成源提交范围、目标依赖和 Easydict 差异的只读核对。
- 已完成 `58451b5fd` 对应的 MacPaw/OpenAI 迁移实现与验证，等待独立本地提交：
  - 将依赖从 `tisfeng/OpenAI` 固定 revision 迁移至 `MacPaw/OpenAI` 0.5.1，并同步工作区
    `Package.resolved`。
  - 使用项目自有 transport 保留精确 endpoint、Bearer 与 Azure `api-key`、免 Key、SSE
    MIME 校验和流式回退分类。
  - 按原始字节和 LF/CRLF 边界解析 SSE，避免 `AsyncBytes.lines` 丢弃空行导致多 chunk
    合并；非 2xx 响应读取受限错误体并保留 SDK `APIErrorResponse` 诊断。
  - 适配上游消息角色、非流式返回模型、`ChatStreamResult` 创建及 HTTPServer 错误 chunk。

## 阶段验证

### `58451b5fd`

- `xcodebuild test` 定向运行 `OpenAIStreamResultTests` 与
  `OpenAIStreamTransportTests`：两个 suite、6 个测试通过。
- SwiftFormat：变更 Swift 文件均无需再次格式化。
- SwiftLint：变更 Swift 文件 0 violations。
- `swiftc -frontend -parse`、`plutil -lint`、`jq -e` 与 `git diff --check`：通过。
- 独立审查发现并推动修复 SSE 空行分帧和非 2xx 错误体丢失问题；修复后再次请求复审。

证明边界：以上结果不证明真实第三方 OpenAI 兼容服务、用户账户、网络代理或 GUI 行为。

- `58451b5fd` 已提交为 `d058fcec8d60f1b72705ed5357e75de976521d91`。
- 已完成 `283dc6b9b` 对应实现与验证，等待独立本地提交：
  - `StreamService` 默认提供 SDK `ChatQuery.ReasoningEffort.none`，通用 OpenAI 请求编码为
    `reasoning_effort: "none"`，子类可以覆盖该属性。
  - 将原有 `off/high/max` 用户配置访问器重命名为 `configuredReasoningEffort`，DeepSeek 继续
    使用该配置，避免 SDK 默认值改变其既有请求语义。
  - 定向运行 `OpenAIReasoningEffortTests` 与 `OpenAIStreamTransportTests`：两个 suite、
    7 个测试通过；SwiftFormat、SwiftLint、Swift 解析和 `git diff --check` 通过。
- `283dc6b9b` 已提交为 `339714ab425e0aaf3c8ab418af9da25196eba728`。
- 已完成 `3d47fbce8` 对应实现与验证，等待独立本地提交：
  - 使用单一 `OpenAIStreamTaskControl` 管理请求开始、任务安装、完成和取消；新请求开始
    时取消旧任务，陈旧请求的完成或 termination 不会清除当前任务。
  - `BaseOpenAIService.cancelStream()` 同时保留流式协调器与既有非流式 Task 的取消路径。
  - 定向运行 `OpenAIStreamTaskControlTests` 与 `OpenAIStreamTransportTests`：两个 suite、
    8 个测试通过；SwiftFormat、SwiftLint、Swift 解析和 `git diff --check` 通过。

## 计划

见[当前执行计划](../../exec-plans/active/2026-09-08-macpaw-openai-semantic-port.md)。
