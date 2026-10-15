# 查询窗口选择 Copilot 模型

- 状态：completed
- 创建日期：2026-09-27
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

## 背景

查询窗口使用模型 ID 作为按钮标题，并读取静态模型列表。Copilot 的动态目录只在设置页保存，CLI 默认选择为空字符串，导致查询窗口没有可用的模型入口。

## 目标与范围

- 目标结果：查询窗口可选择 CLI 动态模型，默认选择可见，两处共享目录与推理校验。
- 允许修改路径：Copilot 服务与设置、StreamService 模型选择接口、EZResultView 菜单、通知、本地化、工程及本任务文档。
- 同任务 history：`docs/histories/2026-09/2026-09-27-copilot-query-model-selection.md`
- 用户限制：不增加旧配置兼容逻辑；未授权新增测试。
- 非目标：修改 CLI 翻译协议或其他服务的模型来源、push。
- 验收标准：无需打开设置即可选模型；默认与 Auto 分离；切换先校验推理后触发既有查询；目录刷新不触发翻译；失败可重试。

## 工作计划

1. 提取共享目录状态与模型选择动作。
2. 为查询窗口接入显示名称、异步加载及 ID 选择。
3. 更新设置页复用共享状态，完成静态检查与构建。
4. 使用 review 技能审查、记录验证限制、归档并本地提交。

## 风险与决策

- 初始 HEAD 为 `c0a6ebd2a466b7c9209410c6aede5c7857c9337b`；工作树与索引均干净。
- 目录只缓存于内存，合并并行查询；界面关闭不取消其他消费者共享的有界目录请求。
- 原生菜单显示名称与保存 ID 分离；异步回调必须核对原窗口、服务与请求身份。
- 目录更新只刷新模型按钮，不经过自动查询配置变更。
- 模型菜单用独立展示接口读取动态目录，避免把 UI 缓存写入基类持久化 supportedModels；其他服务继续返回原 validModels。
- 选择动作携带原服务及模型 ID，服务切换后忽略旧菜单事件。
- 当前 Xcode Run 调试进程仍在运行，不能同时启动同 bundle ID 的 app-hosted test。

## 进度

- [x] 检查调用链及原始 Git 状态。
- [x] 实现共享目录和两处模型选择。
- [x] 验证及 review。
- [x] history、归档及本地提交。

## 验证

- Debug `xcodebuild build`：成功，使用 checkout 独立 Agent DerivedData；唯一警告为无 AppIntents 依赖的 metadata extraction 提示。
- SwiftFormat lint、项目固定版本 SwiftLint、`git diff --check` 和工程 `plutil -lint`：通过。
- 本次界面复用的五个字符串 key 均具有六种现有语言翻译；未修改 String Catalog。
- 核对生成的 Objective-C 接口，模型标题、可选 ID、异步加载和选择方法均正确导出。
- review：冻结工作树源码快照，检查设置与菜单入口、单次模型通知、共享查询、失败重试、窗口/服务失效保护及原有静态服务路径，无剩余 finding。复验源码摘要一致。
- 未新增或扩写测试。用户仍通过 Xcode Run 使用同 bundle ID 的调试宿主，未运行 app-hosted test；未进行新构建的 UI 点击验证。

## 完成条件

- 完成范围内实现、风险匹配验证与审查，记录未验证项，本地提交且不 push。
