# 复用 Codex App Server 翻译进程

- 状态：completed
- 创建日期：2026-09-14
- 完成日期：2026-09-14
- 负责人：Codex
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/pull/1303#issuecomment-5654806361

## 背景

托管 Codex 翻译原先为每次请求启动独立的 `codex exec --json` 进程。代理环境中上游
WebSocket 连接失败时，每个新进程都会重新经历重试与 HTTPS 回退，造成显著且重复的延迟。
用户要求改为复用常驻进程，同时保持不同翻译请求之间的上下文、取消和结果隔离。

## 目标与范围

- 目标结果：托管模式复用一个应用级 Codex App Server，每次翻译使用独立临时 thread，直接使用
  HTTPS 上游传输，并按 turn 独立取消。
- 允许修改路径：`Easydict/Swift/Service/CodexCLI/`、`Easydict.xcodeproj/project.pbxproj`、
  本计划及对应 history。
- 同任务 history：`docs/histories/2026-09/2026-09-14-codex-app-server-reuse.md`
- 用户限制：按已确认方案直接执行；不 push，不创建 PR。
- 非目标：不改变本机 CLI 模式，不自行管理 ChatGPT token，不复用不同翻译的模型上下文，不新增
  或扩写测试代码。
- 验收标准：支持的托管运行时复用 App Server；请求使用临时 thread；取消不终止其他请求；上游
  不尝试 WebSocket；进程异常后可按需恢复；现有相关测试和构建通过。

## 工作计划

1. 核对 0.134.0 与 0.153.4 固定组件的 App Server 协议和配置兼容性。
2. 实现长生命周期 JSON-RPC 进程、请求与事件分发、超时、取消和崩溃清理。
3. 将托管翻译切换为独立临时 thread，并保留登录、配置失效和结果归属边界。
4. 配置应用私有 provider，关闭上游 WebSocket，保持 ChatGPT Keychain 登录来源。
5. 更新工程引用，运行格式检查、现有相关测试、构建和真实连续翻译验证。
6. 记录 history、归档计划并创建本地提交。

## 风险与决策

- 共享进程不共享翻译 thread；每个请求创建 `ephemeral` thread，避免上下文污染和文本落盘。
- 普通取消使用 `turn/interrupt`，只释放对应 thread，不终止其他窗口的请求。
- JSON-RPC 请求和完整翻译分别设置超时；App Server EOF、协议损坏或 RPC 超时会使当前在途请求
  失败，后续请求重新校验组件并启动新进程，但不自动重发用户文本。
- 账号登录、登出、重置和组件失效时终止共享进程，防止旧进程继续持有失效身份或组件状态。
- 两个固定运行时均支持所需稳定协议；0.134.0 缺少 `thread/delete`，因此使用
  `thread/unsubscribe` 释放旧版临时 thread。
- 使用应用私有 model provider 并声明 `supports_websockets=false`，直接选择 HTTPS Responses
  传输；ChatGPT 登录仍由官方 Keychain 流程维护。

## 进度

- [x] 确认问题与目标架构。
- [x] 核对两个固定运行时。
- [x] 完成长生命周期进程和托管翻译接入。
- [x] 完成验证与真实连续翻译检查。
- [x] 记录 history、归档计划并提交。

## 验证

- 0.134.0 与 0.153.4 App Server JSON schema：均包含 `thread/start` 的 `ephemeral`、
  `turn/start`、`turn/interrupt`、流式 agent message 和 token usage 通知。
- 真实连续请求探针：同一 App Server PID 完成两个不同临时 thread 的翻译，未出现 WebSocket
  连接、重试或 HTTPS 回退日志。
- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict | xcbeautify`：通过，包含格式、
  lint、Codex 组件准备、签名和应用验证。
- 12 个现有 Codex 相关 suite：158 个测试全部通过，无失败或跳过。
- 对 6 个变更 Swift 文件运行 `swiftformat --lint --config .swiftformat`：通过。
- `plutil -lint Easydict.xcodeproj/project.pbxproj`：通过。
- `git diff --check`：通过。

## 完成条件

- 生产代码、工程引用和文档差异范围清晰。
- 现有相关测试、完整构建、SwiftFormat 和 `git diff --check` 通过。
- 真实连续请求确认 App Server PID 复用、请求上下文隔离且无 WebSocket 重试。
- history 完成，计划已归档到 `docs/exec-plans/completed/2026-09/`。
