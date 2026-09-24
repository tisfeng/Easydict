# 缩小 SwiftLint 扫描范围

- 状态：completed
- 创建日期：2026-09-24
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

## 背景

根目录 `.swiftlint.yml` 用 `excluded` 排除 `.tmp`、`.build` 等目录，但本地 `.tmp` 已达 24 GB。
使用 Xcode 构建产物中的 SwiftLint 0.62.2，旧配置执行 `lint --no-cache` 超过 45 秒仍未完成。

## 目标与范围

- 目标结果：仅遍历项目 Swift 源码，并保留当前 408 个受 lint 管理的文件。
- 允许修改路径：`.swiftlint.yml`、本计划及同任务 history。
- 同任务 history：`docs/histories/2026-09/2026-09-24-swiftlint-scope.md`
- 用户限制：保留 `.tmp`，不修改 `project.pbxproj`。
- 非目标：清理 `.tmp`、修改 Swift 源码或 Xcode 构建阶段。
- 验收标准：SwiftLint 能快速完成，扫描文件覆盖当前受管源码且不遍历 `.tmp`。

## 工作计划

1. 核对现有配置、Xcode 调用和 Swift 文件分布，测量旧配置。
2. 将扫描入口限制为项目源码路径，验证 SwiftLint 结果与耗时。
3. 记录 history、归档计划，并按仓库规则交付本地提交。

## 风险与决策

- `BuildTools/.build` 含下载依赖，因此只列出 `BuildTools` 当前两个 Swift 源文件。
- SwiftLint 0.62.2 中，单独保留 `excluded: .tmp` 或其他顶层排除规则均超过 8 秒未完成；
  因此移除顶层路径排除，通过 `included` 限定扫描入口。
- 将来在允许目录中引入生成的 Swift 文件时，需要重新评估配置；当前受检文件集合不变。
- 将来新增顶层源码目录或 `BuildTools` 文件时，需要同步维护 `included` 列表。

## 进度

- [x] 核对配置、构建阶段和源码分布，测量旧配置。
- [x] 修改配置并验证。
- [x] 记录 history 并归档计划。

## 验证

- SwiftLint 0.62.2：旧配置 `lint --no-cache` 运行 45 秒后超时。
- SwiftLint 0.62.2：只加 `included` 并保留旧的顶层 `excluded`，60 秒超时。
- SwiftLint 0.62.2：隔离试验中，不加顶层 `excluded` 为 1.28 秒、408 文件、0 违规；
  单独加入 `.tmp` 或其他试验的顶层排除规则，均超过 8 秒。
- 最终配置 `lint --no-cache`：1.21 秒、408 文件、0 违规。
- `git diff --check`：通过；未运行完整 Xcode 构建，配置由构建使用的同一 SwiftLint 可执行文件验证。

## 完成条件

- 新配置验证通过，`git diff --check` 通过，history 已记录并将计划归档。
