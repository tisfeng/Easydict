# 移植本地 Git 交付 Agent 提交链

- 状态：active
- 创建日期：2026-09-07
- 负责人：Codex
- 关联 Issue/PR：无

## 任务摘要与授权

- 意图模式：implementation；交付授权：auto-local-commit；安全状态：normal。
- 目标结果：按顺序移植 Scoco 提交 `ae847c0e3` 与 `4ca75d911`，先引入专用
  `git_committer`，再统一为 `git_delivery`。
- 允许修改路径：`.codex/agents/`、`AGENTS.md`、`docs/agents/git-workflow.md`、
  `.agents/skills/worktree-rebase-merge/SKILL.md`、本任务 plan/history。
- 约束：保留 Easydict 既有的空索引暂存规则；不修改产品代码、`git-commit` Skill 或远程
  状态；按源提交语义分别创建两次本地提交。

## 写入前状态

- 初始 HEAD：`0bbbd4f7cdc40f160e5e54ceee9e200ae757b05e`。
- 初始 staged、unstaged、untracked、冲突：均为空。
- 写入前检查：pass；自动提交资格：eligible。
- Agent-owned paths：允许修改路径中本任务实际产生差异的文件。

## 工作计划

1. [x] 对比两个源提交与 Easydict 当前规则，识别并保留本地的空索引暂存差异。
2. [x] 移植 `ae847c0e3`：新增 `git_committer`，并将普通本地交付路由到该 Agent。
3. [ ] 验证第一层配置、完成独立审查并按交付协议创建第一笔本地提交。
4. [ ] 移植 `4ca75d911`：以 `git_delivery` 取代 `git_committer`，纳入 worktree 集成。
5. [ ] 验证最终配置、完成独立审查、归档计划并创建第二笔本地提交。

## 验收与验证

- 所有 custom agent TOML 可由 `tomllib` 解析，且模型、推理强度、沙箱配置符合源提交。
- 路由目标与 Markdown 相对链接存在；`git diff --check` 通过。
- 第一笔提交只包含 `git_committer` 阶段；第二笔提交只包含统一后的 `git_delivery` 阶段和
  worktree 协议。
- 本次仅修改 Agent 配置与治理文档，不运行 Xcode 构建或产品测试；静态验证不能替代全新
  Codex 会话对 custom agent 发现和模型身份的实际 smoke。
