# 移植 Scoco 取消注册、测试实例规则和 OCR 调度修复

- 状态：active
- 创建日期：2026-10-23
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.1 (27A9275)`

## 背景

用户确认候选 F1、F2、F3，要求完成语义移植、验证和 review，分别本地提交。
Easydict 基线为本地 dev `a2ed12e619113bf6c20cd423496a6f513b90528d`；
Scoco 开发基线为 dev `03c6c63333df859f408e0422e0dfeb6aed5ac568`。

## 目标与范围

- 目标结果：修复 QueryModel 取消注册竞争及重入；按共享资源冲突判断测试实例隔离；
  适配二维码 Vision 阻塞工作 QoS 与取消边界。
- 允许修改路径：`Easydict/Swift/Model/QueryModel.swift`、`EasydictTests/Model/`、
  `Easydict.xcodeproj/project.pbxproj`、`docs/agents/build-and-test.md`、
  `Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine.swift` 及本任务 plan/history。
- 同任务 history：`docs/histories/2026-10/2026-10-23-port-scoco-query-and-ocr-fixes.md`
- 用户限制：仅本地提交，三组分别交付；不 push、不自动合并 dev，不影响用户主 checkout。
  F1 明确包含相关回归测试；F3 仅运行现有测试，不新增测试。
- 非目标：Scoco 源码写入、品牌/发布设施、全模型 actor 化、预热 QoS 猜测性调整、GUI 应用替换。
- 验收标准：F1 完整应用普通配置下通过取消注册与流任务控制测试，隔离取消 API 补做线程检测；
  F2 规则语义及链接检查；
  F3 现有 OCR 二维码 suite 通过；生产代码 review 无未解决有效 finding；各自本地提交。

## 工作计划

1. F1：移植 `7f219bee2b088c5affef07eddd76a3b00e11b6ea` 代码及取消注册回归测试，验证、审查、提交。
2. F2：适配同一来源及 `03c6c63333df859f408e0422e0dfeb6aed5ac568` 的测试宿主规则，静态验证、审查、提交。
3. F3：适配 `bd01b8dc5617415d40d8fc2a2ca3d49761645b65` 的 QR QoS 与取消处理；
   核对 `276fa5d1efa211da75763025fa3190ee2f8522a9` 重构及 `a006be94cad18714e80210c75f269cab62c6ceca` 替代方案，验证、审查、提交。
4. 完成 history，归档计划，核对分支、工作树与三个本地提交。

## 风险与决策

- 取消回调及被替换闭包捕获的对象可能重入；注册表加锁，回调执行与旧闭包释放都置于锁外。
  锁只保护取消注册，不声明 QueryModel 其他属性线程安全。
- stopAllService 原子取走当前快照，之后注册的请求保持有效；同步 ObjC/Swift API 保持不变。
- 测试使用按 checkout 派生的独立 DerivedData，不改 bundle ID，不退出用户实例。
- OCR 保留现有 payload 规范化、去重和错误降级；取消不能作为 QR 成功结果返回。
- Easydict 只有一个 QR 入口，不复制 Scoco 多调用者的模块拆分。
  fork 提高预热 QoS 的因果假说未获可靠 macOS 复现支持，保留现有预热策略。
- 构建/测试及调度代码审查不能证明所有 Thread Performance Checker 警告消失。
- 完整宿主的 TSAN 首次运行在测试连接前退出：Ollama 初始化任务读取 `QueryService.uuid`，
  与 `QueryServiceFactory.service(withTypeId:)` 在初始化后赋值竞争；相关文件均未修改。
  不扩展为服务生命周期修复。改用完整应用普通配置执行回归，并原样抽取取消 API 和同一 suite
  在临时独立包运行 TSAN；后者不能替代完整应用的全局 TSAN 证明。

## 进度

- [x] 冻结基线与来源，复用干净的独立 worktree 并创建任务分支。
- [x] F1 实现、验证、review 和本地提交。
- [x] F2 实现、验证、review 和本地提交。
- [ ] F3 实现、验证、review 和本地提交。
- [ ] 归档计划并完成交付回执。

## 验证

- F1：完整应用 Debug `xcodebuild test -enableThreadSanitizer NO`，精确选择
  `QueryModelCancellationTests` 与 `OpenAIStreamTaskControlTests`，10/10 通过。
- F1 补充：临时独立 Swift 包原样抽取生产取消 API、锁/字典及移植 suite，
  `swift test --sanitize thread` 7/7 通过（含 2 个析构参数场景），无 TSAN 报告。
  不包含完整模型初始化，不声称全宿主 TSAN 通过。
- F1：SwiftFormat 无修改，SwiftLint 430 文件零 violation，工程 `plutil -lint` 和
  `git diff --check` 通过；锁顺序、回调/捕获释放、服务调用者、测试断言和工程引用 review 无有效 finding。
- F2：Markdown 相对链接、`git diff --check` 和规则语义检查通过；
  文档 review 无有效 finding。保留独立 DerivedData、bundle ID 不覆盖、用户多实例授权例外、
  进程查询与只清理本任务实例等边界；未把共享资源存在冲突时允许并行写入作为承诺。
- F3：待验证并记录。

## 完成条件

- 三组明确范围均完成必要验证和适用 review，无未解决有效 finding。
- history 记录来源、适配决定、验证证据及限制；三个本地提交完成消息校验。
- 工作树干净，主 checkout 与 Scoco 保持原状态，不 push，不自动集成 dev。
