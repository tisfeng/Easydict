# 简化当前模型的温度参数策略

- 状态：completed
- 创建日期：2026-10-23
- 负责人：Codex
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/pull/1371

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

## 背景

用户明确只考虑当前模型，不再维护旧版本解析或非标准代理别名兼容。

## 目标与范围

- 目标结果：Claude 请求省略温度；OpenAI 用 GPT-6 前缀直接判断，其他提供商保留温度。
- 允许修改路径：两个服务文件、现有温度测试及必要工程引用、本任务 plan/history。
- 同任务 history：`docs/histories/2026-10/2026-10-23-simplify-llm-temperature.md`
- 用户限制：不兼容旧模型与非标准别名；不 push。
- 非目标：修改模型列表、请求传输或 UI；新增或扩写测试。
- 验收标准：移除旧解析分支及过期测试，当前模型相关现有测试通过，review 通过后本地提交。

## 工作计划

1. 冻结初始工作区，简化温度逻辑并删除过期测试与工程引用。
2. 运行现有相关测试和静态检查，review 本次增量。
3. 更新 history、归档计划并创建本地提交。

## 风险与决策

- 初始 Claude 未暂存改动仅调整 helper 的位置；删除 helper 后保留其余成员原有顺序。
- 移除 Claude 能力 helper 后，请求始终省略温度，无需保留测试专用常量函数。
- OpenAI 只匹配 canonical GPT-6 前缀，不解析版本或提供商路径；其他服务的请求路径不改。
- 工作区曾有锁文件消失问题；只做必要验证并核对锁文件，不提交构建副作用。

## 进度

- [x] 实现简化并删除过期测试与引用。
- [x] 验证与 review。
- [x] 记录与归档；随本任务创建本地提交。

## 验证

- 现有 `OpenAITemperatureSupportTests` 与 `ClaudeSSEParserTests` 共 7 个测试通过。
- 测试使用 Agent 独立 DerivedData，临时传入 `EASYDICT_RELEASE_PACKAGING=YES EXCLUDED_SOURCE_FILE_NAMES=Package.resolved`；不覆盖常规发布打包验证。
- `plutil -lint`、`git diff --check` 通过；工程语义比较确认只删除过期测试引用，构建配置与资源不变。
- 锁文件与执行前内容一致；未调用提供商在线 API。
- 验证后 review：当前模型范围内无未处理 finding。

## 完成条件

- 当前模型路径验证通过，review 没有范围内未处理 finding，本地提交完成且无构建副作用。
