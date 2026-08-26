## 2026-08-23 | 任务：强制校验 Git 提交信息结构

**Links:** `../../exec-plans/completed/2026-08-23-validate-git-commit-message.md`

### 用户请求

修复 `git-commit` skill 没有实际执行双语三段式规则的问题。除改正当前未推送提交的消息
外，还要增加机器校验，防止 Agent 再次将“主要变更”和“影响”合并为同一正文段落。

### 变更

- 将本地提交 `0b0beac0fc618cc93a2aab2a1803eaf946547c07` 仅改写消息为合规的双语
  三段式提交 `cd8fe06d8e49b4cebf4132618822b34f4df76476`；改写前后的 parent 和 tree
  object ID 完全一致。
- 新增确定性提交信息校验器，支持 `--file` 提交前校验，以及 `--commit` 配合
  `--expected-file` 的提交后实际消息校验。
- 英语模式要求单个英文区块；双语模式要求本地语言、严格 70 个连字符分隔线和英文
  区块。每个区块都必须包含 Angular 标题和恰好三个正文段落。
- 双语区块必须使用相同的 type、scope、breaking 标记和 breaking footer 状态；只允许
  最终且包含非空说明的 `BREAKING CHANGE: ` footer，且 footer 不计入三个正文段落。
- 拒绝 `Refs:`、`BREAKING-CHANGE:`、空说明或缺少规定空格等 footer-like 段落，避免
  它们冒充第三个自然正文段落。
- 更新 skill 的必需流程：提交前失败不得运行 `git commit`；提交后失败不得自动 amend
  或删除 `commit_message.txt`，也不能声称交付完成。
- 临时 Git 测试仓库显式关闭继承自用户环境的 commit signing，保证隔离测试不依赖本机
  SSH 签名配置。

### 设计意图

校验器只负责可确定的格式约束，不尝试用启发式判断翻译质量或正文语义。Agent 仍负责
根据 staged raw patch 起草准确的背景、主要变更和影响；脚本负责在 Git 写入前后证明
这些内容采用了规定结构，避免文档规则被遗漏。

### 验证

- 19 个 `git-commit` 单元与临时仓库测试通过。
- 13 个校验器测试和修正后的实际 commit 在 macOS 系统 Python 3.9 下通过。
- Python 编译、skill `quick_validate.py` 和 `git diff --check` 通过。
- 历史错误消息被拒绝，并同时报告两个语言区块都只有两个正文段落；修正后的提交消息
  通过双语校验。
- 独立前向测试发现并推动修复了 `zip(strict=True)` 的 Python 3.9 兼容问题、伪 footer
  冒充正文，以及双语 footer 状态不一致问题。

### 受影响文件

- `.agents/skills/git-commit/`
- `docs/exec-plans/completed/2026-08-23-validate-git-commit-message.md`
