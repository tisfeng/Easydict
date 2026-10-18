## 2026-09-21 | 任务：强化 GitHub 公开 Release 验收

**Links:** [`执行计划`](../../exec-plans/completed/2026-09/2026-09-21-github-public-release-verification.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-5`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

参考 Scoco 提交 `081caf8c4965ae5112bacf6f68a1be3d61aa23f2`，把公开发布资源契约校验的
最终语义移植到 Easydict，并包含测试。

### 变更

- 新增可测试的公开 HTTP、GitHub Release asset、Sparkle appcast 和 checksum 校验 helper，
  解析重定向后的最终响应头，校验状态、长度、类型、Range、唯一上传状态和 SHA-256 digest。
- 在 GitHub Release 公开后、远程 appcast 引用推进前增加公开资产验收步骤；checksum 内容
  下载和 CDN 收敛失败使用有限重试，任一契约不一致都会 fail closed。
- 最终远程验证完整比较目标 appcast item，覆盖版本、构建、channel、说明、URL、长度、类型、
  签名和未知新增字段，并补充失败路径及工作流顺序测试。
- 更新 Release Skill、执行契约和发布维护指南，说明公开验收顺序与恢复边界。

### 设计意图

保留 Easydict 现有 GitHub Release、`raw.githubusercontent.com`、Sparkle URL、Git lease 和 ASC
恢复模型，只移植 Scoco 的公开资源契约语义，不引入 R2、Cloudflare 或新的客户端配置。GitHub
API 元数据与匿名下载响应分别按实测契约验证，避免混用 Content-Type。

### 验证

- `python3 .agents/skills/release-easydict/tests/test_release_public.py`：8 tests passed。
- 完整 Release Skill 测试：临时 Python 3.14 环境安装固定 `Markdown==3.8.1` 后，
  80 tests passed。
- Shell 语法、Python 编译、workflow JSON、Skill `quick_validate.py`、相对 Markdown 链接和
  `git diff --check`：通过。
- Easydict 2.23.0 只读网络核验：GitHub API asset 状态、大小、类型和 digest 可用；匿名下载
  最终类型与长度符合预期，ZIP/DMG 支持 Range，公开 appcast 类型符合预期。
- `review`：基于初始 `HEAD` `dc7d6694c09dca3b79c4fc514805ad639957b3d2`，无未处理 findings。
- 未运行 Xcode build/test、Archive、公证或真实发布，未执行任何远程写入。

### 受影响文件

- `.agents/skills/release-easydict/SKILL.md`
- `.agents/skills/release-easydict/references/release-workflow.md`
- `.agents/skills/release-easydict/scripts/`
- `.agents/skills/release-easydict/tests/test_release_public.py`
- `docs/releases/easydict.md`
- `docs/exec-plans/completed/2026-09/2026-09-21-github-public-release-verification.md`

### 后续事项

- 下一次真实发布会首次端到端执行新增公开验收步骤；若 GitHub 未来调整 API 或 CDN
  Content-Type，需要以当时只读证据更新契约与测试。
