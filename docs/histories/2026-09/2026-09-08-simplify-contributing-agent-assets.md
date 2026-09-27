## 2026-09-08 | 任务：简化贡献指南中的 Agent 资产说明

**Links:** [`CONTRIBUTING.md`](../../../CONTRIBUTING.md)、
[`tisfeng/skills`](https://github.com/tisfeng/skills)

### 用户请求

缩短缺陷报告说明，并在通用 Skill 和 Codex 子代理改由独立项目统一维护后，适配精简后的
Agent 文档规则来简化贡献指南。

### 变更

- 精简缺陷报告所需信息的表述，同时保留 issue 搜索、复现、版本和可公开证据要求。
- 将逐项复制的 Skill 与子代理表格收束为 `tisfeng/skills` 上游入口。
- 保留常用能力示例，并明确 Easydict 项目专属规则继续以根 `AGENTS.md` 为准。

### 设计意图

通用 Skill 和 Codex 子代理已经由外部项目统一维护，贡献指南只提供发现入口，不再复制容易
漂移的能力说明；项目规则与通用资产继续保持各自唯一权威来源。

### 验证

- `git diff --check`：通过。
- Markdown 相对链接：通过；`AGENTS.md`、构建测试和合并后的开发规则入口均存在。
- 上游入口：通过；`https://github.com/tisfeng/skills` 可访问。
- 负向检查：通过；贡献指南不再直接链接 `.agents/skills/` 或 `.codex/agents/` 中的受管快照。
- 手动复核：通过；Agent 责任、实际场景验证、自动 Codex review、Review 周期和高质量 PR
  标准保持不变。
- `xcodebuild`：未运行，本次仅修改 Markdown 文档。

### 受影响文件

- `CONTRIBUTING.md`
- `docs/histories/2026-09/2026-09-08-simplify-contributing-agent-assets.md`

### 后续事项

- None
