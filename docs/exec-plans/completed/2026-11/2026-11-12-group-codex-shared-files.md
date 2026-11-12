# 归位 Codex 共用源码和测试

- 状态：completed
- 创建日期：2026-11-12
- 负责人：Codex
- 关联 Issue/PR：无

## 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-6
- **Environment:** macOS 27.2 / Xcode 27.2 (27B52)

## 背景

两种接入方式和 App Server 已分组，服务入口、配置与 exec 解析文件仍放在 Codex 根目录。

## 目标与范围

- 目标结果：生产与测试的 Codex 根目录只包含职责子目录。
- 允许修改路径：Codex 源码、对应测试目录、Xcode 工程及任务记录。
- 同任务 history：`docs/histories/2026-11/2026-11-12-group-codex-shared-files.md`
- 用户限制：按已确认方案执行。
- 非目标：改动请求、配置存储和界面行为。
- 验收标准：同步工程引用，现有定向测试和真实本机 CLI 验证通过。

## 工作计划

1. 迁移根目录文件并提取 CodexTokenUsage。
2. 核对 target membership，运行测试并审查差异。

## 风险与决策

- 保留 Swift 标识和现有文件引用 ID。新文件仅加入应用 target。

## 进度

- [x] 完成归位和验证。

## 验证

- Debug 构建与 160 项定向测试通过。
- 真实本机 CLI 公式 OCR 和流式翻译 2 项通过。
- 核对 Codex 两个根目录、25 个生产文件、14 个测试文件及各自的 Sources 引用。
- review 对照基线复核目录和代码迁移，未发现需修复的问题。

## 完成条件

核对目录结构、工程引用和验证结果，归档计划并本地提交。
