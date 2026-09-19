# 精简 Agent 文档文案

- 状态：completed
- 创建日期：2026-09-06
- 负责人：tisfeng
- 关联 Issue/PR：none

## 任务摘要

- 意图模式：implementation
- 交付授权：auto-local-commit
- 安全状态：normal
- 目标结果：消除 Agent 文档中的规则冲突、异常 YAML 文案空格、重复职责和绕口表述。
- 允许修改路径：根 `AGENTS.md`、`docs/agents/`、本地维护的 Skill 入口、overlay、
  `.codex/agents/planner.toml` 以及本任务 plan/history。
- 同任务 history：`docs/histories/2026-09/2026-09-06-agent-document-wording-cleanup.md`
- 禁止动作：不修改上游 `fireworks-tech-graph` 镜像、历史档案、产品代码或远程状态。

## 写入前状态

- 写入前检查：pass
- 自动提交资格及原因：eligible；初始索引和工作树为空，任务路径可独立识别。
- 初始 HEAD：`906818217d714e412911dac3648942106d0cd871`
- 初始 staged 路径：none
- 初始 unstaged 路径：none
- 初始 untracked 路径：none
- 初始冲突：none

## 工作计划

1. 修复 overlay 优先级冲突和 Skill description 的解析后空格。
2. 收敛根入口及 `docs/agents/` 中重复维护的规则。
3. 精简本地 Skill 和 planner 配置中的绕口或维护者自述。
4. 验证 YAML/TOML、相对链接、规则语义和 Git diff，完成 history 后本地交付。

## 风险与决策

- 文案压缩可能误删权限或恢复边界；逐项对照原规则，保留所有实际行为约束。
- `review-pr` 只做局部去重，不在本任务拆分工作流或重构 references。

## 进度

- [x] 完成全量清单与只读审计。
- [x] 完成文案修改。
- [x] 完成静态验证与最终复核。

## 验证

- Ruby YAML 解析及等价 `quick_validate.py` 检查：8 个 Skill 通过，未发现异常中文空格。
- Python `tomllib`：3 个 `.codex/agents/*.toml` 解析通过。
- 当前规则文档相对链接检查：50 个文件通过，0 个失效链接。
- `git diff --check`：通过。
- 独立 reviewer：未发现有效 finding；建议的 `review-pr` 权限措辞已收紧。
- `quick_validate.py`：当前 Python 缺少 `PyYAML`，未直接运行；已读取其实现并使用 Ruby
  执行等价字段、命名、长度、占位符和 YAML 检查。

## 完成条件

- 已确认的冲突、异常空格和重复文案消除。
- 权限、Git、review、测试、发布与恢复行为保持不变。
- 静态检查通过，计划归档到 `completed/`，同任务 history 完整。
