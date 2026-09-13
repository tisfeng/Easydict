---
name: submit-pr
description: 创建或复用当前 checkout 已提交变更的 GitHub PR，必要时推送任务分支。PR 审查使用 review-pr；仅本地提交使用 git-commit。
---

# 提交 GitHub PR

根据当前 Git checkout 的已提交变更，规划、创建或复用 GitHub Pull Request。
`<submit-pr-skill-dir>` 指实际加载的本 Skill 目录。

## 模式与授权

- `plan`：只读发现仓库拓扑，预览提交范围、标题、正文、base、head 和 push remote；
  不 fetch、创建分支、写仓库文件、push 或创建 PR。
- 默认：在明确的 PR 交付授权下，fetch 精确 base、推送任务分支、创建或复用正式 PR，
  并验证最终远程状态。
- `draft`：与默认模式相同，但创建 Draft PR。

用户未指定时使用默认模式。用户的只读、确认、暂缓和范围限制持续有效。

只有需要把既有 staged 内容创建为提交时才依赖 `git-commit`。从当前 Skill 清单定位实际入口，
未提供位置时才检查 [同级安装位置](../git-commit/SKILL.md)。干净的已有提交和纯 plan 不要求
该依赖；需要提交但依赖缺失时，可继续只读检查，但在提交、fetch 或 push 前停止。

## 主流程

1. 读取 [工作流契约](references/workflow.md)，确定用户语言、正文、Issue 策略、repository 拓扑、
   base/head 分支与恢复规则。
2. 记录 HEAD 和 staged、unstaged、untracked 边界。
3. `plan` 模式只使用现有提交和缓存的远程事实，运行 helper `plan` 并展示完整 PR 预览。
   缺少提交或 cached base 时报告预览缺口，不为使 plan 成功而写入。
4. 默认或 `draft` 模式要求工作树可安全交付：
   - 存在 unstaged 或 untracked 内容时停止，不运行 `git add`。
   - 仅 staged 非空时，按宿主交付规则使用 `git-commit`；工作树干净时复用已有提交。
   - 精确 fetch base ref，检查完整 `<base-remote>/<base>..HEAD` 提交与文件范围。
     范围为空、来源不明或 HEAD 未包含 base 时停止，不自动修正历史。
5. 根据真实范围起草内容，运行 helper `plan` 并展示语言来源和完整预览。
   默认模式继续；用户要求确认或暂缓时先停止。
6. 使用相同内容运行 helper `apply`；`draft` 追加 `--draft`。helper 重新发现并校验本地/远程状态，
   精确 push，创建或复用 PR，然后读回验证身份、head SHA、title、body 和 Draft 状态。
7. 报告 PR URL、base/head repository 与 branch、head SHA、Draft、分支/push/PR 动作和截图提醒。
   本轮创建提交时同时保留 `git-commit` 的完整回执。

## 安全、完成与停止

- 只支持 GitHub remote；拓扑有歧义时要求显式参数，不创建 fork。
- 不 force push，不 rebase、merge、reset、stash、删除 remote/分支，不切换 checkout 或推送保护分支。
- 不自动添加 reviewer、label、milestone 或 project，不 merge PR、评论或关闭 Issue。
- 只有 helper `apply` 返回成功且 `pr_verification.status == "passed"` 时才声称 PR 交付完成。
  默认不等待 CI；仅在用户或宿主规则要求时查询或等待 checks。
- 远程实体或已有 PR 与冻结计划不匹配、范围/身份漂移、授权被拒或写后验证失败时，
  保留已完成动作并停止；不覆盖维护者编辑、创建第二个 PR 或重复已成功的远程写入。
