# 第一批安全加固与可靠性改进

**Status:** completed
**Created:** 2026-08-26
**Updated:** 2026-08-26
**Owner:** Eric Pan
**Links:** 当前用户请求

## 任务契约

- 任务模式：`implementation`
- 用户目标：按已确认方案完成网络与配置安全、密码加密配置备份、历史语言重放和
  文本替换结果可信度改进，并以测试、构建和手动检查证据验证。
- 允许动作：修改产品代码、测试、Xcode 工程元数据、Info plist、String Catalog、
  执行计划和历史；运行静态检查、Xcode 构建和聚焦测试；完成后按仓库规则自动本地提交。
- 允许修改路径：`Easydict/`、`EasydictTests/`、
  `Easydict.xcodeproj/project.pbxproj`、`docs/exec-plans/`、`docs/histories/`。
- 预期交付物：统一 endpoint 与配置项安全边界、加密备份与预览合并恢复、语言感知重放、
  可区分确认程度的流式插入、完整本地化、行为测试和验证记录。
- 验收标准：远程 HTTP 和 scheme 凭据访问不可达；备份不泄露配置或凭据明文；恢复失败
  不改变原设置；历史重放不污染全局语言；插入失败不触发 provider fallback；相关测试、
  Debug/Release 构建、格式和数据文件检查通过。

## 自动提交状态

- 自动提交资格：`eligible`
- 初始暂存区：`empty`
- 初始工作树：`clean`
- 初始分支：`dev`，HEAD `ef4671ac2eae5bc77422abb2dd964000b4938528`，
  相对 `origin/dev` ahead 1 / behind 1。
- 自动提交结果：本实现、历史与已归档计划由本文件所在的一次 scoped
  local commit 记录；未 push。

## 输入来源

- 用户明确请求：实施已确认的“Easydict 第一批修改与测试计划”。
- 仓库规则：`AGENTS.md`、`docs/agents/`、`docs/architecture/overview.md`。
- 附件或引用材料：用户提供的完整实施与测试计划、Apple ATS/Logger 文档、OWASP
  密码存储与认证加密建议。
- 仅作为证据的内容：当前 checkout 的源码、既有替换测试与上一次实现记录。

## 目标

在不改变合法 HTTPS、精确 loopback HTTP、非敏感 URL Scheme 自动化、逐 chunk 写回和
现有查询记录格式的前提下，关闭已确认的网络与配置泄露边界，并让备份、语言重放和
跨应用插入具有明确、可测试的状态语义。

## 范围

- 包含范围：legacy WebView 删除、ATS 与 endpoint policy、配置项 registry、URL Scheme
  加固、密码加密备份/恢复、历史与收藏重放、文本插入 session/receipt、日志净化、
  全 locale 文案、聚焦测试和构建。
- 不包含范围：Keychain 迁移、Git 历史重写、旧导出文件删除、LAN HTTP、第三方应用
  强确认协议、真实 provider 请求、发布或 push。

## 背景

- 当前 `NSAllowsArbitraryLoads` 全局放宽 ATS，服务 endpoint 只检查 URL 是否包含 scheme
  与 host，旧 WebView 目录还包含 load-time swizzle、宽松 trust 处理和凭据字面量。
- 当前配置导出直接序列化 persistent domain；URL Scheme 可直接读写凭据、重置设置和
  向 Downloads 写文件。
- `QueryRecord` 已保存源/目标语言，但收藏重放只传查询文本。
- 文本替换的插入 API 返回 `Void`，provider 输出完成不能证明目标应用已接受或修改文本。

## 风险与缓解

- 风险：ATS 收紧破坏 Ollama 或 debug Sparkle。
  - 缓解措施：plist 只保留 local networking，并由应用层精确允许三个 loopback host。
- 风险：registry 漏掉动态服务凭据或把内容型数据带入备份。
  - 缓解措施：语义 descriptor、静态 inventory、动态 serviceType/UUID 规则和 unknown
    fail-closed 测试共同约束。
- 风险：恢复过程中 UserDefaults 只完成部分写入。
  - 缓解措施：完整 persistent-domain snapshot、单次 overlay 写入、逐项回读和失败回滚验证。
- 风险：跨应用流式写入期间焦点切换导致误写。
  - 缓解措施：请求开始前绑定目标 PID/上下文，每个 chunk 写入前复核目标。
- 风险：兼容粘贴路径无法确认第三方应用是否实际消费事件。
  - 缓解措施：保留兼容行为但标记 `dispatchedUnverified`，只显示一次中性通知。

## 里程碑

- [x] 确认任务契约、初始 Git 状态、规则和技能约束。
- [x] 完成独立安全边界调查并核对修复边界。
- [x] 实现网络、ATS、配置 registry 与 URL Scheme 安全边界。
- [x] 实现密码加密配置备份、预览和合并恢复。
- [x] 实现历史语言重放和文本插入结果模型。
- [x] 由独立测试执行者补充行为测试。
- [x] 完成静态检查、Debug/Release 构建和聚焦测试，并记录手动检查边界。
- [x] 完成独立旁路与回归复审。
- [x] 记录历史、归档计划并与实现一起纳入一次自动本地提交。

## 验证

- `xcodebuild build-for-testing -workspace Easydict.xcworkspace -scheme Easydict
  -configuration Debug -destination 'platform=macOS' -derivedDataPath
  /private/tmp/easydict-behavior-production-derived CODE_SIGNING_ALLOWED=NO`：通过，编译
  389 个 Swift 文件；SwiftLint 仅报告既有 `PolishingService.swift:11`
  `superfluous_disable_command` warning，0 serious。
- 同一 DerivedData 的 focused `test-without-building`：通过，85 个逻辑测试、114 次执行，
  0 失败、0 跳过。覆盖 endpoint/redirect、registry、backup codec/service、URL Scheme、
  replay、replacement service/stream 与 AppleScript executor；结果位于
  `/private/tmp/easydict-behavior-production-derived/Logs/Test/Test-Easydict-2026.08.26_23-26-15-+0800.xcresult`。
- endpoint、registry 与 scheme 最终安全回归：32 个逻辑测试、61 次执行通过；备份单独回归
  包含既有 `0644` 文件的原子覆盖、密文替换、`0600` 权限和无临时文件残留。
- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -configuration Release
  -destination 'platform=macOS' -derivedDataPath
  /private/tmp/easydict-behavior-production-derived CODE_SIGNING_ALLOWED=NO`：通过；仅有上述
  既有 SwiftLint warning 和未安装 `sentry-cli` 的符号上传跳过提示。
- `swiftformat Easydict EasydictTests --lint`：通过，`0/387 files require formatting`，
  10 files skipped；缓存写入 warning 不影响 lint 结果。
- `jq`：String Catalog JSON 有效；49 个本批 key 均覆盖 `en`、`es`、`ja`、`sk`、
  `zh-Hans`、`zh-Hant`。
- `plutil -lint`：两个 Info plist 与 `project.pbxproj` 通过；`git diff --check` 通过。
- Release 主应用自身的 `Info.plist` 中 ATS 仅包含
  `NSAllowsLocalNetworking=true`；主可执行文件无 legacy WebView 类、旧 scheme handler、
  全局 ATS 例外、测试 canary 或已删除凭据标记。
- 手动检查：未操作用户的 TextEdit、Safari/Chrome、WeChat、辅助功能权限或真实
  provider 凭据，因此跨应用矩阵、Apple Dictionary/MDict/普通结果 WebView、debug
  Sparkle localhost 和真实 Release canary 日志仍需在授权桌面环境中执行；非 POSIX
  导出卷的 `0600` 权限表现也需单独手工确认。自动化与静态复核已覆盖日志格式、
  AppleScript 错误脱敏与主可执行文件 canary 扫描。
- 完整测试目标未追加执行：仓库包含可能触发系统权限、OCR 样本或外部服务副作用的套件；
  本次按计划运行了与改动直接相关的全部 focused suites。

## 决策记录

- 2026-08-26：远程 endpoint 必须使用 HTTPS；HTTP 只允许 `localhost`、
  `127.0.0.1`、`::1`，不通过 DNS 解析扩大范围。
- 2026-08-26：URL Scheme 保留非敏感配置自动化；凭据拒绝，重置和导出转为应用内确认。
- 2026-08-26：备份只包含 portable settings 与服务凭据，使用密码加密；恢复预览后合并，
  保留未包含的当前设置并要求重新打开应用。
- 2026-08-26：Keychain 迁移留到第二批；第一批 registry 使用语义 descriptor，为后续迁移
  提供稳定标识。
- 2026-08-26：兼容替换继续尽力分发，但不得把无返回值的调用记录为已确认修改。
- 2026-08-26：所有 credential-bearing 请求的 redirect 只允许同源；目标跳转仍须再次满足
  endpoint policy，避免 HTTPS endpoint 或 loopback HTTP 经 30x 把凭据带到其他 origin。
- 2026-08-26：endpoint 不再允许 URL Scheme 读或写。仅校验 HTTPS 不能阻止外部调用方
  把已有 API key 导向其控制的 HTTPS host；设置 UI 与加密恢复仍通过统一策略。
- 2026-08-26：endpoint policy 拒绝 URL userinfo；受控 data/bytes transport 在创建任务前
  同时复核 initial request URL 与 original endpoint 安全且同源。
- 2026-08-26：备份先在目标目录创建权限为 `0600` 的随机临时文件，再原子 move/replace，
  避免“先以默认权限落盘、再 chmod”的短暂暴露窗口。

## 进度记录

- 2026-08-26：完成规则、技能、历史上下文和初始状态检查；启动独立只读安全边界调查。
- 2026-08-26：删除 legacy WebView translator/scheme handler，收紧 ATS、endpoint、redirect、
  URL Scheme 与敏感日志边界；完成 registry 和加密备份 UI/codec/恢复事务。
- 2026-08-26：独立生产执行者完成历史语言重放和 insertion session/receipt/confidence；
  独立测试执行者完成全部新增测试和两个重定向测试桩修复。
- 2026-08-26：旁路复审发现 redirect 可跨 origin 与残留正文日志，修复后 focused 测试、
  Debug build-for-testing、Release build 和主产物静态扫描全部通过。
- 2026-08-26：最终旁路复审继续发现并关闭 endpoint userinfo、Scheme endpoint 凭据
  外送、initial transport 绕过，以及 WebView、Claude、DeepL、音频、选择与插入日志的
  canary 路径；独立复审最终阻断项为 0。
