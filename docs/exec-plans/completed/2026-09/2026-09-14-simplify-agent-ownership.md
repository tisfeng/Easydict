# 收敛 Agent 项目默认值与资产所有权

- 状态：completed
- 创建日期：2026-09-14
- 负责人：Codex
- 关联 Issue/PR：none

## 背景

Easydict 的 Agent 入口已经删除通用 Skill 和 PR review 路由，但仍单独声明可由仓库与
`submit-pr` 解析的默认 PR 分支，外部资产文档也继续使用宽泛的“Agent 资产”和“项目差异”表述。

## 目标与范围

- 目标结果：删除重复项目默认值，并准确区分宿主项目政策与受管 Skill 算法的所有权。
- 允许修改路径：`AGENTS.md`、`docs/agents/README.md`、
  `docs/design-docs/external-agent-assets-management.md`、本计划及同任务 history。
- 同任务 history：`docs/histories/2026-09/2026-09-14-simplify-agent-ownership.md`
- 用户限制：直接修改 Easydict，不反向复制 boss-resume 的 Electron 专属规则。
- 非目标：不修改受管 Skills、lock、产品源码、已有 completed plan 或公共用户文档；不 push。
- 验收标准：根入口不再保留重复默认值；资产名称、链接与所有权边界准确；静态检查通过。

## 工作计划

1. 删除根入口中可由仓库默认分支和 `submit-pr` 解析的重复 PR 默认值。
2. 收敛外部 Skill 资产说明，明确项目政策和通用算法的所有权。
3. 创建 history，完成格式、链接、锚点和范围检查，再归档计划并本地提交。

## 风险与决策

- `origin` 的实时默认分支仍为 `dev`，`submit-pr` 会解析 GitHub repository default branch；删除
  根声明不会改变 PR 目标选择。
- 外部资产操作规则继续以 `docs/agents/README.md` 为权威来源，设计文档只解释所有权决策。

## 进度

- [x] 删除重复项目默认值。
- [x] 澄清外部 Skill 资产所有权。
- [x] 完成验证、history、计划归档和本地提交。

## 验证

- `git diff --check` 通过。
- 变更文档的本地链接与锚点检查通过。
- 实时 `origin/HEAD` 仍为 `dev`，`submit-pr` 仍从 GitHub repository default branch 解析 base。
- 受管 Skills、lock、产品源码、公共用户文档和已有 completed plan 无差异。
- 未运行 `xcodebuild`；本次只修改不进入 Xcode 构建图的治理 Markdown。

## 完成条件

- 现行 Agent 入口与资产文档无重复默认值或模糊所有权。
- 本地链接、锚点、格式和提交范围检查通过。
- Plan 归档、history 完成并创建本地提交。
