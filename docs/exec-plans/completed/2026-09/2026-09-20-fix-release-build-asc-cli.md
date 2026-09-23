# 修复 release-build asc 参数续行并补充 CLI 文档

- 状态：completed
- 创建日期：2026-09-20
- 负责人：Unknown
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** Unknown
- **Model:** Unknown
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

## 背景

`release-build.sh` 中的 `asc xcode version view` 命令缺少续行符，导致 `--output json` 被当作独立命令。发布指南还缺少 `asc` CLI 的定位和安装检查说明，并未明确 API Key 使用 App 管理权限。

## 目标与范围

- 目标结果：修复参数传递，增加回归覆盖，并更新 `docs/releases/easydict.md`。
- 允许修改路径：`.agents/skills/release-easydict/scripts/release-build.sh`、`.agents/skills/release-easydict/tests/`、`docs/releases/easydict.md`、本计划及对应 history。
- 同任务 history：`docs/histories/2026-09/2026-09-20-fix-release-build-asc-cli.md`
- 用户限制：不执行真实发布、公证、远程 GitHub 或 App Store Connect 写入。
- 非目标：不重构发布工作流，不修改其他 `asc` 命令。
- 验收标准：`asc` 收到完整单次参数；聚焦测试通过；Shell 检查、文档检查和 `git diff --check` 通过。

## 工作计划

1. 修复 Shell 续行并增加 `asc` 参数回归测试。
2. 补充 `asc` CLI 和 App 管理权限文档。
3. 运行聚焦测试与静态检查，审查变更并记录 history。

## 风险与决策

- 使用临时 mock `asc` 验证参数和 JSON 管道，不触发真实账号、构建或远程写入。
- `asc` 文档只保留 Easydict 使用所需的命令，不复制第三方完整手册。

## 进度

- [x] 修复脚本并增加测试。
- [x] 更新文档。
- [x] 完成验证、审查和 history。

## 验证

- 已完成 Shell、Python、`asc` 自检、聚焦及全量测试；结果见对应 history。

## 完成条件

- 变更通过相关测试和静态检查。
- history 记录落地结果并归档本计划。
