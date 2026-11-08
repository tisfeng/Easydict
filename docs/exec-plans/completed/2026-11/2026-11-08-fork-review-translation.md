# 恢复 fork PR 行内评论翻译

- 状态：completed
- 创建日期：2026-11-08
- 负责人：Codex
- 关联 Issue/PR：无

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B52)`

## 背景

默认工作流 token 在 fork PR 行内评论事件中只有读权限，翻译后无法写回原线程。

## 目标与范围

- 目标结果：通过独立的发布工作流恢复 fork PR 的行内回复。
- 允许修改路径：.github/workflows/ 和任务记录。
- 同任务 history：`docs/histories/2026-11/2026-11-08-fork-review-translation.md`
- 用户限制：本地集成 Easydict 工作流。
- 非目标：运行真实 GitHub workflow。
- 验收标准：通过评论 ID 获取原文并回复原线程，保留已有事件入口。

## 工作计划

1. 增加按 ID 翻译入口并重新打包。
2. 接入 fork 事件与有写权限的发布工作流。
3. 本地验证、审查并提交。

## 风险与决策

- 发布工作流只接收评论标识，从 GitHub 读取正文，不执行 fork 代码。
- GitHub 的 fork 运行审批仍适用。

## 进度

- [x] 实现、验证和审查。
- [x] 使用已发布的 v2.10.0 更新两段工作流。

## 验证

- 两份 workflow 通过 `actionlint`，ID 提取脚本通过 `bash -n`。
- 本地模拟验证正确尝试、缺失记录、重复记录、非法标识与 API 失败。
- 仅本地验证，未运行真实 GitHub workflow。

## 完成条件

- 本地验证与审查通过后归档。
