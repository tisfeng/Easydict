## 2026-11-20 | 任务：统一 Codex MCP 隔离与发送前复核

**Links:** [执行计划](../../exec-plans/completed/2026-11/2026-11-20-codex-mcp-isolation.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

### 用户请求

统一 Easydict 和 Scoco 的 MCP 隔离与发送前复核，保留运行时、连接逻辑和结果处理。
不新增测试；验证和 review 通过后仅本地提交，不合入 dev、不 push。

### 变更

- 任务基线 `8ede70eaa053bd0e51154c48ea8d5c553f8a240f`，独立任务分支，初始索引和工作树干净。
- 提取与 Scoco 一致的 `CodexMCPIsolation`，解析有效 MCP、生成逐项禁用的 TOML 覆盖并验证线程权限。
- 本机 CLI 初始化发现启用的 MCP 时，仅在创建线程前重启一次并复核；并发等待者等待最终可用连接。
- 长期连接上每次新建线程前重读有效配置；新增未隔离 MCP 时拒绝本次请求，保留正在运行的翻译。
- 发送内容前检查返回的线程权限和取消状态；失败线程沿用原有清理路径；内置运行时独立环境与认证保持原样。
- 为隔离失败添加 7 个现有 locale 的明确提示，更新工程引用；未新增或扩写测试。

### 设计意图

Codex 配置采用递归表合并，空表不能清除继承条目，显式禁用后仍需检查有效配置。
参考 [官方合并实现](https://github.com/openai/codex/blob/rust-v0.166.0/codex-rs/config/src/merge.rs)
和 [App Server 协议](https://learn.chatgpt.com/docs/app-server#api-overview)。

在既有 OCR 和翻译路径上统一隔离契约，复用已有 App Server 多路复用、取消和结果处理；
不将 Scoco 的单请求进程模式迁入 Easydict。内置运行时仍拒绝意外外部配置。

### 验证

- Swift 语法、隔离策略类型检查、工程文件、String Catalog JSON 和 `git diff --check` 通过；Scoco 适配器完整类型检查通过。
- 实际 Codex CLI 0.166.0：有效配置中 2 个启用 MCP 经进程级逐项覆盖后复核为 0；线程只读、网络关闭、禁止审批、ephemeral 通过。
- 官方固定运行时 0.134.0/0.153.4：归档和二进制 SHA 与仓库 manifest 一致，codesign 校验通过；独立临时环境中有效 MCP 表和上述线程权限均实际通过。
- 协议检查未发送模型输入；未修改用户 Codex 配置文件，未退出或替换用户应用实例。
- 最终增量 `xcodebuild test`：58 项 Codex 运行时、命令进程、服务、协调器、流式失效、环境与账号恢复测试通过；最终 Debug app 的 codesign deep/strict 通过；新 helper lint 警告清零。
- Easydict 现有 `LocalEnvironment/CodexFormulaImageTests`：真实本机 CLI 的公式图 OCR、流式数学翻译和公式排版断言 2 项通过。固定测试图和源码中的数学文本已核实无个人数据，使用现有默认 OpenAI 服务配置。
- 最终 review（自审）覆盖冻结源码 diff、新 helper、配置异常、重试等待者、权限/取消与失败清理，无未解决 finding；两仓库校验组件除产品文件头外一致。
- 未另做窗口交互验收；Scoco 未独立运行真实模型识图；内置 0.134.0/0.153.4 的实测限于协议与权限边界。

### 受影响文件

- `Easydict/Swift/Service/Codex/AppServer/CodexMCPIsolation.swift`
- `Easydict/Swift/Service/Codex/AppServer/CodexAppServer.swift`
- `Easydict/Swift/Service/Codex/AppServer/CodexAppServerProcess.swift`
- `Easydict/Swift/Service/Codex/LocalCLI/CodexCLIInstallation.swift`
- `Easydict/Swift/Service/Codex/Service/CodexServiceError.swift`
- `Easydict/App/Localizable.xcstrings`
- `Easydict.xcodeproj/project.pbxproj`
- 本任务 plan/history。

### 后续事项

- 仅在 `fix/codex-mcp-isolation` 任务分支本地提交；未合入 dev、未 push。
- 可在后续单独授权后补充专门的隔离异常与并发回归测试。
