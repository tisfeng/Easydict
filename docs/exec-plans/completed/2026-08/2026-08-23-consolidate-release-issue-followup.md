# 合并发布后 Issue 跟进到主发布 Skill

**Status:** completed
**Created:** 2026-08-23
**Updated:** 2026-08-23
**Owner:** Codex
**Links:** `.agents/skills/release-easydict/`、`.agents/skills/release-easydict-issue-followup/`

## 任务契约

- 任务模式：`implementation`
- 用户目标：删除独立的 `release-easydict-issue-followup` skill，将其作为
  `release-easydict` 的 `issue-followup plan|apply|resume` 子命令，并继续使用独立
  helper 实现确定性 Issue 操作。
- 允许动作：重组仓库 skill、迁移 helper/测试/参考文档、更新 Agent 文档、执行离线
  验证、记录历史并创建一次本地提交。
- 允许修改路径：`.agents/skills/release-easydict/`、
  `.agents/skills/release-easydict-issue-followup/`、`docs/agents/skills.md`、
  `docs/exec-plans/`、`docs/histories/2026-08/`。
- 预期交付物：一个同时支持发布生命周期和发布后 Issue 跟进的
  `release-easydict` skill；保留独立 `release_issues.py`、schema-v2 状态和固定报告。
- 验收标准：新子命令路由明确；`publish`/`release` 验证后自动执行内部
  `issue-followup apply`；直接 `apply` 仍先刷新计划；`resume` 仍只重试冻结批次；
  旧独立 skill 目录被移除；全部离线测试和 skill 校验通过。

## 自动提交状态

- 自动提交资格：`eligible`
- 初始暂存区：`empty`
- 初始未暂存区：`empty`
- 初始未跟踪路径：`empty`
- 初始分支：`dev`，相对 `origin/dev` 为 `ahead 1, behind 2`
- 自动提交结果：待验证完成后创建一个新的本地提交，不 push、不改写已有提交

## 目标

以一个领域 skill 提供全部 Easydict 发布能力，同时继续通过内部脚本、独立状态目录和
模式专用参考文档隔离高风险的 Issue 远程操作。

## 范围

- 包含范围：skill description、动作路由、授权边界、publish 编排、helper/测试迁移、
  参考文档和 Agent 文档同步。
- 不包含范围：修改 schema-v2 行为、迁移或删除 `.tmp` 状态、重新发布版本、评论或
  关闭真实 Issue、修改 PR 模板、同步远程分支或 push。

## 风险与缓解

- 风险：主发布 `resume` 与 Issue `resume` 含义混淆。
  - 缓解措施：Issue 恢复固定使用 `issue-followup resume <version>` 命名空间。
- 风险：合并入口后误把只读计划当作远程操作授权。
  - 缓解措施：`issue-followup plan` 单独声明为只读；`apply`/`resume` 仍要求明确请求或
    已授权 publish/release 的内部延续。
- 风险：文件移动破坏测试加载路径或既有状态。
  - 缓解措施：测试继续从 skill 根目录相对加载脚本；状态路径和 schema 保持不变。
- 风险：历史文档中的旧 skill 名称被误认为当前入口。
  - 缓解措施：当前规范文档只登记新入口；历史文件保留为已完成设计快照，并由新历史
    记录后续收敛。

## 里程碑

- [x] 记录初始 Git 状态并读取仓库、skill-creator 和两个 release skill 契约。
- [x] 将 helper、测试和策略迁入 `release-easydict`。
- [x] 重写单一 skill 的 description、动作路由、授权与恢复规则。
- [x] 更新 Agent 文档并移除独立 skill 目录。
- [x] 完成离线测试、skill 校验、静态检查、历史记录和自动本地提交。

## 验证

- `python3 -m unittest discover -s .agents/skills/release-easydict/tests -p 'test_*.py' -v`：
  通过，20 个测试成功。
- `python3 -m py_compile ...`：两个 helper 和两个测试文件均通过。
- `release_content.py --help`、`release_issues.py --help`：直接调用通过，两个 helper 均
  保持可执行权限。
- `quick_validate.py .agents/skills/release-easydict`：通过。
- `git diff --check`：通过。
- 当前 skill、`docs/agents/` 和 `AGENTS.md` 不再引用独立 skill 入口。
- 未执行真实 GitHub Release、Issue 评论或 Issue 关闭。

## 决策记录

- 2026-08-23：只保留 `release-easydict` skill；Issue 操作使用
  `issue-followup plan|apply|resume <version>` 子命令命名空间。
- 2026-08-23：保留 `release_issues.py`、schema-v2、固定三类 Markdown 汇总和
  `.tmp/release/<version>/state/issue-followup/` 状态目录。
- 2026-08-23：不提供旧 skill 的兼容 stub。

## 进度记录

- 2026-08-23：初始索引、未暂存区和未跟踪区均为空；当前分支存在远程分歧，本任务不
  执行 pull、rebase、merge 或 push。
- 2026-08-23：完成 helper、测试和策略迁移；主 skill 以命名空间区分发布恢复和 Issue
  恢复，并在 publish 验证后内部执行 `issue-followup apply`。
- 2026-08-23：20 个离线测试、Python 编译、两个 helper 入口、单一 skill 校验和 Git
  diff 检查全部通过。
