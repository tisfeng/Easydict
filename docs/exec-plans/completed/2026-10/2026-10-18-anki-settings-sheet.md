# Anki Connect 二级设置窗口

- 状态：completed
- 创建日期：2026-10-18
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

## 背景

折叠组方案已撤回，用户采用参照 Scoco SheetChevronRow 的二级窗口方案，并要求实际检查布局与交互。

## 目标与范围

- 目标结果：高级页单行入口，打开分组、可滚动的 Anki 设置 Sheet。
- 允许修改路径：Anki 设置视图、箭头入口组件、String Catalog、工程引用及任务文档。
- 同任务 history：`docs/histories/2026-10/2026-10-18-anki-settings-sheet.md`
- 用户限制：完成后实际检查 Sheet 的布局与交互。
- 非目标：变更 Anki 协议、模板处理和网络业务逻辑。
- 验收标准：入口状态同步；关闭功能仍能配置；映射与预览可访问；完成按钮关闭；配置保留；无裁切与重叠。

## 工作计划

1. 提取 Anki 设置内容并实现原生 Button 箭头入口与 Sheet。
2. 补齐本地化与工程引用，构建验证。
3. 启动新构建，实际检查布局、编辑、开关、滚动、关闭和重新打开。
4. 使用 review 技能审查并修复问题，完成 history、归档计划和本地提交。

## 风险与决策

- Sheet 使用固定初始尺寸和 Form 自带滚动，完成按钮位于滚动内容之外。
- 使用原有 Defaults 即时保存；不新增保存/取消语义。
- 参照 Scoco 交互，使用 Button 代替手势以支持键盘。

## 进度

- [x] 初步实现。
- [x] 构建与实际检查。
- [x] 审查与交付准备完成。

## 验证

- Debug 构建、JSON/工程静态检查及 diff 检查通过。
- macOS 27.0.1、中文深色界面实际验证入口、开关状态、牌组即时保存、关闭功能仍可编辑、映射增删、模板换行、hello 预览、长内容滚动、固定完成按钮及 Esc/Return 关闭。
- 测试配置已恢复；review 无有效 finding，源码快照复验一致。
- 运行验证范围与未执行项目详见同任务 history。

## 完成条件

- 必要构建、布局与交互检查通过，review 无有效 finding；history 完整，计划归档。
