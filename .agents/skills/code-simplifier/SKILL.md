---
name: code-simplifier
description: 在保持功能不变的前提下简化代码，提高可读性、一致性与可维护性。适用于清理、重构或检查近期修改；除非另有说明，只关注近期改动。
---

<!--
https://github.com/getsentry/skills/blob/main/plugins/sentry-skills/skills/code-simplifier/SKILL.md
-->

<!--
Based on Anthropic's code-simplifier agent:
https://github.com/anthropics/claude-plugins-official/blob/main/plugins/code-simplifier/agents/code-simplifier.md
-->

# 代码简化

保持功能不变，简化代码并提高可读性。优先处理真实的重复、嵌套和间接层，不为减少行数牺牲
清晰度或有意义的抽象。

## 范围与授权

- 默认只检查近期修改或当前会话接触过的代码；扩大范围需要用户授权。
- 检查或只读 review 只给建议。实际修改、验证和交付遵循当前任务及仓库规则，不因调用本 Skill
  自动获得写入、高成本验证或外部操作授权。

## 简化要求

- 先理解调用方、测试、配置和数据格式；保持功能、输出、公开 API、命名、兼容性、序列化、
  错误语义和用户可见文本不变。
- 保留必要的错误处理、边界行为、状态转换，以及隔离副作用和表达领域概念的抽象。
- 遵循目标项目、语言、框架和运行时的现有约定，不把某个平台的规则套用到其他项目。
- 合并重复逻辑，减少无用嵌套；使用明确命名和控制流，避免嵌套三元或隐藏副作用的密集单行。
- 职责相关的逻辑放在一起，不强行合并无关职责。注释解释意图、约束和非显然原因，不复述代码。

## 工作方式

识别近期改动及必要上下文，选择保持行为不变的最小改法。在已有授权内应用修改并执行相称验证，
报告重要变化与未验证部分。没有明确收益时保留现有实现。

## 语言和平台专项规则

只加载目标代码对应的 reference：

- Electron、TypeScript、React、IPC、preload 或 renderer：
  [Electron/TypeScript 专项规则](references/electron-typescript.md)。
- Swift、SwiftUI 或 Xcode：[Swift/Xcode 专项规则](references/swift-xcode.md)。
