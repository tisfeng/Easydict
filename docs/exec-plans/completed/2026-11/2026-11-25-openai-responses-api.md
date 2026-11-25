# Custom OpenAI Responses API

<!-- 文件名：2026-11-25-openai-responses-api.md；命名规则见 docs/histories/README.md 的“命名与 slug”。 -->

- 状态：completed
- 创建日期：2026-11-25
- 负责人：Grok 4.7
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/issues/1306

## 执行上下文

- **Agent Name:** `Grok 4.7`
- **Model:** `Grok 4.7`
- **Environment:** `macOS Unknown / Xcode Unknown (Unknown)`。当前执行环境是 Linux，没有 `sw_vers`、`swift` 或 `xcodebuild`。

## 背景

自定义 OpenAI 只发送 Chat Completions（`/chat/completions` + `messages`）。部分兼容网关只接受 Responses API（`/responses` + `input`）。维护者已同意支持 Responses。已有未合并的 #1307 仍停在 review，当前 `dev` 没有该能力。

## 目标与范围

- 目标结果：自定义 OpenAI 可选择 Chat Completions 或 Responses。Responses 请求走 `/responses` 和 `input`；已识别后缀在切换时互换；裸 base URL 只在 Responses 下追加后缀；SSE 按 `data.type` 分类。Chat Completions 的既有请求保持不变。
- 允许修改路径：OpenAI/Custom OpenAI 服务、设置视图、配置 key、本地化、用户服务说明、对应单元测试、Xcode 工程引用、本计划与 history。
- 同任务 history：`docs/histories/2026-11/2026-11-25-openai-responses-api.md`
- 用户限制：基于 `dev` 的 `feat/responses-api-1306`；不使用自动关闭关键字；不向 fork 本身开 PR；不破坏 Chat Completions。
- 非目标：自定义请求头、改内置 OpenAI/DeepSeek 等服务的协议、真实 opencode 端点联调。
- 验收标准：默认仍为 Chat Completions；无法识别的完整 URL 不被追加后缀；Responses 流式任务走现有 `cancelStream()`；非 2xx、非完成状态和错误 SSE 会失败；`text/event-stream` 以外的流式成功响应用现有 content-type 错误表达。

## 工作计划

1. 增加接口类型、endpoint 适配和 Responses 请求/解析。
2. 只在自定义 OpenAI 设置中露出选择器，并在切换时改写已识别 endpoint。
3. 用现有流任务槽发起 Responses 请求，Chat 路径仅在自定义服务且 URL 以 `/responses` 结尾时改回 Chat Completions。
4. 补纯函数测试、本地化、服务说明和工程引用。
5. 在当前环境能做的静态检查后审查 diff。

## 风险与决策

- 现有完整 URL 若不是 `/chat/completions` 或 `/responses`，两种模式都保持原样，避免升级后把 `https://host/api/chat` 改成不可用地址。
- 裸 base URL（空路径或版本段，如 `…/v1`）只在 Responses 下追加后缀。Chat 默认不追加，因此现有 Chat 配置不变。
- 新请求使用 Alamofire async/await。官方 `api.openai.com` 发送 `store: false`；其他主机省略该字段，避免不识别的网关拒绝请求。不发送 temperature，避免拒绝采样参数的模型失败。
- Responses 流式和非流式取消分别复用 `OpenAIStreamTaskControl`，不新增另一套无标识任务槽。
- opencode go 需要的 `x-opencode-session` 仍不在本次范围。

## 进度

- [x] 实现服务、设置和测试
- [x] 静态检查与审查
- [x] 归档计划并写 history

## 验证

- `jq -e . Easydict/App/Localizable.xcstrings`：通过。
- `git diff --check`：通过。
- 对照 Alamofire 5.12.2 源码核对 `streamRequest`、`streamingData`（失败类型为 `Never`）和 completion 字段。
- 未运行 `xcodebuild build` / `xcodebuild test`：环境没有 Xcode。
- 未做界面验收：环境不能运行 macOS 应用。

## 完成条件

- 范围内的实现和测试已落地。
- history 已记录验证限制。
- 计划移到 `completed/2026-11/`。
