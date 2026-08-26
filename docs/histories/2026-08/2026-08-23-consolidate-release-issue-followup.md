## 2026-08-23 | 任务：合并发布后 Issue 跟进到主发布 Skill

**Links:** `../../exec-plans/completed/2026-08-23-consolidate-release-issue-followup.md`

### 用户请求

取消独立的 `release-easydict-issue-followup` skill，将发布后的 Issue 计划、执行和恢复
作为 `release-easydict` 的一部分，同时继续使用独立脚本隔离确定性远程操作。

### 变更

- 将 Issue helper、schema-v2 测试和关联决策策略迁入 `release-easydict`，删除独立
  skill 目录，不保留兼容入口。
- 更新 skill description 和动作路由，新增
  `issue-followup plan|apply|resume <version>` 命名空间，并与发布生命周期的
  `resume` 明确区分。
- 保留 `apply` 先刷新计划、`resume` 复用冻结批次、版本评论幂等、reopen 不阻止关闭、
  默认解决规则和固定三类 Markdown 汇总。
- `publish` 与 `release` 在 GitHub Release、appcast 和远程验证成功后，直接执行同一
  skill 内部的 `issue-followup apply` 行为。
- 更新 Agent skill 清单和 helper 命令映射；Issue 模式的详细流程与策略通过专用
  reference 渐进加载。

### 设计意图

发布生命周期和发布后的 Issue 跟进属于同一个 Easydict 版本交付领域，使用单一 skill
更容易发现和调用。高风险 Issue 写入仍通过独立 helper、独立状态目录和显式授权边界
隔离，因此合并入口不会混淆只读计划、发布恢复和远程 Issue 恢复。

### 验证

- 合并目录下 20 个 Python 单元测试全部通过。
- Python 编译、两个 helper 的直接 `--help` 和可执行权限检查通过。
- `release-easydict` 的 `quick_validate.py` 和 `git diff --check` 通过。
- 当前操作规范中不再引用被删除的独立 skill。
- 未执行真实 GitHub Release、Issue 评论或 Issue 关闭。

### 受影响文件

- `.agents/skills/release-easydict/`
- `.agents/skills/release-easydict-issue-followup/`
- `docs/agents/skills.md`
- `docs/exec-plans/completed/2026-08-23-consolidate-release-issue-followup.md`

### 后续事项

- 可以先运行 `$release-easydict issue-followup plan 2.22.0` 检查实际关联和固定分类，
  再根据需要直接调用 `issue-followup apply 2.22.0`。
- PR 模板中的显式发布目标字段仍按用户要求留待后续单独处理。
