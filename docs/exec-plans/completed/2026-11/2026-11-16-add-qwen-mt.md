# 增加 Qwen-MT 翻译服务

- 状态：completed
- 创建日期：2026-11-16
- 负责人：nu11b1ade
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/issues/1114、
  https://github.com/tisfeng/Easydict/pull/1406

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B52)`

## 背景

Qwen-MT 要求单条 user 消息及独立的 `translation_options`，现有自定义 OpenAI
服务的聊天提示词无法直接满足其契约。用户希望向上游提交支持，并先使用 fork 构建。
首次写入前工作树干净，基线为 `30b53c9b7bb112f18aec9c5ce0ddfe808ee1cc66`。

## 目标与范围

- 目标结果：在服务列表配置和使用 Qwen-MT，提交独立 PR，并准备个人可安装构建。
- 允许修改路径：Qwen-MT 源码和测试、服务注册及类型、图标、本地化、Xcode 工程、
  英文和中文服务文档、本任务 plan/history；为保留专用翻译响应，对共享结果处理增加
  默认关闭的原文保留能力。
- 同任务 history：`docs/histories/2026-11/2026-11-16-add-qwen-mt.md`
- 用户限制：使用已有 fork `nu11b1ade/Easydict`；PR 目标为 `tisfeng/Easydict:dev`。
- 非目标：通用聊天功能、术语库编辑器及上游发布流程变更。
- 验收标准：专用请求、模型与语言映射正确；设置可见；构建和不依赖密钥的测试通过；
  用户填写本机 Key 后通过真实服务验证；PR 与个人安装包可追溯到相同实现。

## 工作计划

1. 核实官方接口、现有服务架构及 Issue。
2. 实现服务、注册、语言映射、设置及资源。
3. 添加专属测试及中英文配置说明。
4. 运行格式、静态检查和构建测试，实测设置界面并截图。
5. 使用仓库 review 技能检查最终差异，处理有效问题。
6. 记录 history、归档计划、提交 PR，准备并安装个人构建。

## 风险与决策

- 使用官方 OpenAI 兼容接口，发送原文及语言选项，不发送 system 消息。
- Flash/Lite 使用增量流式输出；Plus 使用完整响应，避免把累计流重复拼接。
- 复用通用配置和结果处理；Qwen-MT 跳过聊天包装清理，保留接口返回的引号与标签，
  其他服务沿用原行为。
- 用户已在执行期间安装 Xcode 27.2，改为本机构建、测试和界面验证。
- 不提交任何 API Key；集成测试读取本机配置。缺少凭据的场景记录为未验证。
- 个人 Release 构建沿用官方 bundle ID；切回官方版本时保留设置。

## 进度

- [x] 核实接口、架构、fork 和上游 Issue。
- [x] 实现服务和资源。
- [x] 完成专属测试、中英文文档和 Release 构建。
- [x] 使用本机凭据通过真实 API 测试。
- [x] 实测设置与三种模型的翻译界面，完成最终代码 review。
- [x] 提交上游正式 PR，归档计划并准备交付回执。
- [x] 修正自动审查发现的聊天清理问题，补测真实响应中的引号和标签保留。

## 验证

- `git status --short --branch`：初始工作树干净。
- 初始 `xcodebuild -version`：本机仅有 Command Line Tools。
- 用户安装后 `xcodebuild -version`：Xcode 27.2 (27B52)，后续改为本机验证。
- 新增服务和测试已通过 SwiftFormat、Swift 语法解析、工程文件 lint、JSON/XML 解析和
  `git diff --check`。
- Release 构建及 `Default` 计划下的 `QwenMTServiceTests` 通过：4 项测试，包含
  三个模型的参数化传输策略检查。
- 本机 Release 测试使用 ad hoc 签名、显式 Release 测试宿主及空的签名 entitlement
  覆盖，不修改工程中的官方签名配置。
- 上游 `MDictReaderTests.swift` 引用了只在 Debug 编译的 `MDictReader.zlibCompress`，
  因此本次定向 Release 测试命令使用
  `EXCLUDED_SOURCE_FILE_NAMES=MDictReaderTests.swift`；该文件与本次目标 suite 无关，
  仓库测试及工程配置未作相应修改。
- 本次 Release 应用已安装到本机 Applications，版本 `2.27.0 (70)`、
  bundle ID `com.izual.Easydict`；源产物及安装副本均通过
  `codesign --verify --deep --strict`。
- `LocalEnvironment` 计划下的真实请求测试通过：Flash、Plus、Lite 英文转简体中文，
  以及 Flash 英文转繁体中文；对返回译文中的“世界”和“变/變”做断言。
- PR 自动审查指出共享聊天清理会移除合法引号和开头的 `<think>` 内容，已增加
  Qwen-MT 专用的响应保留能力。补测 Lite、Plus 的带引号和 `<think>` 输入，
  对真实返回内容逐块及最终展示结果做等值断言；4 个回归用例通过，
  加上原有 4 个翻译用例，共 8 个真实接口用例通过。
- 设置界面的“验证”显示成功；通过正常输入入口翻译固定句子
  `The world is changing.`，分别切换 Flash、Plus、Lite，均显示正确译文。
  已保存设置和三种模型的脱敏截图，截图留在仓库外。
- 最终安装版通过 URL scheme 输入带引号的同一句子，Lite 译文保留引号；
  已保存回归截图并恢复 Flash 模型。
- 主窗口默认隐藏导致自动化连接受阻；临时显示窗口完成实测后，已恢复原始偏好，
  并正常启动安装副本。当前只运行一个安装版实例，所选模型恢复为 Flash。
- 最终 review 覆盖服务注册、配置、请求编码、语言校验、流与完整响应、错误处理、
  取消控制、资源及文档；响应保留修正已复核，未发现已证实的遗留缺陷。
  未单独执行 UI 取消操作。
- 正式 PR #1406 已从 fork 任务分支提交至上游 `dev`；创建后回读核对
  repository、分支、head、标题和正文通过。截图由交付流程从仓库外补传。
- 官方接口参考：<https://help.aliyun.com/zh/model-studio/machine-translation>、
  <https://www.alibabacloud.com/help/en/model-studio/qwen-mt-api>。

## 完成条件

- 功能差异已验证并审查，已知验证限制在 history/PR 明确说明。
- PR 已提交至上游 dev，个人构建可供使用。
