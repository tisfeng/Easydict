# 移植 Xcode 验证选择规则

- 状态：completed
- 创建日期：2026-09-10
- 意图模式：implementation
- 交付授权：auto-local-commit
- 安全状态：normal

## 目标与授权范围

将 Scoco 提交 `2d57b691d8512781af3c4571aaf113d926a3caa4` 中的 Xcode 验证选择语义
移植到 Easydict。允许修改 `docs/agents/build-and-test.md` 及本任务 plan/history；不修改产品源码、
Xcode 工程、受管 Skill、Agent 或 lock，不集成其他 worktree，不推送。

## 写入前状态

- 初始 HEAD：`6e2f6ee8ef3f3dbf61ff4cc7b0f67bec855e70c2`，detached checkout。
- staged、unstaged、untracked、冲突：均为空。
- 写入前检查：通过；具备自动本地提交资格。
- Agent-owned paths：构建测试规则及本任务 plan/history，交付前逐项冻结。
- 同任务 history：`docs/histories/2026-09/2026-09-10-port-xcode-validation-rules.md`。

## 工作计划

1. 按 Easydict workspace、scheme、测试 target 和现有工程工具语义改写 Xcode 验证选择规则。
2. 校验命令示例、项目引用、旧规则残留、Markdown 链接和差异格式。
3. 委派独立 reviewer 复核最终候选，修复有效问题并增量复验。
4. 记录 history、归档计划并按 Git 门禁完成本地交付。

## 风险与决策

- 不直接 cherry-pick，避免带入 Scoco 的名称和既有 history；只移植源提交的规则语义。
- 删除行数硬阈值，但按编译、行为、工程配置和重复测试所需证据选择最小充分验证。
- DerivedData fallback 只用于证据明确的权限、缓存损坏或 runner 状态问题，不掩盖产品失败。
- 删除 Agent 层额外格式或 lint 命令，不改动 Easydict 现有工程 phase、配置或源码。

## 进度与验证

- 已完成独立 planner 方案复核；关键 Easydict 映射由主 Agent 对当前仓库再次核验。
- 已按 Easydict 名称和真实测试标识完成规则修改，Bash 示例语法检查通过。
- workspace、scheme、测试源码和工程 Sources 引用静态核验通过；旧阈值、占位符、宽泛 fallback、
  Agent 层额外格式检查及 Scoco 路径残留扫描通过。
- Markdown 相对链接、目标锚点和 `git diff --check` 通过；纯治理文档未运行 Xcode。
- 独立 reviewer 对规则候选无 finding；收尾记录增量复核后进入本地交付。
- 完成条件：目标语义落地且无 Scoco 路径或占位符残留，静态检查与独立复核通过，计划归档，
  变更按精确路径本地提交且未推送。
