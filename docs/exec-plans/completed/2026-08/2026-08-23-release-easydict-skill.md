# Easydict 智能发布 Skill

**Status:** completed
**Created:** 2026-08-23
**Updated:** 2026-08-23
**Owner:** Codex
**Links:** `.agents/skills/release-easydict/`、`scripts/release/`

## 任务契约

- 任务模式：`implementation`
- 用户目标：新增仓库专用发布 skill，复用现有发布脚本，自动生成英文发布说明和重点标题，并在发布成功后处理现有 PR 弱关联的 issue。
- 允许动作：新增 skill、确定性 helper、离线测试、发布文档和本次计划/历史文档；运行本地静态与 fixture 校验；创建一次本地提交。
- 允许修改路径：`.agents/skills/release-easydict/`、`docs/agents/skills.md`、`scripts/release/README.md`、`docs/exec-plans/`、`docs/histories/2026-08/`
- 预期交付物：可发现、可恢复、正常路径无需人工选择内容或 issue 的 `release-easydict` skill。
- 验收标准：发布说明只翻译 PR 标题且保留 GitHub 元数据；主标题来自真实 PR；弱引用候选可验证且不把 PR 当 issue；只有完整解决的 issue 才允许发布后通知；重复执行不重复评论或关闭。

## 自动提交状态

- 自动提交资格：`eligible`
- 初始暂存区：`empty`
- 初始未暂存区：`empty`
- 初始未跟踪路径：`empty`
- 自动提交结果：本计划与实现由同一个收尾本地提交交付，不执行 push

## 范围

- 包含：skill 编排规则、Release Notes 解析/渲染、弱引用收集、语义决策契约、发布后幂等通知、离线 fixture 和文档。
- 不包含：修改 PR 模板、执行真实发布、编辑当前 Draft、评论或关闭真实 issue、改变现有 shell 发布入口语义。

## 风险与缓解

- 风险：裸 `#123` 实际指向 PR 或仅为背景引用。
  - 缓解措施：通过 GitHub issue API 解析实体，并要求关联性与完整解决两道决策门都通过。
- 风险：模型遗漏或虚构 Release Notes 条目。
  - 缓解措施：helper 要求翻译清单与原始 PR 集合完全一致，并保留作者、链接和编号。
- 风险：发布恢复时重复评论或关闭 issue。
  - 缓解措施：评论使用版本隐藏标记，动作状态逐项持久化，远程操作前重新验证 Release。
- 风险：测试误操作线上数据。
  - 缓解措施：单元测试只使用 fixture；远程修改命令必须显式传入 `--execute`。

## 里程碑

- [x] 创建 skill 入口和详细 issue 判断策略。
- [x] 实现发布说明捕获、校验、渲染和 Draft 更新 helper。
- [x] 实现弱引用收集、决策校验、评论渲染和幂等执行 helper。
- [x] 补充离线测试和仓库文档。
- [x] 完成 skill、Python、Markdown 和 Git diff 校验。
- [x] 将计划移到 `completed/`，记录历史并自动本地提交。

## 验证

- `python3 .../skill-creator/scripts/quick_validate.py .agents/skills/release-easydict`：通过。
- `python3 -m unittest discover -s .agents/skills/release-easydict/tests -p 'test_*.py'`：
  通过，17 个测试成功。
- `python3 -m py_compile ...`：两个 helper 和两个测试文件均通过。
- 两个 helper 的直接 `--help` 调用：通过，文件具有可执行权限。
- `git diff --check`：通过。
- 未执行真实 Draft、publish、issue comment 或 issue close；测试全部使用离线 fixture。

## 决策记录

- 2026-08-23：本阶段不新增 PR 模板，兼容现有 closing reference、issue URL、`owner/repo#123` 和裸 `#123`。
- 2026-08-23：`closingIssuesReferences` 仅作为候选来源；自动通知必须同时满足目标关联和完整解决。
- 2026-08-23：现有发布脚本保持执行引擎角色，skill 在 Draft 与 publish 之间编排内容，在 publish 成功后编排 issue 跟进。

## 进度记录

- 2026-08-23：确认初始工作树干净、暂存区为空；当前 `dev` 比 `origin/dev` 领先一个既有发布修复提交。
- 2026-08-23：完成英文 Release Notes/标题 helper、弱关联 issue 两道决策门、发布后降级保护、
  远程评论标记和 reopen 防重复关闭。
- 2026-08-23：完成 17 个离线测试、skill 校验、Python 编译检查、helper 入口检查和文档同步。
