# Issue Translator Action v2.8.2 更新

**Status:** completed
**Created:** 2026-09-04
**Updated:** 2026-09-04
**Owner:** Codex
**Links:** `tisfeng/issues-translate-action` `v2.8.2`

## 任务契约

- 任务模式：`delivery`
- 用户目标：先修复并发布 `issues-translate-action` 的 Google 翻译依赖，再在本地 `dev` 更新 Easydict 的 Issue 翻译工作流引用并推送。
- 允许动作：提交并推送 Action 的 `main`，创建和推送 `v2.8.2` tag，更新本工作流、创建 history 与本计划，并提交、推送 `dev`。
- 允许修改路径：`.github/workflows/issue-translator.yml`、`docs/exec-plans/`、`docs/histories/2026-09/`。
- 禁止动作：不创建 GitHub Release 或 PR；不修改其他工作流、产品代码、Xcode 工程或用户内容。
- 验收标准：Easydict 仅引用已推送的 `v2.8.2` tag；YAML 与 diff 静态验证通过；`dev` 推送前后均无远端分叉。

## 初始状态

- 仓库：Easydict
- 分支：`dev`
- `initial_head`：`f863c541c29d6902a86e62f2660e9ea74ce586ff`
- 初始暂存区：空
- 初始工作树：干净
- 初始冲突：无

## 实施步骤

- [x] 为 Action 的底层翻译失败补充向外传播的回归测试，并重跑 Action 验证。
- [x] 精确提交并推送 Action 的客户端迁移，创建并推送 `v2.8.2` tag。
- [x] 将 Easydict 的 `issue-translator` 工作流从 `v2.8.1` 更新为 `v2.8.2`。
- [x] 验证 YAML、变更范围和 diff，记录 history，将本计划归档并精确提交、推送 `dev`。

## 风险与决策

- `google-translate-api-x` 依赖 Google 网页端的非官方 batch RPC；本次只更新已固定版本的 Action tag，不引入官方 Google Cloud API。
- 测试覆盖客户端调用选项和失败传播；本地网络无法代替 GitHub 托管 Runner 的真实 Google 连通性验证。
- tag 是工作流依赖的不可变部署边界，必须先确认 `v2.8.2` 已推送才更新 Easydict 引用。

## 验证

- Action `npm test -- --runInBand`：17 项测试通过；`npm run build`、`npm run package`、`npm run format-check` 和 `git diff --check`：通过。
- Action `f0170e1913ea679197821b5b7058ed5d9d221f9c` 已推送至 `main`；带注释的 `v2.8.2^{}` 解析到同一提交。
- Easydict 工作流 YAML：Ruby `YAML.safe_load` 解析通过；`git diff --check` 通过；仅有允许路径中的 workflow、计划和 history 变更。
