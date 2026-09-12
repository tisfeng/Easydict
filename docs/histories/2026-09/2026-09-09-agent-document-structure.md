# Agent 文档结构重组

- 日期：2026-09-09
- 状态：completed
- 关联计划：[`2026-09-09-agent-document-structure.md`](../../exec-plans/completed/2026-09-09-agent-document-structure.md)

## 用户请求

重新整理 review、构建测试和开发规则的结构，使文档名称与职责一致。

## 变更

- 新增 `docs/agents/review.md`，集中实质审查、reviewer 委派、快照、复审、回退和只读边界。
- 将 `development.md` 重命名为 `coding-guidelines.md`，保留跨语言代码质量、Swift/API 与本地化。
- 将测试组织、工程文件与资源、tester、构建命令与静态验证收敛到 `build-and-test.md`，并清除
  指向已删除 `swift-xcode.md` 的现行链接。
- 更新根路由、请求边界、文档治理与贡献入口；恢复有行为风险 implementation 优先使用 reviewer
  的既有触发条件。

## 设计意图

将审查协调与测试验证分离，为编码约束使用更准确的文档名称，同时保留 reviewer、tester 与
planner 的既有职责和触发强度。

## 验证

- `git diff --check`：通过。
- 现行相对链接、锚点、旧路径与受管路径：静态检查通过。
- 独立 reviewer：发现并修复风险 implementation 遗漏的 P2；增量复核无新增 finding。
- 未运行 `xcodebuild`，因为本次仅修改治理 Markdown。

## 受影响文件

- `AGENTS.md`
- `CONTRIBUTING.md`
- `docs/agents/request-boundary.md`
- `docs/agents/review.md`
- `docs/agents/build-and-test.md`
- `docs/agents/coding-guidelines.md`
- `docs/agents/README.md`
- `docs/exec-plans/completed/2026-09-09-agent-document-structure.md`

## 后续事项

- None
