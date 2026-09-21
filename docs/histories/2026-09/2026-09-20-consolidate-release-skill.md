## 2026-09-20 | 任务：聚合 Easydict 发布实现到项目 Skill

**Links:** [`执行计划`](../../exec-plans/completed/2026-09/2026-09-20-consolidate-release-skill.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-5`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

将 `scripts/release/` 中的发布实现全部聚合到项目专属 `release-easydict` Skill，并删除不再
需要的 legacy 脚本和流程图。

### 变更

- 将 ASC workflow、发布 shell/Python、依赖、测试和 Developer ID 导出配置迁入
  `.agents/skills/release-easydict/`，删除 `scripts/release/`、legacy 脚本和流程图。
- 统一 Skill、仓库根和 build worktree 的路径解析，消除 Skill helper 对旧发布目录的
  `sys.path` 依赖，并更新 preflight 同步校验和构建 fingerprint。
- 让入口脚本把 workflow 运行时副本写入 `.tmp/release/asc/`，使 ASC 恢复状态保留在
  `.tmp/release/asc/runs/`，不污染 Skill 源码。
- 将原发布引擎 README 改为 Skill reference，并同步公开发布指南、changelog 说明、架构说明
  和全部现行命令路径。

### 设计意图

发布实现只保留一个权威目录和一个入口，不使用旧路径 wrapper 或符号链接。公开用户指南继续
保留在 `docs/releases/`，Skill 只承载 Agent 指令、详细流程、可执行实现、静态资源和测试；
运行状态仍属于仓库临时数据。

### 验证

- `quick_validate.py .agents/skills/release-easydict`：通过。
- `python3 -m unittest discover -s .agents/skills/release-easydict/tests -p 'test_*.py'`：
  71 tests passed。
- `bash -n .agents/skills/release-easydict/scripts/*.sh`、Python compile checks、`jq -e`、
  `plutil -lint`、相对 Markdown 链接检查、旧现行路径扫描和 `git diff --check`：通过。
- 从仓库外 cwd 运行 `--help` 并加载 `release-common.sh`：通过；仓库根和 plist 路径正确。
- `review`：无 findings。
- 当前环境没有 `asc`，未运行真实 `asc workflow validate`；未执行 Archive、公证或远程写入。

### 受影响文件

- `.agents/skills/release-easydict/`
- `scripts/release/`
- `.gitignore`
- `changelog/README.md`
- `docs/releases/easydict.md`
- `docs/design-docs/application-architecture.md`
- `docs/exec-plans/completed/2026-09/2026-09-20-consolidate-release-skill.md`

### 后续事项

- 在安装 `asc` 的发布机器上，于下一次真实发布前运行
  `asc workflow validate --file .agents/skills/release-easydict/scripts/asc-workflow.json --pretty`。
