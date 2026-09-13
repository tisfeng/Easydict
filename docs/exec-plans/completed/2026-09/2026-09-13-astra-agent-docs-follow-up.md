# Astra Agent 文档后续精简

- 状态：completed
- 创建日期：2026-09-13
- 负责人：Codex
- 关联 Issue/PR：none

## 背景

通用 Skills 已升级到 v0.4.0，并完成短描述、明确路由和渐进披露优化。本轮继续按照
GPT-6 Astra 官方建议精简 Easydict 的宿主 Agent 文档和项目专属 Release Skill。

## 目标与范围

- 目标结果：移除所有任务的额外模式文档读取，压缩重复的 Xcode 验证说明，并让
  `release-easydict` 根 Skill 只保留路由和关键边界。
- 允许修改路径：`AGENTS.md`、`docs/agents/{task-modes,build-and-test}.md`、
  `.agents/skills/release-easydict/`、`.claude/settings.local.json`、本计划和同任务 history。
- 同任务 history：`docs/histories/2026-09/2026-09-13-astra-agent-docs-follow-up.md`。
- 用户限制：不修改 History 规则和模板；不删减或改写任何编译测试命令。
- 非目标：不修改受管 Skills、`skills-lock.json`、产品代码、发布脚本或外部服务；不 push。
- 验收标准：任务模式语义保持不变，构建命令内容不变，Release Skill 的动作、授权、状态、
  恢复和 Issue 跟进约束均可追踪，静态检查与 Skill 测试通过。

## 工作计划

1. 将任务模式核心规则合并到根入口，删除 `task-modes.md` 和 Claude 本地权限文件。
2. 去除 Xcode 验证说明中的重复内容，完整保留命令区块。
3. 将 Release 生命周期细节集中到按需读取的 reference，压缩根 `SKILL.md`。
4. 创建 history，验证链接、Skill、测试和 Git 差异，归档计划并创建本地提交。

## 风险与决策

- Release 的远程写入授权和不可逆边界继续保留在根 Skill；模式专属步骤移入 reference。
- 已完成的 plan/history 是历史证据，不因现行路径变化批量改写。
- `.claude/settings.local.json` 按用户明确要求删除，不迁移其中权限。

## 进度

- [x] 完成 Agent 入口和构建文档精简。
- [x] 完成 Release Skill 渐进披露重构。
- [x] 完成 history、验证、归档和本地提交准备。

## 验证

- Markdown 现行旧路径检索和 Release reference 目标检查：通过。
- Release Skill `quick_validate.py`：通过；现有 23 个 Python 单元测试全部通过。
- `build-and-test.md` 的完整命令区块与初始 HEAD 一致。
- `git diff --check`：通过。
- `xcodebuild`：未运行；本任务不修改 Xcode 构建图。

## 完成条件

- [x] 批准的四项修改全部完成，保留项未改变。
- [x] 静态验证与 Release Skill 测试通过。
- [x] 计划归档、history 完成且本地提交准备就绪。
