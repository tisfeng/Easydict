# Issue Translator Action v2.9.1 升级

- 状态：completed
- 创建日期：2026-09-09
- 完成日期：2026-09-09
- 负责人：Codex

## 任务契约

- 意图模式：implementation
- 交付授权：push
- 目标：仅在上游 `tisfeng/issues-translate-action@v2.9.1` 已发布并核验后，更新 Easydict 的 Issue 翻译工作流引用。
- 允许写入：`.github/workflows/issue-translator.yml`、本计划及其 completed 归档、`docs/histories/2026-09/2026-09-09-issue-translator-v2-9-1.md`。
- 禁止操作：不改动工作流触发器、权限、输入配置、产品代码或其他自动化；不触发真实 workflow。

## 写入前快照

- `HEAD` 与 `origin/dev`：`03f42bcc8f6ff249017cf3c2ef11e712813fd930`
- staged、unstaged、untracked 和冲突：均为空。
- 当前引用：`tisfeng/issues-translate-action@v2.9.0`。

## 执行结果

1. 已核验上游 `v2.9.1` 的远端 tag peeled SHA 为 `71e9aa61b05d65b9d82faedbe926b5985255f48b`，GitHub Release 为 stable。
2. 仅将 `uses:` 引用从 `v2.9.0` 更新至 `v2.9.1`；事件和 inputs 保持原样。
3. 已执行 YAML 解析与 diff 静态检查；未触发真实 workflow。

## 完成条件

- [x] `dev` 引用已发布的 `v2.9.1` tag。
- [x] YAML 配置语义未变。
- [x] 任务记录可与更新一同交付。
