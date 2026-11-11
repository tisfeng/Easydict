# 修复词典网页点击被表格手势拦截

- 状态：completed
- 创建日期：2026-10-11
- 负责人：Codex
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/pull/1351

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

## 背景

真实点击在 NSTableView 内没有进入词典 iframe。移除表格单击手势或仅在命中 WKWebView 时让其退出识别，均恢复发音；恢复原代理后再次失效。

## 目标与范围

- 目标结果：词典网页收到真实点击，英美发音及例句可播放。
- 允许修改路径：查询表格、其控制器接入、Xcode 工程、本任务记录。
- 同任务 history：`docs/histories/2026-10/2026-10-11-dictionary-click-gestures.md`
- 用户限制：复用当前分支；不 push。
- 非目标：音频资源重写、播放器替换；不纳入已有 AppleDictionary.swift 调试改动。
- 验收标准：构建、现有相关测试及原生点击验证通过，完成 review。

## 工作计划

1. 添加局部表格手势过滤，保留原代理与其他区域行为。
2. 构建、现有测试、真实点击和生命周期验证。
3. 审查最终差异，记录结果并创建本地提交。

## 风险与决策

- 仅在 macOS 27 及以后安装，使用公开手势类及代理接口，不按系统私有 selector 匹配。
- 保留原代理转发，检查重建与代理生命周期。
- 不新增测试，使用现有 suite 与人工运行验证。

## 进度

- [x] 实现。
- [x] 验证与 review。
- [x] 归档与提交。

## 验证

Debug 构建、AppleDictionaryTests 的 5 个现有测试通过；新构建中英音、美音、例句与滚动后点击通过。重复布局代理稳定、临时表格释放检查通过。Review 未发现有效 finding，详情见同任务 history。

## 完成条件

构建和相关验证完成，未解决风险如实记录；review 后更新 history 并归档。
