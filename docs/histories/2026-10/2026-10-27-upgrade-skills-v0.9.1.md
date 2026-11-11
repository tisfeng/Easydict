## 2026-10-27 | 任务：升级受管 Skills 至 v0.9.1

**Links:** [执行计划](../../exec-plans/completed/2026-10/2026-10-27-upgrade-skills-v0.9.1.md)、[上游 v0.9.1](https://github.com/tisfeng/skills/releases/tag/v0.9.1)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

按项目流程将 Easydict 的受管 skills 更新到 v0.9.1，验证后本地提交，不 push。

### 变更

- 使用 skills@1.5.25、独立 npm 缓存及规定的 --copy --full-depth 参数，从固定 tree/v0.9.1 安装同来源六个完整技能。
- 六项 lock ref 从 v0.8.1 更新至 v0.9.1；review-pr 内容和 hash 更新，其余五个目录内容不变。
- 同步来源基线的日期、tag、peeled commit 与安装命令，完成计划归档。

### 设计意图

完整采用固定上游快照，获得线程维护、同名分支复用和复审快进修复；不手工修改受管内容或 hash，不跨来源升级第三方技能。

### 验证

- v0.9.1 tag object：`3295da05793b447d99d33f48738ed4820ba7fe25`；peeled commit：`eea85d3877b3bd46b8885cbab8f0d9729cbc9276`，本地与远程一致。
- 56 个文件匹配上游 tag archive；六项 lock 来源、ref、路径及目录 hash 验证通过。
- `PYTHONDONTWRITEBYTECODE=1 python3.12 -B -m unittest discover -s .agents/skills/review-pr/tests`：79 项通过。
- 六个技能 frontmatter、agents/openai.yaml 与 44 个相对链接检查通过；Python AST、Shell bash -n、JSON jq 与 git diff --check 通过。
- 第三方、项目专属技能及符号链接等 190 项保护内容和第三方 lock 条目未变；测试后快照清单仍一致。
- 按 review 技能核对升级差异、来源和宿主边界，无遗留 finding。
- 未更改应用源码、工程或构建配置，按规则未运行 Xcode 构建或 GUI 验证；未操作真实 PR。

### 受影响文件

- `.agents/skills/review-pr/`：与上游固定版本一致的完整快照差异。
- `skills-lock.json`、`docs/agents/skills.md`。
- 本任务计划及本记录。

### 后续事项

- None
