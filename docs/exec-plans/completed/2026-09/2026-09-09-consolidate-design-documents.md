# 统一设计文档目录并移除冗余 Skill 别名

- 状态：completed
- 创建日期：2026-09-09
- 负责人：Codex
- 关联 Issue/PR：无

## 任务摘要与授权

- 意图模式：implementation；交付授权：auto-local-commit；安全状态：normal。
- 目标结果：将 `docs/architecture/` 合并到 `docs/design-docs/`，减少重复索引和治理说明；删除
  根 `skills/fireworks-tech-graph` 兼容符号链接，保留唯一真实 Skill。
- 允许修改路径：`AGENTS.md`、`CONTRIBUTING.md`、`docs/agents/README.md`、
  `docs/design-docs/`、`docs/architecture/`、`docs/references/fireworks-tech-graph.md`、
  `docs/user-docs/README.md`、`docs/exec-plans/active/swift-migration.md`、
  `skills/fireworks-tech-graph` 以及本任务 plan/history。
- 同任务 history：`docs/histories/2026-09/2026-09-09-consolidate-design-documents.md`。
- 禁止动作：修改产品源码、Xcode 工程、`.agents/skills/`、`.claude/skills`、双 lock 或远程状态。

## 写入前状态

- 写入前检查：pass；自动提交资格：eligible。
- 初始 HEAD：`602c56b24a68d2917f4d9e5ed5180f9f4cbdf91a`。
- 初始分支：`docs/refine-agent-documentation`。
- 初始 staged、unstaged、untracked、冲突：均为空。
- Agent-owned paths：允许路径中本任务实际产生差异的文件。

## 目标与非目标

### 目标

- 让 `docs/design-docs/` 同时承载产品与技术设计、长期设计决策，并在 README 中明确分类。
- 将应用架构和文本选择流程迁移到统一目录，更新全部现行入口。
- 压缩两篇 Agent 治理设计中与现行规则重复的操作条款。
- 删除根 `skills/` 下没有仓库内消费者的兼容链接，澄清上游路径和本地安装路径。

### 非目标

- 不把四篇正文合并成单一大文件。
- 不批量改写 completed plan/history 中记录的旧路径。
- 不改变产品行为、Agent 执行规则、Skill 内容、lock 或运行时发现机制。

## 工作计划

1. 移动两篇架构文档，合并目录 README 并精简两篇治理设计。
2. 更新根入口、贡献指南、Agent 治理、公共文档索引和活动计划的现行链接。
3. 删除根 Skill 兼容符号链接，更新来源参考中的路径说明。
4. 检查相对链接、锚点、旧活动引用、受管资产和 Git 格式。
5. 完成独立审查，记录 history，归档计划并按门禁本地提交。

## 风险与决策

- `docs/design-docs/` 是统一后的通用设计目录，但不成为第二套 Agent 路由。
- `application-architecture.md` 使用明确文件名，避免统一目录中的 `overview.md` 含义不清。
- 历史记录保留旧路径作为当时事实；当前任务 history 提供迁移映射。
- `skills-lock.json` 的 `skillPath` 是上游入口，不因删除本地根符号链接而修改。

## 进度

- [x] 冻结初始 Git 状态、允许路径和保护路径。
- [x] 完成文档迁移、精简和链接更新。
- [x] 删除根 Skill 兼容链接并验证真实 Skill。
- [x] 完成静态验证和独立审查。
- [x] 补齐 history、归档计划并进入本地交付。

## 验证

- `git diff --check` 通过。
- 现行入口、设计文档、活动计划、参考和本任务 history 共检查 41 个本地 Markdown 链接，
  没有失效链接。
- 旧 `docs/architecture/` 引用只保留在本任务 plan/history 的迁移事实中；现行入口均已改为
  `docs/design-docs/`。
- `.agents/skills/fireworks-tech-graph/SKILL.md` 和 `.claude/skills` 均可解析，双 lock、受管
  Skill、Codex 子代理和 Claude 兼容入口相对初始 HEAD 无差异。
- 独立 reviewer 发现并关闭 1 项 P2：区分“本任务采纳历史材料”和“提升为长期规则”，最终
  增量复审无新增 finding。
- 本任务只修改治理和设计 Markdown 及一个符号链接，默认不运行 Xcode。

## 完成条件

- `docs/architecture/` 和根 `skills/` 不再存在，现行入口全部指向统一目录。
- 两篇治理设计只保留长期理由，操作规则继续由现行 Agent 文档维护。
- `.agents/skills/fireworks-tech-graph/`、`.claude/skills` 和双 lock 与初始状态一致。
- history 已记录结果，计划已归档并进入本地交付，不 push。
