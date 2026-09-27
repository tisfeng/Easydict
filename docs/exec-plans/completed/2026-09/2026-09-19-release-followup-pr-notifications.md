# Easydict 发布跟进 PR 通知与机器人过滤

- 状态：completed
- 创建日期：2026-09-19
- 负责人：/root
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `/root`
- **Model:** Unknown
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

## 背景

发布后的跟进目前只处理有关联 Issue 的 PR，机器人 PR 仍可能进入 changelog。需要统一发布 PR 分类，使机器人 PR 不进入用户可见更新日志或通知，并为没有有效 Issue 关联的人工 PR 增加发布通知。

## 目标与范围

- 目标结果：扩展 release-easydict 的 PR 分类、Issue/PR 通知计划、幂等状态和文档测试。
- 允许修改路径：`.agents/skills/release-easydict/`、`changelog/2.23.0.md`、本计划、本任务 history。
- 同任务 history：`docs/histories/2026-09/2026-09-19-release-followup-pr-notifications.md`
- 用户限制：不发布 Release，不评论或关闭 GitHub Issue/PR，不推送任何分支。
- 非目标：不修改应用生产代码，不改变 appcast 正式发布动作。
- 验收标准：机器人 PR 被统一过滤；人工无 Issue PR 生成幂等通知计划；PR 不触发关闭；测试和静态检查通过。

## 工作计划

1. 增加共享 PR 分类规则并接入 Release follow-up 收集。
2. 增加无 Issue PR 通知、目标专属 marker 和可恢复动作状态。
3. 更新 2.23.0 changelog、流程文档、策略文档和测试。
4. 运行测试、`git diff --check`，完成 review 后归档计划并写 history。

## 风险与决策

- 只忽略 GitHub API 标记为 bot 或精确已知 bot 登录名的 PR，不按 `chore` 泛化过滤。
- PR 通知默认使用英文，因为 Release Notes 是英文；Issue 仍由逐 Issue 决策选择语言。
- PR 只发表评论，不关闭 PR；Issue 关闭逻辑保持不变。
- schema 从 2 升至 3，拒绝复用旧 actions 状态，避免新动作被旧状态误解释。

## 进度

- [x] 共享分类与候选收集
- [x] PR 通知计划与执行状态
- [x] 文档、changelog 和测试
- [x] 验证、review、归档

## 验证

- `python3 -m unittest discover -s .agents/skills/release-easydict/tests -p 'test_*.py'`：30 项通过。
- `python3 scripts/release/release_notes.py validate --file changelog/2.23.0.md --version 2.23.0`：通过。
- `python3 .agents/skills/release-easydict/scripts/release_content.py validate-pr-policy --repo tisfeng/Easydict --version 2.23.0 --notes changelog/2.23.0.md`：通过，13 条人工 PR。
- `bash -n scripts/release/release-preflight.sh scripts/release/release-easydict.sh`、`python3 -m py_compile ...`、`git diff --check`：通过。

## 完成条件

- 代码、测试和文档完成，计划移动到 `docs/exec-plans/completed/2026-09/`。
- history 记录实际变更和验证结果。
