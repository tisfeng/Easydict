# Copilot 模型选择使用本地目录

- 状态：completed
- 创建日期：2026-09-27
- 负责人：Codex
- 关联 Issue/PR：None

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

## 背景

查询窗口每次选择模型都会启动 CLI，设置页多个生命周期入口和显式推理翻译也会查询目录，导致等待。现有目录仅存于内存。

## 目标与范围

- 目标结果：菜单直接使用持久化目录，仅设置页手动刷新触发 CLI 目录查询。
- 允许修改路径：GitHubCopilot 服务、StreamService 模型接口、EZResultView 模型菜单、Copilot 设置页、AppPathManager 缓存路径、String Catalog、工程注册及对应文档。
- 同任务 history：`docs/histories/2026-09/2026-09-27-copilot-local-model-cache.md`
- 用户限制：模型动态来自 CLI；只手动更新；无需未发布代码的旧格式迁移。
- 非目标：PR、rebase、推送、自动更新目录、翻译协议重构。
- 验收标准：重启恢复目录；菜单不启动 CLI；刷新成功原子保存并通知窗口，失败保留旧目录；翻译仅用本地能力校验推理，默认模型仍读取 CLI 本地配置。

## 工作计划

1. 添加目录序列化、缓存路径与原子存储，启动恢复快照。
2. 删除菜单等待与设置自动刷新，保留手动刷新、空状态提示和更新时间。
3. 移除翻译前目录请求，按实际模型和本地能力决定推理参数。
4. 执行格式、资源、工程与构建验证，审查调用链及失败路径。
5. 更新 history、归档计划并创建本地提交。

## 风险与决策

- 目录可能过期；保留 CLI 错误并提示设置手动更新，不自动重试翻译。
- 默认模型可能在 CLI 外部更改；在 Runner 读取当前配置后再用缓存能力校验。
- 磁盘保存失败不得替换当前快照；无缓存时仍提供默认与当前已选模型。
- 基线 `a3ff883c6319d4ffe4fd58e63ea65c404e0b1998`；首次写入前工作树及索引为空。

## 进度

- [x] 本地缓存、菜单与设置交互
- [x] 翻译能力校验、文档与本地化
- [x] 验证与 review；按交付流程创建本地提交

## 验证

- Debug 构建通过，使用 checkout 专属 Agent DerivedData；仅 AppIntents metadata extraction 提示。
- SwiftFormat lint、固定版本 SwiftLint、工程 plutil、String Catalog JSON 与六语言覆盖、diff 检查通过。
- 代码路径核对：目录请求仅能由设置页刷新/重试触发；菜单同步显示；翻译使用实际模型与缓存能力。
- review 无有效 finding；缓存失败保留、缺失目录和旧菜单服务身份校验路径均已检查。
- 未新增测试；现有 Copilot 专项测试缺失，Xcode Run 正在占用同 bundle ID，不运行 app-hosted tests。UI 点击、重启恢复和失败场景尚未运行时验证。

## 完成条件

- 必要验证及 review 完成，无未处理有效 finding。
- history 完整，计划归档，提交范围与任务一致。
