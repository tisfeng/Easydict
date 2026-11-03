# 删除全部服务温度配置

- 状态：completed
- 创建日期：2026-10-24
- 负责人：Unknown
- 关联 Issue/PR：None

## 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

## 背景

用户要求所有服务统一使用默认温度，不再配置或发送 temperature。

## 目标与范围

- 目标结果：删除请求参数、温度状态与能力判断、滑块和无用本地化。
- 允许修改路径：服务、配置键与视图、温度测试、工程引用、String Catalog、本任务记录。
- 同任务 history：`docs/histories/2026-10/2026-10-24-remove-all-temperature.md`
- 用户限制：dev 本地提交，不 push。
- 非目标：修改依赖 SDK 或用户已保存的偏好数据。
- 验收标准：应用不读取或发送温度，没有温度 UI 或能力开关；测试与 review 完成。

## 工作计划

1. 删除温度请求字段、公共属性和 UI，清理相关文件及工程引用。
2. 检查 SDK 缺省编码及历史配置迁移，运行相关现有测试。
3. review、记录结果、归档并提交。

## 风险与决策

- 删除温度配置后，输出使用服务默认值；旧偏好留在磁盘但不再读取。
- 用户进一步要求删除 Codex 旧温度键名兼容；只剩温度键的历史实例不再据此触发迁移。
- 删除仅测试已移除能力的两个测试；不新增测试。

## 进度

- [x] 后续：删除 Codex 旧温度迁移识别，9 个迁移测试通过，review 无有效 finding，纳入 dev 本地提交。

- [x] 删除与验证完成，review 无有效 finding，纳入 dev 本地提交。

## 验证

- 后续迁移清理：相同独立 DerivedData 及临时构建参数下，CodexConfigurationMigrationTests 9 个现有测试通过；源码搜索无 temperature，review 无有效 finding。

- 独立 Agent DerivedData 下 xcodebuild test：ClaudeSSEParserTests、OpenAIStreamTaskControlTests、QueryModelCancellationTests、CodexConfigurationMigrationTests，24 个现有测试通过，Debug 编译成功。
- 临时使用 EASYDICT_RELEASE_PACKAGING=YES EXCLUDED_SOURCE_FILE_NAMES=Package.resolved；未改工程配置，不覆盖发布打包。
- git diff --check、JSON 和 pbxproj 检查通过；review 及源码摘要复验通过。

## 完成条件

- 现有相关测试通过，review 无未解决 finding，dev 本地提交且不 push。
