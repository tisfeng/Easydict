## 2026-08-26 | 任务：第一批安全加固与可靠性改进

**Links:** `docs/exec-plans/completed/2026-08-26-first-batch-hardening-and-reliability.md`

### 用户请求

完成网络与配置安全、密码加密配置备份、历史与收藏语言重放、文本替换结果可信度四组
改进；同步六个 locale，并以独立测试执行、Release 构建和安全旁路复审收尾。

### 变更

- 删除未使用的 legacy WebView translator 和 URL scheme handler 及其工程引用，移除全局
  WebKit scheme swizzle、宽松 TLS trust 和其中的凭据字面量；Bing 初始请求改为 HTTPS，
  两个 Info plist 仅保留 `NSAllowsLocalNetworking`。
- 新增 `ServiceEndpointSecurityPolicy`。HTTPS 允许无 userinfo 的有效 host；HTTP 只允许不经
  DNS 解析的 `localhost`、`127.0.0.1`、`::1`。设置校验、备份恢复和实际服务请求
  共享同一判定；initial request 在创建 transport 前复核，credential-bearing redirect
  还必须保持同源。
- 新增 fail-closed `ConfigurationItemRegistry`，以语义 descriptor 区分 portable setting、
  service credential、内容、运行时状态和 unsupported；覆盖静态凭据及带 service/UUID 的
  动态 API key，未知项不导出、不恢复。
- 收紧 `easydict://`：凭据和 endpoint 的读写均被拒绝，避免外部调用方把已有 API key
  导向其 HTTPS host；失败读取不触碰剪贴板。重置必须应用内确认；旧明文导出动作
  只打开加密备份 UI，并拒绝密码、路径、恢复数据及其他 payload-bearing URL 组件。
- 在隐私设置加入 `.easydictbackup` 导入导出。v1 使用固定二进制 envelope、PBKDF2-HMAC-
  SHA256 600,000 次、32-byte salt、12-byte nonce 和 AES-256-GCM；header 作为 AAD，载荷为
  binary plist。写入先创建 `0600` 同目录临时文件再原子发布。
- 恢复在 KDF 前验证 envelope 边界，解密后严格验证 bundle/schema/descriptor/type/endpoint，
  预览设置、凭据、新增、覆盖和不安全 endpoint 数量；通过 persistent-domain overlay 单次
  写入、逐项回读并在失败时恢复和验证完整旧 domain。
- 新增 `QueryReplayRequest` 和可选语言桥接；历史或收藏会先恢复记录中的语言对和 UI，再
  查询。显式源语言跳过检测，`.auto` 重新检测，且不写入全局语言 Defaults。
- 新增 `TextInsertionSession`、`TextInsertionReceipt`、`TextInsertionError` 和三档 confidence。
  session 在 provider 请求前绑定 PID、bundle、AX/browser 上下文，每个 chunk 写入前复核；
  receipt 后才计数，AX 可回读时升级为 verified，兼容路径仅标记 unverified。
- 本地插入错误不再触发 provider fallback；首个有效 chunk 前的 provider 失败仍最多回退
  一次。首次失败、部分中断、取消、权限、无策略、目标变化和 unverified 分发分别得到一次
  本地化反馈；Release 相关日志只保留字符数、策略、confidence 和错误类别。
  WebView、Claude/DeepL 请求、音频、选择和浏览器插入链路的 URL、路径、原始错误、脚本与
  provider 响应正文也不再进入文件日志。
- 为本批 49 个 String Catalog key 同步 `en`、`es`、`ja`、`sk`、`zh-Hans`、`zh-Hant`。

### 设计意图

endpoint policy 同时约束配置入口和真实请求，避免“UI 看似安全、运行时仍可绕过”；redirect
视作新的网络目的地并采用同源约束，避免认证 header 跨 origin。备份只接受 registry 映射的
语义项，文件内部不暴露 raw defaults key，既支持未来 Keychain 迁移，也阻止恶意备份指定任意
UserDefaults key。文本替换把 provider 成功与目标应用接受分开建模，避免把已生成内容误报为
已写入，也防止插入失败后第二家 provider 把另一份结果写向错误目标。

### 验证

- Debug `build-for-testing`：通过；编译 389 个 Swift 文件。
- Focused `test-without-building`：85 个逻辑测试、114 次执行，0 失败、0 跳过；结果为
  `/private/tmp/easydict-behavior-production-derived/Logs/Test/Test-Easydict-2026.08.26_23-26-15-+0800.xcresult`。
- Release build：通过；主 app 自身的 ATS 仅保留 local networking，主可执行文件无 legacy
  WebView 类、旧 scheme handler、全局 ATS 例外、测试 canary 或已删除凭据标记。
- SwiftFormat lint：`0/387 files require formatting`，10 files skipped；SwiftLint 仅有既有
  `PolishingService.swift:11` warning，0 serious。
- String Catalog JSON 与 49 个 key 的六语言覆盖校验通过；两个 Info plist 和 PBX 的
  `plutil -lint` 通过；`git diff --check` 通过。
- 独立最终安全旁路复审阻断项为 0。
- 测试未调用真实 provider，也未操作用户的第三方应用、辅助功能权限或付费凭据。

### 受影响文件

- `Easydict/Swift/Feature/Configuration/`
- `Easydict/Swift/Feature/ActionManager/ActionManager.swift`
- `Easydict/Swift/Model/QueryRecord.swift`
- `Easydict/Swift/Service/`
- `Easydict/Swift/Utility/AppleScript/`
- `Easydict/Swift/Utility/EventMonitor/`
- `Easydict/Swift/Utility/SystemUtility/`
- `Easydict/Swift/View/SettingView/`
- `Easydict/objc/Utility/EZLinkParser/EZSchemeParser.m`
- `Easydict/objc/Service/AudioPlayer/EZAudioPlayer.m`
- `Easydict/objc/ViewController/View/WordResultView/`
- `Easydict/objc/ViewController/Window/`
- `Easydict/App/Info.plist`
- `Easydict/App/Info-debug.plist`
- `Easydict/App/Localizable.xcstrings`
- `EasydictTests/Feature/`
- `EasydictTests/Service/TextReplacementStreamTests.swift`
- `EasydictTests/Utility/AppleScript/`
- `Easydict.xcodeproj/project.pbxproj`

### 后续事项

- 代码和当前构建产物中的旧凭据风险已移除；凭据所有者仍需在私下确认轮换或撤销。未确认
  轮换前，不应声明历史暴露已完全关闭。本批不重写 Git 历史。
- 现有 Defaults 凭据的 Keychain 迁移留到第二批；本批 registry descriptor 是迁移接口。
- 发布前仍需在授权桌面环境执行 TextEdit AX、Safari/Chrome AppleScript、WeChat 兼容模式、
  中途切换焦点、关闭 Accessibility、只读字段、流中断/取消，以及 Apple Dictionary、MDict、
  普通结果 WebView、debug Sparkle localhost 和真实 Release canary 日志矩阵；非 POSIX 导出卷
  的 `0600` 权限表现也需手工确认。
