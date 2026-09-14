---
name: worktree-rebase-merge
description: 将当前 worktree 的任务提交 rebase 到本地目标分支，并从目标 worktree 合并。用于明确要求本地集成；仅创建提交使用 git-commit。
---

# Worktree Rebase/Merge 工作流

将当前 checkout 视为源：必要时创建任务分支并提交，rebase 到目标分支，
再从目标分支的 worktree 合并。源与目标相同时只提交，不 rebase 或 merge。

## 依赖与授权

完整交付依赖 `git-commit` 的提交、分支命名和已有提交回执能力。从当前 Skill 清单
定位实际入口，未提供位置时才检查 [同级安装位置](../git-commit/SKILL.md)。缺失时可完成
只读预检，但在首次分支、暂存、提交、rebase 或 merge 写入前停止。

本 Skill 只在用户明确要求本地集成时执行 Git 写入。仅预览或只读请求不创建分支/
worktree、不暂存、提交、rebase 或 merge。除非用户明确要求，不 fetch、pull 或 push。

## Git 状态保护

- 开始前确认允许路径、提交范围、用户限制，以及源/目标的 HEAD、索引、工作树、
  worktree 占用和进行中操作。
- Git 写操作串行执行；每次写入前复验相关状态，写入后确认结果符合预期。
- rebase 前冻结源提交范围与目标 OID；rebase 后核对改写结果。merge 前确认源干净、
  目标仍为冻结 OID，且目标 worktree 没有漂移。
- 不使用 reset、强制移动 ref、stash 或 clean，不切换用户其他 checkout 的分支。
- 发现非预期漂移、未解冲突、范围不一致、不能安全处理的语义冲突或权限拒绝时，
  保留现场并停止后续写入。

## 主流程

1. 读取 [集成协议](references/integration-workflow.md)，使用其只读 helper 收集稳定的源/目标事实。
2. 用户指定目标时使用该分支；否则按集成协议实时解析远程默认分支。目标或 remote
   有歧义、无法证明实时默认分支或本地目标不存在时，在写入前停止并请用户指定。
3. detached HEAD 按集成协议挂接到不覆盖现有 ref 的任务分支。没有 staged、unstaged、
   untracked 或相对目标的提交时，不创建空分支。
4. 源与目标相同时，只使用 `git-commit` 完成提交和回执。
5. 其他情况先用 `git-commit` 提交获准的源变更，要求源 worktree 干净；再检查完整
   `<target>..<source>` 提交和路径范围，执行 `git rebase <target>` 并验证改写结果。
6. 在干净的目标 worktree 执行 `git merge <source>`。没有目标 worktree 时，在仓库外创建临时
   worktree，成功合并后删除；冲突或失败时保留供恢复。
7. 读取 [集成回执](references/reporting.md)，报告真实分支、OID、worktree、rebase/merge、工作树和
   Push 状态；单提交或多提交统计复用 `git-commit` 的回执契约。

## 完成与停止条件

直接提交模式在 `git-commit` 完成时结束。普通集成只有在源已成功 rebase、目标从冻结
OID 按预期合并、源与目标最终状态已验证且回执完整时才算完成。目标只有脏
worktree 时，允许先完成源提交，然后在 rebase/merge 前暂停；恢复步骤见集成协议。
