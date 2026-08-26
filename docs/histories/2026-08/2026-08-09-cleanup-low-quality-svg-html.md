## 2026-08-09 | 任务：清理低质量 SVG 和 HTML 文档

**Links:** `AGENTS.md`

### 用户请求

移除过时的目录级 SVG 和 HTML 文档，同时保留少量有用的架构图和运行时 HTML 资源。

### 变更

- 移除六个价值较低的架构 SVG 文件，包括 Baidu、Markdown、ClaudeCode、CodexCLI、
  AppleDictionary 和 CodexCLI 测试副本。
- 移除六个目录概览 HTML 文件。
- 保留七个核心架构或发布流程 SVG 文件，以及运行时使用的
  `dictionary-result.html` 模板。
- 从 `Easydict.xcodeproj/project.pbxproj` 中移除已删除文件的引用。
- 保持 Markdown 文档、图标资源和 `.agents` skill 资源不变。

### 设计意图

当前 Agent 文档规则不再要求目录级 HTML 或 SVG 产物。只保留具有明确架构或操作价值的
图表，可以减少导航噪声，同时不移除运行时资源或更有用的 Markdown 文档。

### 验证

- 对七个保留的 SVG 文件运行 `rsvg-convert`：通过。
- `plutil -lint Easydict.xcodeproj/project.pbxproj`：通过。
- 已删除文档引用扫描：通过，未发现残留引用。
- `git diff --check`：通过。

### 受影响文件

- `Easydict.xcodeproj/project.pbxproj`
- `Easydict/`、`EasydictTests/` 和 `release-scripts/` 下选定的 SVG 和 HTML 文档文件
- `docs/histories/2026-08/2026-08-09-cleanup-low-quality-svg-html.md`

### 后续事项

- None.
