# 去除 git-commit skill 的项目耦合

- 日期：2026-08-27
- 状态：completed
- 来源：Scoco `896f494358832f54c0d84cd3186d0cc2b89b556c`

## 背景

Easydict 的 `git-commit` skill 仍包含 Easydict 项目名称、OpenAI 和截图翻译示例，以及测试夹具中的项目专属用户名。通用 skill 不应依赖这些产品上下文。

## 变更

- 将 scope、英文和中文提交示例改为通用 UI 场景。
- 将提交信息校验器的说明和测试用户名改为通用表述。
- 保留一次性空索引 fallback、staged-only、implementation 精确暂存和提交信息契约。
- Scoco 同时删除的 `.agents/openai.yaml` 在 Easydict 中不存在，因此不引入无效删除。

## 边界

本次只修改 `git-commit` skill 及其校验器测试，不修改产品代码、应用内置 Agent 资源或其他 skill。

## 计划

本任务执行计划：[`2026-08-27-scoco-agent-docs-port.md`](../../exec-plans/completed/2026-08-27-scoco-agent-docs-port.md)。

## 验证

- `git-commit` 校验器测试和 Python 语法检查通过。
- 静态确认 skill、脚本和测试不再绑定 Easydict 或 Scoco 项目名称。
