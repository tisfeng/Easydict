# 统一 Codex MCP 隔离与发送前复核

- 状态：completed
- 创建日期：2026-11-20
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

## 背景

Codex OCR 源自 Easydict。Scoco 适配期间补充了有效 MCP 配置枚举和显式禁用，
Easydict 本机 CLI 仍传空表。配置表递归合并使空表不能清除用户的已有 MCP。

## 目标与范围

- 目标结果：统一有效配置检查、显式禁用与复核，以及发送内容前的线程权限检查。
- 允许修改路径：Easydict/Swift/Service/Codex/、Easydict.xcodeproj/project.pbxproj，以及主 String Catalog 和本任务 plan/history。
- 同任务 history：`docs/histories/2026-11/2026-11-20-codex-mcp-isolation.md`
- 用户限制：不新增或扩写测试；验证和 review 通过后仅本地提交，不合入 dev、不 push。
- 非目标：更换运行时、认证、连接生命周期或 OCR/翻译结果处理。
- 验收标准：本机 MCP 显式禁用且有效配置复核通过后才能创建线程；线程权限、取消状态通过后才能发送内容；保留原有并发和连接行为。

## 工作计划

1. 在两个独立任务工作树中记录基线并实现相同的隔离策略。
2. 运行现有相关测试、构建及静态检查；可用时使用真实 CLI 检查协议兼容。
3. 使用 review 技能自审完整 diff 与并发、失败、取消路径，修复有效 finding 并复验。
4. 更新 history、归档计划并各自本地提交。

## 风险与决策

- 保留 Easydict 内置独立环境和长期连接，Scoco 保留单请求连接。
- MCP 覆盖使用带引号的 TOML 表键，避免服务器名称被误解为点分配置路径。
- 检查不通过时停止当前请求，不发送原文或图片，不修改用户的 Codex 配置文件。
- 必须兼容 Easydict 内置 0.134.0/0.153.4 与本机 CLI 0.166.0 的实际协议。

## 进度

- [x] 读取现行规则，检查干净基线，创建独立工作树。
- [x] 实现统一策略、错误提示及发送前取消检查。
- [x] Xcode 构建和现有测试通过。
- [x] 最终源码快照 review（自审）通过，准备仅任务分支本地提交。

## 验证

- 独立任务基线：`8ede70eaa053bd0e51154c48ea8d5c553f8a240f`，初始工作树与索引干净。
- 两边共享的 MCP 策略源码一致；Swift 语法、Scoco 适配器完整类型检查、工程文件和 String Catalog 解析、diff 空白检查通过。
- 本机 Codex CLI 0.166.0：真实有效配置含 2 个启用 MCP，进程级逐项覆盖后复核为 0；线程只读、网络关闭、禁止审批、ephemeral 均通过。
- Easydict 固定 0.134.0/0.153.4：官方包通过仓库 manifest 的归档和二进制 SHA 校验及 codesign 校验；在独立临时环境实际验证有效 MCP 表与线程权限。上述协议检查均未调用 turn/start 或发送模型输入。
- 最终增量 `xcodebuild test` 通过：Easydict 58 项 / Scoco 19 项现有测试；最终 Debug 产物 codesign deep/strict 通过，新 helper 无 lint 警告。Easydict 复用用户主 checkout 既有的三项本机 Debug 签名设置，不改工程签名配置。
- Easydict 复用现有 `LocalEnvironment` 的 `CodexFormulaImageTests`：真实本机 CLI 的固定公式图 OCR、流式数学翻译和公式排版断言 2 项通过；无新增测试。
- 最终 review（自审）覆盖原始 diff、新文件、配置解析、覆盖键编码、初始化重试/等待者、权限检查、取消与清理，无未解决 finding；当前小型校验组件符合现有运行时与连接边界。
- 未另做窗口交互验收；Scoco 未独立运行真实模型识图；内置 0.134.0/0.153.4 的实际验证限于协议与权限边界，不作为真实账号 OCR 证明。
- 不新增测试、fixture、mock 或生产测试 hook；不退出或替换用户应用实例。

## 完成条件

- 源码变更、必要验证、review、history 完成；计划归档且任务分支本地提交。
