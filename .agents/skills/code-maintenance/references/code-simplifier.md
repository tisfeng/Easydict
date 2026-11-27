# 代码简化

<!--
https://github.com/getsentry/skills/blob/main/plugins/sentry-skills/skills/code-simplifier/SKILL.md
Based on Anthropic's code-simplifier agent:
https://github.com/anthropics/claude-plugins-official/blob/main/plugins/code-simplifier/agents/code-simplifier.md
-->

先阅读调用方、测试、配置和数据格式，找出造成理解或修改困难的重复、嵌套或间接层。没有明确收益时保留现有实现。

- 保持输出、公开 API 及其命名、序列化格式、兼容行为、错误语义和用户可见文本。
- 保留表达领域概念、隔离副作用或约束状态转换的抽象。把职责相关的逻辑放在一起。
- 遵循项目的语言和框架约定。用明确的命名和控制流表达意图，避免嵌套三元表达式或隐藏副作用的密集单行。
- 用注释解释约束和非显然的原因。改动完成后，从原调用入口验证正常结果、边界条件和副作用顺序。
