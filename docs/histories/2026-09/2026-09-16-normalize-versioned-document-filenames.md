## 2026-09-16 | 任务：统一版本化文档命名

**Links:** `easykol-scout-extension@979863ef1739a0cad5d0797449b1be128ae9c22a`

### 用户请求

将 EasyKOL Scout 的版本化文档命名修正语义移植到 Easydict。

### 变更

- 将 10 个历史 plan/history 文件名中的版本标识改为标准点分形式，包括 `v0.3.x` 和 `v2.9.1`。
- 同步相关 plan、history 中的路径引用，并精简 `<slug>` 命名规则。

### 设计意图

保留历史内容与项目文档结构，只统一稳定版本标识写法，使文件名与现行命名规则一致。

### 验证

- 全仓 210 个 Markdown 文件的相对链接检查：通过。
- `git diff --check`：通过。
- 手动检查：连字符版本文件名与相关文本引用均已清理。

### 受影响文件

- `docs/agents/README.md`
- `docs/exec-plans/completed/2026-09/` 中 4 个版本化计划
- `docs/histories/2026-09/` 中 6 个版本化记录及本记录

### 后续事项

- None
