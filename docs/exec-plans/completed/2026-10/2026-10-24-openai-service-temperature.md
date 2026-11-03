# OpenAI 按服务省略温度并迁移到 dev

- 状态：completed
- 创建日期：2026-10-24
- 负责人：Unknown
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/pull/1371

## 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

## 背景

PR 已 squash 合并，旧 PR 分支还有本地温度清理提交；OpenAI 仍存在用户要求删除的模型前缀判断。

## 目标与范围

- 目标结果：OpenAI 按服务省略温度并隐藏滑块，删除静态能力函数。
- 允许修改路径：OpenAI 服务、已有温度测试、本任务 plan/history。
- 同任务 history：`docs/histories/2026-10/2026-10-24-openai-service-temperature.md`
- 用户限制：最终停留 dev，不 push。
- 非目标：移除其他仍支持温度服务的参数。
- 验收标准：无静态函数及模型前缀判断，现有测试通过，review 完成，本地提交。

## 工作计划

1. 核对远程合并状态，快进 dev，迁移仅有的未合入提交。
2. 改为服务能力判断，同步已有测试。
3. 运行必要测试并审查，记录结果、本地提交。

## 风险与决策

- PR 使用 squash 合并，只 cherry-pick 本地提交 a2944d73，避免重复 PR 历史。
- OpenAIService 的子类共享实现，按 serviceType 区分 OpenAI；保留其他服务能力及已有禁用覆盖。

## 进度

- [x] 已切换 dev，快进至远程合并提交 3843ffdd4，迁移 a2944d73 为 8b60f5fc2。
- [x] 实现完成，17 个现有测试通过，review 无有效 finding；纳入本地提交。

## 验证

- 独立 Agent DerivedData 下运行 OpenAITemperatureSupportTests、ClaudeSSEParserTests、OpenAIStreamTaskControlTests、QueryModelCancellationTests：17 个测试全部通过。
- 临时构建参数 EASYDICT_RELEASE_PACKAGING=YES EXCLUDED_SOURCE_FILE_NAMES=Package.resolved；未修改工程配置，未验证发布打包或在线 API。
- git diff --check 通过，语义 review 无有效 finding，审查后源码摘要一致。

## 完成条件

- 必要验证、review 通过；记录 history，归档 plan 并本地提交，不 push。
