# 修复 Apple Dictionary 图标字体资源

- 状态：completed
- 创建日期：2026-10-11
- 负责人：Codex
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/pull/1351

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

## 背景

朗文词典的喇叭图标使用本地字体，内存 HTML 未嵌入字体，导致图标显示方框。PR 的绝对音频路径修复未覆盖此场景。

## 目标与范围

- 目标结果：词典内合法字体嵌入 data URL，恢复图标。
- 允许修改路径：AppleDictionary.swift、本计划与同任务 history。
- 同任务 history：`docs/histories/2026-10/2026-10-11-apple-dictionary-font-resources.md`
- 用户限制：复用当前分支；未授权新增测试或 push。
- 非目标：重写词典渲染器或放宽 WebView 文件访问权限。
- 验收标准：真实朗文词条字体可加载，音频嵌入保留，边界检查保留，必要构建与现有测试通过。

## 工作计划

1. 在现有资源嵌入链路支持内联 CSS 的字体 URL。
2. 验证真实词条、构建及现有测试，进行只读 review。
3. 更新 history，归档计划，创建本地提交。

## 风险与决策

- 复用现有路径规范化、符号链接、文件类型与大小检查，避免引入宽泛文件读取。
- 字体只处理 @font-face 内的 URL；保留网络、data 和未知格式引用。
- 构建使用 agent 独立 DerivedData；不与 Xcode Run 并发启动测试宿主。

## 进度

- [x] 实现、构建、现有测试、真实词条 WebKit 字体验证与 review。
- [x] 记录结果并归档；本地提交由本任务交付步骤创建。

## 验证

- 构建成功；AppleDictionaryTests 4 个测试通过；SwiftLint 0 violations；语法与 diff 检查通过。
- 真实词条嵌入 2 份字体、39 处音频引用；WebKit 字体从 NetworkError 变为 loaded。
- Review 未发现有效 finding。
- 调试版已启动，界面自动化读取超时；应用内实际点击播放留待人工复测，未声明验证通过。

## 完成条件

- 范围内实现通过适用验证和 review，记录准确结果，提交前归档计划。
