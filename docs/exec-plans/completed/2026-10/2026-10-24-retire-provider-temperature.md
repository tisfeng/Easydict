# 清理已废弃或固定的服务温度参数

- 状态：completed
- 创建日期：2026-10-24
- 负责人：Codex
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/pull/1371

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

## 背景

用户要求逐个检查模型服务，彻底移除已废弃或不再生效的温度参数，避免把推理模式限制误判成全面废弃。

## 目标与范围

- 目标结果：Claude、MiniMax、Gemini 不发送温度，也不展示无效滑块；其他服务保留官方仍支持的能力。
- 允许修改路径：流式服务温度能力、请求构造、Claude/MiniMax/Gemini、共享配置视图，以及本任务 plan/history。
- 同任务 history：`docs/histories/2026-10/2026-10-24-retire-provider-temperature.md`
- 用户限制：不维护旧模型兼容层，不 push；不新增或扩写测试。
- 非目标：改动模型列表、推理配置、清空用户偏好、在线余额或代理后端；不将文档结论写成成功实测。
- 验收标准：服务的请求与 UI 使用同一能力开关，其他服务参数不变；现有相关测试、构建与 review 通过，本地提交。

## 工作计划

1. 核对官方文档及所有生成模型服务的请求入口。
2. 最小化修改已废弃参数与配置 UI，运行既有测试及静态检查。
3. review 后记录检查结论、归档计划并本地提交。

## 风险与决策

- Claude 已省略请求字段，本次补齐 UI 清理；其他服务仍使用共享温度键，不删除全局存储定义。
- MiniMax M3 温度固定，Gemini 新模型废弃采样参数；Gemini 服务统一采用默认采样，不新增旧版本识别。
- OpenAI 为推理模式限制而非全面废弃，保留当前条件省略；DeepSeek 思考模式忽略但不报错，非思考模式仍支持，保持现状。
- 智谱、Groq、Ollama 与自定义服务保留温度；内置 AI/AI Tool 使用保留的智谱免费模型；豆包翻译与 CLI 服务原本不提供此请求参数。
- 先前 OpenAI 实测被 429 额度不足和配置代理 502 阻断，不能推导温度参数是否导致 400。
- 本次从干净的 `a9e038f6b265282fc7fdc283caf7d5773e24399a` 开始，保留分支，不修改工程或锁文件。

## 进度

- [x] 官方文档与请求路径核对。
- [x] 实现、测试与 review。
- [x] 记录与归档；随任务创建本地提交。

## 验证

- 独立 Agent DerivedData 的 `xcodebuild test`：4 个现有 suite、17 个测试通过，同时覆盖 Debug 构建；没有新增或扩写测试。
- 验证临时使用 `EASYDICT_RELEASE_PACKAGING=YES EXCLUDED_SOURCE_FILE_NAMES=Package.resolved`，没有修改工程配置；不覆盖常规发布打包。
- `git diff --check` 通过；移除的 `temperatureMaxValue` 无残留调用。
- review 六个源码/UI 文件及请求、UI、继承路径：无范围内 finding；三个服务使用相同能力属性，其他提供商沿用默认行为，无需模型版本表。
- review 前后源码摘要一致，工程文件与锁文件逐字节保持初始内容。
- 本次未调用在线 API；文档与静态代码证据不等同于真实接口测试或 GUI 操作验证。

## 完成条件

- 已废弃温度不再进入请求及配置 UI；相关验证和 review 通过，无构建副作用，本地提交且不 push。
