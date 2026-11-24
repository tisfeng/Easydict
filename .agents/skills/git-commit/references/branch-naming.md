# 统一分支命名

本文件是 Agent 拟定分支名称的唯一规则入口；生成、分类和校验由
[`branch_name.py`](../scripts/branch_name.py) 实现。其他技能引用本规范并调用工具，不维护另一套正则或名称拼接。
命名不创建、切换或移动分支，操作授权和保护分支检查仍由调用流程负责。

## 名称来源

- 用户明确指定名称时，使用该 Git 合法字面名称；不把 `@{-1}` 等 checkout 简写当作名称。
- 既有分支保持原名，不因不符合默认格式自动重命名。
- Agent 自行拟定开发任务名时，只使用下表的任务格式；不以 Agent、客户端或模型名称作为前缀。
- PR 审查和发布同步的自动化分支使用下表的专用格式，不自行增加命名空间。

## 格式

| 用途 | 格式与选择 |
| --- | --- |
| 开发任务 | `<type>/<english-kebab-case-summary>`；type 使用 `feat`、`fix`、`docs`、`style`、`refactor`、`perf`、`test`、`build`、`ci`、`chore`、`revert`，含义见[提交信息契约](commit-message.md#type-指南) |
| PR 审查 | `review/pr-<number>-<sha10>`；使用准确 PR 编号和冻结 head SHA 的前 10 位小写十六进制字符 |
| latest-base 审查 | `review/pr-<number>-merge-<sha10>`；仅用于隔离的 latest-base 审查分支 |
| 发布同步 | `release/sync-<version>`；version 为点分数字版本，可带 `v` 前缀和小写预发布后缀 |

任务摘要使用简洁英文表达实际变更，小写字母或数字以单个连字符连接，不包含 scope 标点、空格或下划线。
Agent 从任务和只读 diff 选择最窄的 type，再把明确的英文摘要传给工具；工具不从标题猜测含义。

## 工具接口

```bash
python3 <git-commit-skill-dir>/scripts/branch_name.py task --type fix --summary remove-github-models
python3 <git-commit-skill-dir>/scripts/branch_name.py review --pr 42 --sha <head-sha> [--merge-latest]
python3 <git-commit-skill-dir>/scripts/branch_name.py release --version 2.25.0
python3 <git-commit-skill-dir>/scripts/branch_name.py validate --name <explicit-name>
python3 <git-commit-skill-dir>/scripts/branch_name.py is-task --name <existing-name>
python3 <git-commit-skill-dir>/scripts/branch_name.py candidate --name <name> --number 2
```

- 生成和校验成功时输出名称；`is-task` 只通过退出码报告是否符合默认任务格式（0 是，1 否）。输入错误退出 2。
- 冲突候选从原名开始，再尝试 `-2`、`-3` 等后缀。消费端检查引用占用、提交身份、保护名称及远程状态；不以改名绕过这些检查。
- Python 消费端可加载同一脚本的 `task_name`、`is_task_name`、`validate_literal`、`review_name`、`release_name`、`candidate_name`；Shell 使用 CLI。
- `submit-pr`、`review-pr`、`worktree-rebase-merge` 需要同级完整安装 `git-commit`。依赖缺失时报告安装要求，不回退到本地复制的规则。
