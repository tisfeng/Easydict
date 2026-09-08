# 按提交移植 Scoco OpenAI 语义

## 状态

进行中

## 目标

按 Scoco 的 `58451b5fd`、`283dc6b9b`、`3d47fbce8` 和 `e5aa987d8`
顺序，将相应语义适配到 Easydict。每个阶段完成实现、验证和独立本地提交后，再进入下一阶段。

## 授权与限制

- 用户已授权实现，并要求每个源提交对应一个独立本地提交。
- 不执行 fetch、pull、push、rebase、merge、PR 或发布操作。
- 保留 Easydict 的自定义 endpoint、双鉴权头、免 Key 服务、流式校验回退、HTTPServer
  错误 chunk、远程模型获取和非流式取消行为。
- `283dc6b9b` 在 Easydict 中采用用户指定的语义：`StreamService` 默认使用
  `reasoning_effort: "none"`，子类可以按服务能力覆盖。
- 不移植 Scoco 专属的订阅、认证目录、BillingStore、Pi Agent 或后端缓存。

## 初始快照

- 分支：`dev`
- HEAD：`f61433859af9a6053a6fe63414e1efff8f4b6e1e`
- 初始索引、未暂存和未跟踪内容均为空。

## Agent-owned paths

- `Easydict.xcodeproj/project.pbxproj`
- `Easydict.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- `Easydict/Swift/Service/OpenAI/`
- `Easydict/Swift/Feature/HTTPServer/Vapor/routes.swift`
- `EasydictTests/Service/ServiceTests.swift`
- `EasydictTests/Service/OpenAI/`
- `docs/agents/build-and-test.md`
- 本计划与同任务 history。

## 阶段

1. 对应 `58451b5fd`：迁移至 MacPaw/OpenAI 0.5.1，适配请求、SSE、结果模型和取消，
   保留 Easydict 的 MIME 回退及 HTTPServer 契约。实现与定向测试已完成，等待本地提交。
2. 对应 `283dc6b9b`：为 `StreamService` 增加可覆盖的 SDK reasoning effort 默认值
   `.none`，并在通用 OpenAI 请求中编码。实现与定向测试已完成，等待本地提交。
3. 对应 `3d47fbce8`：将迁移阶段的两个取消辅助类型统一为一个加锁任务协调器，覆盖提前
   取消、请求替换和陈旧完成。
4. 对应 `e5aa987d8`：按模块拆分本任务新增测试，更新 Xcode 引用，并补充测试目录规则。

## 验证

- 每阶段运行变更 Swift 的 SwiftFormat、SwiftLint、语法或编译检查、工程 plist 检查和
  `git diff --check`。
- 测试源码发生变化时，使用 `Easydict.xcworkspace` 定向运行相应 suite。
- 请求契约覆盖 endpoint、Bearer/`api-key`、免 Key、SSE、MIME 分类、chunk 编解码、
  reasoning effort 和取消竞态。
- 不以静态检查证明真实第三方服务、账户、网络或 GUI 行为。

## 完成条件

四个阶段均形成独立 Angular-style 本地提交；最终工作树干净，没有 push，并将本计划移动到
`docs/exec-plans/completed/`，由同任务 history 链接。
