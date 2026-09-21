# 简化 Agent 文档与任务模式

- 状态：completed
- 创建日期：2026-09-13
- 负责人：Codex
- 关联 Issue/PR：none

## 背景

现有 `AGENTS.md`、`request-boundary.md` 与 `git-delivery.md` 重复描述通用 Skill 契约，且以
多维内部状态、Mutation Gate 和交付回执增加了不必要的理解成本。本任务把项目入口收敛为最小
路由，并将计划/执行模式与本地交付边界合并为一份短文档。

## 目标与范围

- 目标结果：删除重复路由和两份复杂规则，以 `task-modes.md` 作为计划/执行模式的唯一来源。
- 允许修改路径：`AGENTS.md`、`docs/agents/`、`docs/exec-plans/{README,templates}.md`、
  `docs/histories/README.md`、两份相关 `docs/references/`、本计划和同任务 history。
- 同任务 history：`docs/histories/2026-09/2026-09-13-simplify-agent-docs.md`。
- 用户限制：不重复描述通用 Skill 契约，合并并简化请求和 Git 交付规则。
- 非目标：不修改 `.agents/skills/`、`skills-lock.json`、产品源码或上一任务已有改动；不 push。
- 验收标准：现行规则无旧文件或旧状态模型引用，Skill 契约不再重复，链接与静态检查通过。

## 初始状态

- 初始 HEAD：`f3eb9eaaf92e3dbb40b0bd36d2e16dd27b96cd0e`。
- 已有工作树变更：上一任务的 Skills v0.3.9 升级改动，共 14 项状态记录；暂存区为空。
- 重叠或阻塞：none。

## 工作计划

1. 新建精简的 `docs/agents/task-modes.md`，删除旧的请求边界与 Git 交付文档。
2. 精简 `AGENTS.md`、Agent 治理、构建验证规则和执行计划模板。
3. 更新相关参考资料术语，创建 history，并归档本计划。
4. 检查旧引用、Markdown 链接、差异卫生和 Git 范围；只提交本任务路径。

## 风险与决策

- 通用 Skill 自我完备，宿主文档只保留项目专属默认值和资产治理边界。
- 计划模式不产生仓库或外部写入；执行模式完成验证后自动本地提交，但不隐式扩大为 push、PR
  或发布。
- 通过精确暂存隔离本任务与现有 Skills 升级改动。

## 进度

- [x] 新增统一任务模式文档并删除旧规则。
- [x] 精简入口、治理文档、模板和相关参考资料。
- [x] 创建 history、完成静态验证并准备独立本地提交。

## 验证

- 旧文件名、Mutation Gate、旧状态字段与通用 Skill 路由检索：无残留。
- Markdown 相对链接与锚点检查：10 项通过。
- `git diff --check`：通过。
- `xcodebuild`：未运行；本任务只修改仓库治理 Markdown，不进入 Xcode 构建图。

## 完成条件

- [x] 新入口和合并规则落地，旧文档删除。
- [x] 所有现行引用与模板同步完成。
- [x] 验证通过，计划归档并创建独立本地提交。
