# 移除 Skill 覆盖层

- 状态：completed
- 创建日期：2026-09-06
- 负责人：tisfeng
- 关联 Issue/PR：none

## 任务摘要

- 意图模式：implementation
- 交付授权：auto-local-commit
- 安全状态：normal
- 目标结果：删除 `.agents/overrides/`，使项目级 Skill 仅由各自的 `SKILL.md` 定义。
- 允许修改路径：`.agents/overrides/`、根 `AGENTS.md`、`docs/agents/README.md`、
  `docs/agents/request-boundary.md` 以及本任务 plan/history。
- 同任务 history：`docs/histories/2026-09/2026-09-06-remove-skill-overrides.md`
- 禁止动作：不修改任何 Skill 内容、既有历史档案、产品代码或远程状态。
- 预期交付物：删除覆盖文件，清理当前规则中的 overlay 路由，并完成本地提交。
- 验收标准：当前规则不再引用覆盖层，Skill 目录内容不变，文档链接与 Git diff 检查通过。

## 写入前状态

- 写入前检查：pass
- 自动提交资格及原因：eligible；初始索引和工作树为空，任务路径可独立识别。
- 初始 HEAD：`b45b89141d6026d416b062f877a37794e69417b9`
- 初始 staged 路径：none
- 初始 unstaged 路径：none
- 初始 untracked 路径：none
- 初始冲突：none
- Agent-owned paths：`.agents/overrides/README.md`、
  `.agents/overrides/fireworks-tech-graph/layout.md`、`AGENTS.md`、
  `docs/agents/README.md`、`docs/agents/request-boundary.md` 以及本任务 plan/history。

## 目标与非目标

### 目标

- 删除 Skill 覆盖层及其加载规则。
- 保留项目级 `.agents/skills/` 布局和上游 Skill 镜像保护。
- 保留历史文档中对旧覆盖机制的事实记录。

### 非目标

- 不把覆盖规则迁移到其他目录或 Skill。
- 不修改 `fireworks-tech-graph` 或其他 Skill 的行为。

## 工作计划

1. 删除 `.agents/overrides/` 下的两个文件。
2. 清理根入口、Agent 文档治理和请求边界中的 overlay 路由。
3. 验证目录、引用、链接、Skill 内容和 Git diff。
4. 完成独立复核、归档计划并创建本地提交。

## 风险与决策

- 删除布局覆盖会取消 Easydict 专属的间距、验收和临时 PNG 清理要求；这是用户明确接受的行为变化。
- 历史计划和 history 保留旧路径，避免改写已发生事实。

## 进度

- [x] 删除覆盖目录内容。
- [x] 清理当前规则引用。
- [x] 完成验证和独立复核。
- [x] 归档计划并完成本地提交准备。

## 验证

- `.agents/overrides/`：已从文件系统移除。
- 当前生效规则引用扫描：未发现残留的 overlay 加载规则；历史档案中的事实记录保留。
- `.agents/skills/` 相对初始 HEAD：无变化。
- Markdown 相对链接检查：39 个链接通过。
- `.claude/CLAUDE.md` 和 `.claude/skills`：符号链接目标保持有效。
- `git diff --check`：通过。
- 独立 reviewer：未发现有效 finding；授权边界完整，删除未产生当前规则失效链接。
- Xcode 构建：未运行；本次仅调整仓库治理文档和 Skill 目录结构。

## 完成条件

- `.agents/overrides/` 不再存在。
- 当前生效的入口和规则不再要求读取 overlay。
- `.agents/skills/fireworks-tech-graph/` 相对初始 HEAD 无变化。
- 静态检查和独立复核通过，计划已归档到 `completed/`。
