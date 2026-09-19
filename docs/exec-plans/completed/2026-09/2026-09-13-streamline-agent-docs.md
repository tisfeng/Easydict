# 进一步精简 Agent 文档

- 状态：completed
- 创建日期：2026-09-13
- 负责人：Codex
- 关联 Issue/PR：none

## 背景

上一轮已合并请求边界与 Git 交付规则。本轮继续删除现行 Agent 文档中的通用能力描述和重复
背景，同时保留用户指定的编译测试命令、编码规范主体、执行计划结构和 history 模板。

## 目标与范围

- 目标结果：进一步收敛 Agent 入口、任务模式、治理、验证及参考文档，并把放错目录的 OCR
  history 移入 `2026-09/`。
- 允许修改路径：根 Agent 入口、`docs/agents/` 中指定文档、执行计划模板、两份 Agent 设计文档、
  两份 Agent reference 及其索引、本计划和同任务 history，以及 OCR history 的路径。
- 同任务 history：`docs/histories/2026-09/2026-09-13-streamline-agent-docs.md`。
- 用户限制：不修改 `CONTRIBUTING.md`、history 模板和 README；不删减任何编译测试命令；编码
  规范只调整类型文档固定字符数规则。
- 非目标：不修改受管 Skills、lock、Skill 来源参考、产品代码或已有 skills v0.3.9 改动；不 push。
- 验收标准：现行规则职责清晰且无目标重复，保留内容符合用户限制，链接和静态检查通过。

## 初始状态

- 初始 HEAD：`3e05444a95393dd42a093a6e096b6f7014fe4630`。
- 已有工作树变更：skills v0.3.9 升级相关 14 项状态记录；暂存区为空。
- 重叠或阻塞：两份 Skill 来源 reference 已有改动，本轮不修改。

## 工作计划

1. 精简 `AGENTS.md`、`task-modes.md` 和 Agent 治理文档。
2. 压缩构建测试说明但完整保留命令，只调整一条编码规范，并删除执行计划模板中的 Git 初始状态。
3. 清理重复的 Agent 设计/reference，移动 OCR history，更新对应目录索引。
4. 创建 history，检查语义、链接、差异与提交范围，创建独立本地提交。

## 风险与决策

- 历史和 completed plan 继续作为证据，不批量改写其旧术语。
- `astra-agent-guidance.md` 保留最小来源记录，避免已有 history 链接失效。
- `external-agent-assets-management.md` 保留非显然的快照治理设计，只删除重复操作规则。

## 进度

- [x] 完成入口、规则和模板精简。
- [x] 完成设计/reference 清理及 OCR history 移动。
- [x] 完成验证、history、归档与独立本地提交。

## 验证

- 已删除内容与旧路径的现行引用：无残留。
- Markdown 相对链接和锚点：通过。
- 编译测试命令、OCR history 正文、`CONTRIBUTING.md` 和 history 模板：与初始 HEAD 一致。
- 编码规范：仅类型文档固定字符数规则发生变化。
- `git diff --check`：通过。
- `xcodebuild`：未运行；本任务只修改治理 Markdown。

## 完成条件

- [x] 所有批准的精简和移动已完成。
- [x] 用户要求保留的内容及已有 skills 改动未被混入。
- [x] 静态验证通过并创建独立本地提交。
