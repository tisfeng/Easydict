## 2026-09-15 | 任务：Upgrade Managed Skills V0.5.0

**Links:** [`docs/exec-plans/completed/2026-09/2026-09-15-upgrade-managed-skills-v0.5.0.md`](../../exec-plans/completed/2026-09/2026-09-15-upgrade-managed-skills-v0.5.0.md)

### 用户请求

将 EasyKOL Scout 与 Easydict 的六个 `tisfeng/skills` 受管 Skill 升级到最新 `v0.5.0`。

### 变更

- 使用 `skills@1.5.25` 从固定 `v0.5.0` tag 同步六个完整 Skill 目录，并更新 lock 中的 ref 与 hash。
- `submit-pr` 新增固定 PR 正文模板、detached checkout 分支处理及对应验证；其余五个 Skill 内容不变。
- 更新来源参考，记录 annotated tag object 与 peeled commit。

### 设计意图

固定 tag 和完整仓库快照确保离线可审查与可复现；仅覆盖 lock 声明的六个目录，保留独立来源的
`fireworks-tech-graph`、项目专属 `release-easydict` 以及宿主 Swift/Xcode 规则。

### 验证

- `diff -qr`：两个仓库的六个安装目录均与 `v0.5.0` 上游快照一致。
- 独立 SHA-256 重算：两个仓库的全部 lock 条目均匹配。
- 受管 Skill 单元测试：94 项通过（13 + 7 + 45 + 23 + 6）。
- `jq -e . skills-lock.json`：通过。
- `git diff --check`：通过。
- `review`：未发现阻塞 finding。

### 受影响文件

- `.agents/skills/submit-pr/`
- `skills-lock.json`
- `docs/references/tisfeng-skills.md`
- `docs/exec-plans/completed/2026-09/2026-09-15-upgrade-managed-skills-v0.5.0.md`
- `docs/histories/2026-09/2026-09-15-upgrade-managed-skills-v0.5.0.md`

### 后续事项

- 未执行真实 GitHub PR 创建；本任务通过受管 Skill 测试验证新流程，不对外部仓库写入。
