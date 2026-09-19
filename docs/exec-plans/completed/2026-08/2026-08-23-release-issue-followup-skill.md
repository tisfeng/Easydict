# Easydict 发布后 Issue 跟进 Skill

**Status:** completed
**Created:** 2026-08-23
**Updated:** 2026-08-23
**Owner:** Codex
**Links:** `.agents/skills/release-easydict/`、`.agents/skills/release-easydict-issue-followup/`

## 任务契约

- 任务模式：`implementation`
- 用户目标：将发布后的 issue 通知与关闭逻辑提取为独立 skill，固定默认解决规则、三类 Markdown 汇总以及 `plan`、`apply`、`resume` 行为，并接入主发布流程。
- 允许动作：新增和修改仓库 skill、确定性 helper、离线测试、Agent 文档、本次计划与历史文档；执行本地验证；创建一次本地提交。
- 允许修改路径：`.agents/skills/release-easydict-issue-followup/`、`.agents/skills/release-easydict/`、`docs/agents/skills.md`、`docs/exec-plans/`、`docs/histories/2026-08/`
- 预期交付物：可独立测试和恢复的 `release-easydict-issue-followup` skill，以及委托该 skill 的 `release-easydict` publish 编排。
- 验收标准：`plan` 全程只读；`apply` 无需已有 plan 并在执行前刷新；关联 PR 默认视为已解决，只有带来源的明确反证才阻止关闭；reopen 不阻止关闭；汇总只使用固定三类并包含 issue/PR Markdown 链接；重复执行不重复评论。

## 自动提交状态

- 自动提交资格：`eligible`
- 初始暂存区：`empty`
- 初始未暂存区：`empty`
- 初始未跟踪路径：`empty`
- 自动提交结果：本计划与实现由同一个收尾本地提交交付，不执行 push

## 输入来源

- 用户明确请求：按已确认方案执行，并采用 `release-easydict-issue-followup` 名称。
- 仓库规则：`AGENTS.md`、`docs/agents/repository-guide.md`、`docs/agents/skills.md`。
- 现有实现：`.agents/skills/release-easydict/` 中的 issue helper、策略、测试和 publish 编排。
- 仅作为证据的内容：2.22.0 已发布后的 issue 处理结果及 #1201、#1206 的误判案例。

## 目标

让 issue 跟进成为独立、确定、可重复执行的发布后阶段。主发布 skill 只负责在远程发布验证成功后委托；独立 skill 负责收集、判断、计划、执行、恢复和固定格式报告。

## 范围

- 包含范围：skill 拆分、schema v2、默认解决策略、显式反证、幂等动作、固定 Markdown 汇总、publish 委托、离线测试和文档同步。
- 不包含范围：修改 PR 模板、重新发布版本、评论或关闭真实 issue、push 任何提交。

## 风险与缓解

- 风险：弱编号引用实际是 PR 或无关对象。
  - 缓解措施：保留 GitHub 实体解析和逐 PR 关联审计；拒绝项只进入机器审计。
- 风险：直接 `apply` 使用过期状态。
  - 缓解措施：每次 `apply` 先重新收集和生成最新计划；`resume` 才复用已冻结的未完成批次。
- 风险：远程操作部分完成后重试产生重复评论。
  - 缓解措施：使用版本隐藏标记和逐 issue 原子状态；重试时仍关闭当前开放且已解决的 issue。
- 风险：旧 schema v1 状态污染新测试。
  - 缓解措施：新状态写入独立的 `state/issue-followup/` 目录，不读取旧文件。

## 里程碑

- [x] 确认范围、旧实现和 Git 初始状态。
- [x] 新增独立 skill、策略、helper 和 schema v2。
- [x] 接入主发布 skill 并移除重复的旧 issue 实现。
- [x] 完成单元测试、skill 校验和静态检查。
- [x] 记录历史，将计划移到 `completed/` 并自动本地提交。

## 验证

- `python3 -m unittest discover -s .agents/skills/release-easydict/tests -p 'test_*.py' -v`：通过，7 个测试成功。
- `python3 -m unittest discover -s .agents/skills/release-easydict-issue-followup/tests -p 'test_*.py' -v`：通过，13 个测试成功。
- `python3 -m py_compile ...`：主发布 helper、新 issue helper 和测试文件均通过。
- `quick_validate.py`：`release-easydict` 和 `release-easydict-issue-followup` 均通过。
- 两个 helper 的直接 `--help` 调用：通过；新 helper 已设置可执行权限。
- `git diff --check`：通过。
- 未执行真实发布、issue 评论或 issue 关闭；所有新行为测试均为离线 fixture/mocking。

## 决策记录

- 2026-08-23：skill 名称固定为 `release-easydict-issue-followup`。
- 2026-08-23：`apply` 是完整动作入口，不要求先运行 `plan`；`plan` 仅用于只读预览。
- 2026-08-23：publish 完成远程验证后才委托 `apply`，issue 阶段失败不回滚 Release。
- 2026-08-23：每个 source PR 都必须明确标记为 `fixes`、`related` 或 `rejected`；含 `fixes` 时默认解决，只有带 GitHub URL 的明确反证才允许保留 issue。
- 2026-08-23：已有版本评论只阻止重复评论；reopen 历史和旧的本地关闭状态都不能阻止关闭当前开放且已解决的 issue。

## 进度记录

- 2026-08-23：初始工作树、索引和未跟踪路径均为空；已读取仓库规则、skill-creator、主发布 skill、git-commit 及旧 issue helper。
- 2026-08-23：完成独立 skill、schema-v2 决策和状态目录、确定性三类 Markdown 报告，以及主 publish 委托。
- 2026-08-23：完成 20 个离线测试、两个 skill 校验、Python 编译检查、helper 入口和 Git diff 校验。
