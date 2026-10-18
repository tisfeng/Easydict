# <任务标题>

<!-- 文件名：YYYY-MM-DD-<slug>.md；命名规则见 docs/histories/README.md 的“命名与 slug”。 -->
<!-- 本模板只用于多步骤、跨模块或高风险的执行任务。 -->

- 状态：active
- 创建日期：YYYY-MM-DD
- 负责人：<name>
- 关联 Issue/PR：<link or none>

## 执行上下文

<!--
- Agent Name：填写当前主执行 Agent 的运行上下文明确提供的名称，并原样记录。客户端名称只有在
  运行上下文明确将其声明为当前 Agent 身份时才可使用。不得根据应用名称、进程名、默认配置、
  会话 ID、内部角色或历史记录推测；无法确认时填写 Unknown。
- Model：优先填写当前主执行 turn 的运行上下文或响应元数据明确提供的完整模型 ID，并原样记录。
  无法取得完整 ID 时，依次记录运行上下文明示的模型别名或基础模型。不得根据客户端名称、默认
  配置、启动参数、可用模型列表、模型家族或历史记录推测。以上信息均不可得，或客户端仅显示
  Auto 等选择模式时，填写 Unknown。
- Environment：使用 `sw_vers -productVersion` 和 `xcodebuild -version` 记录当前执行环境；
  无法取得的值填 Unknown。执行中切换环境时更新该字段，并在“验证”中说明影响。
-->

- **Agent Name:** `<name or Unknown>`
- **Model:** `<model-id, alias, base-model, or Unknown>`
- **Environment:** `macOS <version or Unknown> / Xcode <version or Unknown> (<build-version or Unknown>)`

## 背景

说明问题、当前状态以及为什么需要这项工作。

## 目标与范围

- 目标结果：
- 允许修改路径：
- 同任务 history：`docs/histories/YYYY-MM/YYYY-MM-DD-<slug>.md`
- 用户限制：
- 非目标：
- 验收标准：

## 工作计划

1. 列出按顺序执行的工作。

## 风险与决策

- 记录兼容性、数据、运行时或发布风险。
- 记录重要选择及原因。

## 进度

- [ ] 待完成工作。

## 验证

- 记录执行过的检查、结果和未运行的检查。
- 记录与任务相关的验证，不套用无关的治理场景。

## 完成条件

- 列出归档到 `completed/YYYY-MM/` 前必须满足的条件。
