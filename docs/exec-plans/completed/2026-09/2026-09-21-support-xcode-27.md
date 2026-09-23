# 支持 Xcode 27 的 CodeQL 构建

- 状态：completed
- 创建日期：2026-09-21
- 负责人：Codex
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/pull/1274

## 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-5
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

## 背景

PR #1274 引入了 macOS 27 Icon Composer 图标。原 CodeQL Swift job 使用
`macos-latest`，实际运行在 macOS 26.6.2 / Xcode 26.6，`actool` 无法打开
`Easydict-27.icon`，导致构建检查失败。

## 目标与范围

- 目标结果：让 Swift CodeQL 构建在 GitHub Actions 的 `xcode-27` runner 上运行，并在日志中验证 macOS/Xcode 主版本。
- 允许修改路径：`.github/workflows/codeql.yml`、本计划及同任务 history。
- 同任务 history：`docs/histories/2026-09/2026-09-21-support-xcode-27.md`
- 用户限制：本地修改和提交；不自动 push、不修改 GitHub 评论或检查状态。
- 非目标：不修改应用源码、图标资源、依赖版本或其他 workflow；不切换到 `xcode-27-xlarge`。
- 验收标准：Swift CodeQL job 使用 `xcode-27`；版本检查拒绝非 macOS 27/Xcode 27 环境；YAML、Shell 静态检查和 review 通过。

## 工作计划

1. 修改 CodeQL Swift job 的 runner 和工具链版本校验。
2. 运行 YAML、Shell、差异和仓库相关静态检查。
3. 使用 review 检查 workflow 变更，更新 history 并归档本计划。
4. 创建本地提交，不执行 push。

## 风险与决策

- `xcode-27` 目前是 GitHub Actions Public Preview，可能有排队或工具链稳定性风险；先使用标准 runner，不引入更高成本的 `xcode-27-xlarge`。
- 缓存 key 已包含 Xcode 版本，切换后会自然隔离 Xcode 26 与 Xcode 27 的 SwiftPM 缓存。
- 版本校验只约束主版本，不依赖具体 patch/build 号，以便兼容后续 Xcode 27 image 更新。

## 进度

- [x] 修改 workflow。
- [x] 完成静态验证和 review。
- [x] 更新 history、归档计划并创建本地提交。

## 验证

- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/codeql.yml")'`：通过。
- 提取 `Show build environment` 的 Shell 脚本运行 `bash -n`：通过。
- 断言 workflow 使用 `xcode-27` 并包含 macOS/Xcode 27 主版本校验：通过。
- `git diff --check`：通过。
- review：仅修改 runner label 和工具链版本门禁，未发现 finding。
- 未运行 GitHub Actions 在线检查；需要 push 后才会触发新的远程 CI。

## 完成条件

- workflow 仅在预期路径发生范围内变更。
- 静态检查和 review 通过，history 已记录限制和未运行项。
- 计划归档到 `docs/exec-plans/completed/2026-09/`。
- 本地提交已创建，未执行 push。
