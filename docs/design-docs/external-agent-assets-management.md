# 外部 Agent 资产统一版本治理设计

- 状态：adopted
- 初次记录：2026-09-08

## 背景

Easydict 需要直接从仓库运行 Skills 和 Codex 子代理，同时又要让多个项目共享同一套通用
实现。若每个项目独立修改副本，同名资产会逐渐产生难以追踪的行为、测试和安全差异；若只
引用全局目录，离线运行、代码审查和历史复现又缺少稳定证据。

## 设计决策

采用“外部版本化权威来源 + 仓库内完整快照 + lock 内容校验 + 宿主规则保留项目差异”：

- `tisfeng/skills` 统一维护六个通用 Skills 与四个 Codex 子代理，二者使用同一个发布 tag。
- `fireworks-tech-graph` 保持独立第三方来源，不并入通用技能仓库。
- 外部 Skills 由 `skills-lock.json` 控制，Codex 子代理由 `.codex/agents-lock.json` 控制。
- 项目提交可直接运行的完整资产，而不是依赖机器全局状态；lock 记录来源和预期内容哈希，
  配合重新计算实际哈希来检查本地漂移。
- `release-easydict` 保留项目维护权，Easydict 的构建、PR、发布和交付策略继续由宿主文档
  定义，不通过 fork 通用 Skill 实现。

现行操作规则以 [`docs/agents/README.md`](../agents/README.md#外部-agent-资产) 为准；本文只
解释为什么采用该边界。

## 取舍

- 仓库会保存较大的第三方 Skill 快照，但换取离线可用、可审查和可回滚。
- Skills lock 与 agents lock 的字段和更新语义不同，因此分别验证，不强行套用同一套安装和
  校验流程。
- 跟踪 `main` 这类可移动分支的第三方来源时，需要在 reference/history 中额外记录同步时
  commit；长期若上游发布稳定 tag，应优先改用不可变 tag。

## 重新评估条件

- 外部安装器改变 lock 格式、hash 算法或项目安装目录。
- `tisfeng/skills` 拆分仓库、改变发布策略或不再同时发布 Skills 与 agents。
- `fireworks-tech-graph` 提供稳定版本 tag，或者不再以嵌套 Skill 目录发布。
- Easydict 新增必须项目维护但与通用 Skill 同名的行为，无法通过宿主规则表达。
