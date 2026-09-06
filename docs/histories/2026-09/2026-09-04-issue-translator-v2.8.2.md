# Issue Translator Action v2.8.2 更新

- 日期：2026-09-04
- 状态：completed
- 关联计划：[`2026-09-04-issue-translator-v2.8.2.md`](../../exec-plans/completed/2026-09-04-issue-translator-v2.8.2.md)
- 上游 Action 提交：`tisfeng/issues-translate-action@f0170e1913ea679197821b5b7058ed5d9d221f9c`

## 用户请求

修复翻译 Action 后提交、推送并创建可引用的版本，再直接在 Easydict 本地 `dev` 更新翻译工具。

## 变更

- 上游 Action 将已失效的 `@tomsun28/google-translate-api` 替换为固定的 `google-translate-api-x@10.7.3`，强制使用 Google 网页翻译 batch RPC，并让 provider 拒绝传播到顶层失败信息。
- 上游添加了 batch 选项、原文结果和 provider 拒绝传播的测试，重新生成了运行时 `dist` bundle。
- Easydict 的 `.github/workflows/issue-translator.yml` 从 `tisfeng/issues-translate-action@v2.8.1` 更新为已推送的 `@v2.8.2`。

## 设计意图

Easydict 只固定引用经过验证的 Action tag，不直接依赖分支。此次保持非官方 Google 网页端 batch 协议边界，不引入 Google Cloud API，也不改动其他自动化或产品代码。

## 验证

- Action `npm test -- --runInBand`：17 项测试通过。
- Action `npm run build`、`npm run package`、`npm run format-check`、`git diff --check`：通过。
- 上游 `main`：`f0170e1913ea679197821b5b7058ed5d9d221f9c` 已推送；`v2.8.2^{}` 解析到同一提交。
- Easydict 工作流 YAML 解析、`git diff --check` 和变更范围审计：通过；提交前 `dev` 与 `origin/dev` 均为 `f863c541c29d6902a86e62f2660e9ea74ce586ff`。

## 后续事项

- 不创建 GitHub Release 或 PR；GitHub 托管 Runner 的下一次工作流运行将验证真实的 Google 网络连通性。
