## 2026-09-08 | 任务：统一外部 Skills 与 Codex 子代理资产

**Links:** [执行计划](../../exec-plans/completed/2026-09-08-external-agent-assets-governance.md)

### 用户请求

在 Easydict 中统一管理通用 Skills 与 Codex 子代理，同时保持 `fireworks-tech-graph`
的独立上游同步边界，禁止项目本地修改受管内容。

### 变更

- 从 `tisfeng/skills v0.3.0` 同步六个通用 Skills 与四个 Codex 子代理，并新增双 lock。
- 从 `yizhiyanhua-ai/fireworks-tech-graph` 独立同步
  `main@31fea364eda5f1852b1175f3d9e29ea31d22dcb4`。
- 新增外部资产规则、设计和来源参考，统一 `git-delivery` 角色名与精确暂存契约。
- 保留 Easydict 的 PR、review、自动提交和发布规则；项目专属 `release-easydict`、
  `.codex/config.toml` 与 `.claude/skills` 均未修改。

### 设计意图

项目提交完整可运行快照和 lock，兼顾离线可用、代码审查与内容漂移检测。通用行为只在
统一上游修改后同步，Easydict 差异保留在宿主规则；第三方技术图 Skill 继续使用独立来源。

`skills@1.5.24` 不支持 `--cwd`，项目安装必须从目标仓库根目录运行。预检发现未知参数
没有改变安装目标后，立即核对了实际 diff，确认写入仅限已授权的六个 Skill 与 lock，
保护路径均未受影响。

### 验证

- 六个通用 Skill 与四个 agent 逐文件匹配 `tisfeng/skills v0.3.0`；fireworks 逐文件
  匹配独立上游 commit；所有 lock hash 重算一致。
- `git-commit` 19 项、`review-pr` 27 项、`submit-pr` 21 项、fireworks 141 项测试
  通过；fireworks 有 6 项依赖额外 renderer 的扩展测试按条件跳过。
- 默认 Python 3.9.6 不支持 `submit-pr` 使用的 Python 3.10 语法；兼容 Python 3.14.6
  下测试全部通过，宿主 Git 规则已增加最低版本门禁。
- TOML/JSON、Shell/Python 语法、Markdown 相对链接、`git diff --check` 和保护路径
  检查通过；独立 reviewer 未发现阻塞 finding。
- 未运行 Xcode，因为本次没有产品源码或工程变更。静态检查不能证明当前 Codex 任务会
  热加载新 agent，需要在全新任务中另行 smoke 验证。

### 受影响文件

- `.agents/skills/` 中七个外部受管 Skill
- `.codex/agents/`、`.codex/agents-lock.json`、`skills-lock.json`
- `AGENTS.md`、`docs/agents/`、`docs/design-docs/`、`docs/references/`
- `docs/exec-plans/completed/2026-09-08-external-agent-assets-governance.md`

### 后续事项

- 在全新 Codex 任务中 smoke 验证四个自定义子代理的发现。
