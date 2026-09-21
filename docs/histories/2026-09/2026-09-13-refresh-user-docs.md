## 2026-09-13 | 任务：更新用户文档

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-13-refresh-user-docs.md)

### 用户请求

检查并更新 `user-docs` 中已经过时的内容，重点校准支持的服务，并执行确认后的改进方案。

### 变更

- 新增中英文服务总览，按无需密钥、项目内置、用户密钥和 CLI 说明当前 29 个服务条目。
- 重写中英文完整使用指南，更新 52 种可选翻译语言、OCR/TTS、窗口服务、全局及应用内快捷键、
  查询历史、收藏、导出、Markdown 结果和故障排查说明。
- 更新 Apple 翻译指南，区分 macOS 15+ 离线 Translation 框架和 macOS 快捷指令回退路径。
- 收敛 Apple Dictionary 指南，移除来源不明的第三方词典下载和旧转换流程；新增 MDict
  直接导入、资源关联和词典管理指南。
- 修复本地化贡献指南的构建链接和 Xcode 要求，并同步公共文档索引及根 README 摘要。

### 设计意图

把易漂移的完整服务集合集中到每种语言的一份 `SERVICES.md`，根 README 和完整指南只保留
稳定摘要和链接。厂商价格、免费额度和模型名称不再固化在仓库中；词典文档只描述合法文件的
导入边界，不分发或推荐来源不明的内容。

### 验证

- 中英文服务 ID 集合：各 29 项，与源码注册表完全一致。
- 可选翻译语言计数：52，与当前语言注册和筛选逻辑一致。
- 17 份公共 Markdown 的相对链接与锚点：通过。
- 过时内容残留检索：通过。
- `git diff --check`：通过。
- `xcodebuild`：未运行；本任务只修改公共 Markdown，不进入 Xcode 构建图。

### 受影响文件

- `README.md`
- `README_ZH.md`
- `docs/user-docs/README.md`
- `docs/user-docs/en/`
- `docs/user-docs/zh/`
- `docs/exec-plans/completed/2026-09/2026-09-13-refresh-user-docs.md`
- `docs/histories/2026-09/2026-09-13-refresh-user-docs.md`

### 后续事项

- 外部服务若新增、删除或更改凭据类型，只需同步中英文 `SERVICES.md`，并继续通过服务 ID
  集合校验避免遗漏。
