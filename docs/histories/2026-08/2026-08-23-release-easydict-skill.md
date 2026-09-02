## 2026-08-23 | 任务：新增 Easydict 智能发布 Skill

**Links:** `../../exec-plans/completed/2026-08-23-release-easydict-skill.md`

### 用户请求

复用现有 macOS 发布脚本新增仓库 skill，自动将 GitHub Release Notes 整理为英文、生成重点
发布标题，并在正式发布后判断和处理现有 PR 弱关联的 issue，全程无需逐项人工选择。

### 变更

- 新增 `release-easydict` skill，将现有 `draft` 和 `publish` 作为执行引擎，在两阶段之间
  编排 Draft 内容和 issue 决策。
- 新增发布说明 helper，严格保持 GitHub 的 PR 作者、编号、链接、contributors 和 changelog，
  同时验证英文标题、重点 PR、源快照和 Draft 并发变化。
- 新增 issue helper，从 closing reference、issue URL、`owner/repo#123` 和裸 `#123`
  收集候选，经 GitHub API 排除 PR 实体，并执行关联性与完整解决两道判断门。
- 发布前冻结候选和决策；发布后只允许降级，不允许新增或升级 issue 动作。版本评论带幂等标记，
  即使本地状态丢失，也不会再次关闭发布通知后被重新打开的 issue。
- 增加 17 个离线行为测试和中文发布文档，不修改现有 shell 发布入口语义。

### 设计意图

保留 `scripts/release/` 对构建、公证、Git、appcast 和 GitHub Release 的职责，将需要语义判断的
英文整理和 issue 完成度判断放在 skill 层。弱引用只提供候选，不直接授予关闭权限；只有真实目标且被
当前 Release 完整解决的 issue 才能在远程发布验证成功后收到评论并被关闭。

### 验证

- `python3 .../skill-creator/scripts/quick_validate.py .agents/skills/release-easydict`：通过。
- `python3 -m unittest discover -s .agents/skills/release-easydict/tests -p 'test_*.py'`：
  通过，17 个测试成功。
- `python3 -m py_compile ...`：通过。
- 两个 helper 的直接 `--help` 调用和可执行权限检查：通过。
- `git diff --check`：通过。
- 未执行真实发布或 issue 远程写入。

### 受影响文件

- `.agents/skills/release-easydict/`
- `docs/agents/skills.md`
- `docs/exec-plans/completed/2026-08-23-release-easydict-skill.md`
- `docs/histories/2026-08/2026-08-23-release-easydict-skill.md`

### 后续事项

- PR 模板中的显式发布目标字段按用户要求留待后续单独处理；当前实现兼容已有弱关联 PR。
