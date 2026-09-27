# 重组 Agent 审查与编码规则

- 状态：completed
- 创建日期：2026-09-09
- 负责人：Codex
- 关联 Issue/PR：none

## 背景

审查规则位于构建测试文档，使文档名称与内容不匹配；`development.md` 的名称也过于宽泛。
同时测试组织仍链接已删除的 `swift-xcode.md`。

## 任务摘要

- 意图模式：implementation
- 交付授权：auto-local-commit
- 安全状态：normal
- 受阻操作及原因（如有）：none
- 目标结果：将审查规则独立为 `review.md`，将编码规则重命名为 `coding-guidelines.md`，收敛
  构建测试职责并修复现行链接。
- 允许修改路径：`AGENTS.md`、`CONTRIBUTING.md`、`docs/agents/`、本任务 plan/history。
- 同任务 history：`docs/histories/2026-09/2026-09-09-agent-document-structure.md`
- 禁止动作：不修改 `.agents/skills/`、`.codex/agents/`、lock、产品代码、历史记录或远程状态。
- 预期交付物：职责单一且链接有效的 Agent 文档结构。
- 验收标准：reviewer、tester、planner 的角色边界明确；现行入口无旧路径或失效链接；最终差异
  经 reviewer 复核。

## 写入前状态

- 写入前检查：pass
- 自动提交资格及原因：eligible；初始索引、工作树与未跟踪文件为空，任务路径可独立识别。
- 初始 HEAD：`9087d286c6a8bca7b03e5c89214ae0a56e3a6ed1`
- 初始 staged 路径：none
- 初始 unstaged 路径：none
- 初始 untracked 路径：none
- 初始冲突：none
- Agent-owned paths：允许路径及本任务 plan/history。

## 目标与非目标

### 目标

- 将 reviewer 规则从构建测试文档迁入独立的审查文档。
- 将 `development.md` 重命名为准确表达内容的 `coding-guidelines.md`。
- 将工程元数据、测试规则与 tester 保留在构建测试文档中，并修复失效链接。

### 非目标

- 不改变 reviewer、tester、planner 的权限或受管 Skill/TOML 内容。
- 不批量改写 history 或 completed plan 中的历史路径。

## 工作计划

1. 创建审查文档，迁移 reviewer 的委派、快照、复审与回退规则。
2. 重命名并收窄编码规范，补全构建测试的工程与 tester 职责。
3. 更新根入口、请求边界、贡献文档和现行链接。
4. 验证最终链接与差异，委派 reviewer 复核，归档 plan 并记录 history。

## 风险与决策

- 迁移不得弱化 reviewer 的硬性委派条件；规则主语保持为主 Agent，避免递归委派。
- 历史记录保留当时的路径事实；只修复当前有效文档中的失效链接。
- `coding-guidelines.md` 保留跨语言、Swift/API 与本地化的内聚规则，不为形式对称拆分小文件。

## 进度

- [x] 完成现行文档、引用和 planner 结论核对。
- [x] 完成文档迁移与路由更新。
- [x] 根据 reviewer finding 恢复有行为风险 implementation 的 reviewer 触发。
- [x] 完成静态验证与 reviewer 复核。
- [x] 归档计划并完成 history。

## 验证

- 现行相对链接、锚点、旧路径与受管路径检查：通过。
- `git diff --check`：通过。
- 独立 reviewer 对最终文档差异的只读复核：发现并修复 1 项 P2（恢复有行为风险
  implementation 的 reviewer 触发）；增量复核无新增 finding。
- 不运行 `xcodebuild`，因为本次仅修改治理 Markdown。

## 完成条件

- 各专题文档只有一个主要职责，reviewer、tester、planner 不混淆。
- 所有现行入口和相对链接有效，`swift-xcode.md` 的失效引用清除。
- 静态检查与独立 reviewer 复核完成，plan 归档并写入 history。
