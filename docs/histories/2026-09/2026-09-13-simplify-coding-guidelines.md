## 2026-09-13 | 任务：精简编码规范

**Links:** None

### 用户请求

检查并优化 `docs/agents/coding-guidelines.md` 中含糊、重复或过度具体的规则。

### 变更

- 删除与项目 formatter 和 linter 配置不一致的注释 80 字符限制。
- 让文件规模和命名规则以项目工具及目录约定为准，避免无关重构和跨目录误用。
- 合并重复的文档注释要求，移除 `static` 与 `for ... where` 的局部风格偏好。
- 精简 SFSafeSymbols 规则，只保留类型安全 API 和禁止硬编码名称的约束。

### 设计意图

保留职责拆分、必要文档、Swift 组织方式、API 和本地化等项目约束，同时减少容易让 Agent 扩大
任务范围或生成无意义样板的规定。

### 验证

- `git diff --check`：通过。
- 相对链接检查：通过。
- 手动检查：确认除 SFSafeSymbols 表述外，语言与迁移、库与 API、本地化内容未改变。

### 受影响文件

- `docs/agents/coding-guidelines.md`
- `docs/histories/2026-09/2026-09-13-simplify-coding-guidelines.md`

### 后续事项

- None
