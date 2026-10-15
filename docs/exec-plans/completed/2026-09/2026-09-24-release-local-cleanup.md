# 发版成功后清理本地临时文件

- 状态：completed
- 创建日期：2026-09-24
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

## 背景

发布工作流成功后，`.tmp/release/<version>/` 仍保留归档、DerivedData、日志和恢复状态。旧版本不再复用这些文件，且旧目录中可能存在注册的 Git worktree。

## 目标与范围

- 目标结果：发布和 Issue 跟进均成功后安全清理该版本的本地临时数据，保留可跨版本复用的构建缓存；支持预览和失败后重试。
- 允许修改路径：`.agents/skills/release-easydict/`、`docs/releases/easydict.md`、本计划及对应 history。
- 同任务 history：`docs/histories/2026-09/2026-09-24-release-local-cleanup.md`
- 用户限制：本次不实际删除历史 2.22.0、2.23.0 的数据；不修改远程服务。
- 非目标：重新设计发布工作流、清理仓库其他 `.tmp` 路径。
- 验收标准：未完成版本不能删除；成功版本预览无副作用；清理仅针对目标版本与对应 ASC 运行；注册 worktree 安全移除；缓存不误删；失败可重试。

## 工作计划

1. 核对 ASC 运行、Issue 计划和 Git worktree 的实际状态契约。
2. 实现带完成状态门禁的预览和执行命令，并接入发布 Skill 的最终阶段。
3. 更新文档，运行脚本检查和隔离场景验证，审查代码。
4. 记录 history、归档计划并创建本地提交。

## 风险与决策

- 发布成功后的清理不会进入 ASC workflow，以免在 Issue 跟进前删除恢复数据。
- 版本路径和 symlink 必须严格限制；未知内容导致拒绝清理。
- 不改变 `release-common.sh` 和 `asc-workflow.json`，避免无关的构建缓存指纹变化。
- 跨版本缓存整体保留；没有可靠的未完成发布引用索引时，不按目录时间猜测过期 fingerprint。

## 进度

- [x] 读取发布记录与仓库规则。
- [x] 实现清理与文档。
- [x] 验证与审查。
- [x] 记录并提交。

## 验证

- `bash -n`、`py_compile`、`git diff --check`：通过。
- 2.22.0、2.23.0 真实目录仅预览：分别估算 15.81 GiB、8.40 GiB，未删除。
- 隔离 Git 仓库验证：未完成 Issue、脏 worktree 和新运行会阻止清理；预览无删除；执行保留缓存及其他版本、移除注册 worktree；中断后可重试。
- 现有 80 项 release unittest：79 项通过；`test_build_lock_rejects_second_owner` 在测试临时 Git 仓库销毁时稳定报 `Directory not empty`，未修改的 `release-common.sh` 测试路径，与新清理脚本无调用关系。
- Xcode 构建：未运行；本次仅修改 Skill、独立清理脚本和文档，没有修改 App 构建图。

## 完成条件

- 预览与执行覆盖成功、未完成、脏 worktree 和重复运行；静态检查与隔离场景通过，审查无未解决 finding；现有测试的临时目录清理错误单独记录。
