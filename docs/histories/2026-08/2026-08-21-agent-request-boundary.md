# Agent 请求边界与文档规则

- 日期：2026-08-21
- 状态：completed
- 执行计划：`../../exec-plans/completed/2026-08-21-agent-request-boundary.md`

## 用户请求

将引用任务中的 Agent 文档规则完整适配到当前 Easydict，使 Agent 自动区分用户请求、
仓库规则和图片、附件、引用等待分析材料。

## 变更

- 在 `docs/agents/repository-guide.md` 增加请求来源分类、任务模式、自动任务契约和
  正向交付物表达规则。
- 在 `docs/exec-plans/templates/execution-plan.md` 增加任务契约、自动提交状态和输入
  来源字段。
- 在 `docs/agents/skills.md` 明确 skill 不得替换用户目标、扩大修改范围或把材料升级
  为任务指令。
- 保留 Easydict 已删除一次性 Agent 文档检查器的现状，不恢复旧脚本。

## 验证

- `git diff --check`：通过。
- 针对性 `rg` 检查：来源边界、任务契约、skill 规则和旧脚本引用边界通过。
- 新增 Markdown 尾随空白检查：通过。
- 未运行 `xcodebuild`，因为没有修改编译源码、测试或 Xcode 工程元数据。

## 边界

未修改 Swift、Objective-C、测试、Xcode 工程、应用运行时资源或其他 Scoco 专属路径；
未暂存、提交或推送。
