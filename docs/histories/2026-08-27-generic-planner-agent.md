# 泛化 planning 子代理配置

- 日期：2026-08-27
- 状态：completed
- 来源：Scoco `51189a4c93d99e578984e120ed5c3409de7643eb`

## 背景

当前 planner 的角色描述和规则读取方式绑定 Easydict，不利于在不同仓库 checkout 中复用；同时仍需保持当前仓库根 `AGENTS.md` 的规则路由权威性。

## 变更

- 将角色描述改为通用的只读 planning 子代理。
- 改为读取当前仓库根目录的 `AGENTS.md`（如果存在）及其任务路由要求。
- 保留证据驱动规划、禁止修改文件和 Git、禁止外部服务、禁止扩大授权以及禁止递归委派。

## 边界

本次只修改 `.codex/agents/planner.toml` 及本任务计划归档，不修改产品代码、skill 运行时资源或远程状态。

## 计划

本任务执行计划：[`2026-08-27-scoco-agent-docs-port.md`](../exec-plans/completed/2026-08-27-scoco-agent-docs-port.md)。

## 验证

- 使用 Python `tomllib` 解析 planner 配置。
- 静态确认 planner 保持只读和禁止递归委派约束。
