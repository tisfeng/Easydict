# 清理已完成版本的 .tmp 数据

- 状态：completed
- 创建日期：2026-09-24
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

## 背景

用户要求清理当前 `.tmp`。2.22.0 和 2.23.0 已发布并完成 Issue 跟进。2.22.0 首次清理移除了注册 worktree，但删除大型 DerivedData 时遇到目录重新出现 `.DS_Store`，留下可恢复收据。

## 目标与范围

- 目标结果：清空当前 `.tmp` 内容，并修复清理脚本对短暂 `ENOTEMPTY` 错误的处理。
- 允许修改路径：`.agents/skills/release-easydict/scripts/release-cleanup.py`、本计划及对应 history；清理 `.tmp` 内已核验的临时内容。
- 同任务 history：`docs/histories/2026-09/2026-09-24-release-tmp-cleanup.md`
- 用户限制：不修改 GitHub 或其他远程服务；不删除 `.tmp` 之外的工作树或缓存。
- 非目标：更改发布流程和构建配置。
- 验收标准：2.22.0、2.23.0 及其他确认无用的临时内容清理完成；`.tmp` 为空；Git 状态正常。

## 工作计划

1. 核对目录占用、发布完成状态、工作树与活动进程。
2. 修复有限重试并在隔离目录验证，然后继续 2.22.0、2.23.0 清理。
3. 核对其他临时文件来源并清空剩余内容，复查 Git 状态。
4. 审查代码，记录 history 并创建本地提交。

## 风险与决策

- 注册 worktree 必须由 `git worktree remove` 先移除；不直接删除 `.git` 管理目录。
- 只对 `ENOTEMPTY` 做有限重试，其他删除错误立即报告。
- 清理失败时保留收据并复用同一版本命令，不重复发布。

## 进度

- [x] 完成盘点与发布状态预览。
- [x] 修复并验证删除重试。
- [x] 完成实际清理与复查。
- [x] 审查并提交。

## 验证

- `python3 -m py_compile`、`git diff --check`：通过。
- 注入两次 `ENOTEMPTY` 的隔离目录验证：有限重试后成功删除。
- 实际 `cleanup 2.22.0 --execute`、`cleanup 2.23.0 --execute`：成功；2.22.0 中的 3 个注册 worktree 先由 Git 移除。
- 核对 `.tmp` 无子项、占用 0B、无 `.tmp/release` 注册 worktree、无构建锁。
- Xcode 构建未运行：仅修复本地清理脚本，不涉及 App 构建图。

## 完成条件

- `.tmp` 为空，清理命令没有遗留的注册 worktree 或锁；隔离测试和静态检查通过，代码审查无未解决 finding。
