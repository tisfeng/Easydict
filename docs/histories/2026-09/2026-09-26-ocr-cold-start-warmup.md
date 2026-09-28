## 2026-09-26 | 任务：为 Vision OCR 增加启动预热以消除首次查询的冷编译卡顿

**Links:** 计划 `docs/exec-plans/completed/2026-09/2026-09-26-ocr-cold-start-warmup.md`

### 执行上下文

- **Agent Name:** `Mavis`
- **Model:** `deepseek-flash`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

### 用户请求

用户贴出一段 OCR 日志，其中反复出现 `Unable to find a valid E5 in provided path
.../cr_*_e5.mlmodelc.bundle/`，要求检查问题。排查确认该报错与「首次 OCR 耗时 88–118 秒」
同源后，用户认可启动预热的缓解方案，并要求接入点放在 `EasydictApp.swift`（Swift，不使用
`AppDelegate.m`）、入口不加 `@objc`。

### 变更

- 新增 `AppleOCREngine+WarmUp.swift`：`AppleOCREngine.warmUpVisionOCRIfNeeded()` 用锁保证
  同进程只执行一次，立即返回；随后在 `Task.detached(priority: .utility)` 中延迟 3 秒，用
  CoreGraphics + CoreText 合成一张 320×96 的图，以与真实 `.auto` 查询完全相同的配置发一次
  丢弃结果的 Vision OCR 请求（macOS 26+ 走 `RecognizeTextRequest`，否则走
  `VNRecognizeTextRequest`）。
- `EasydictApp.swift` 的 `EasydictCmpatibilityEntry.main()` 中，在 `EasydictApp.main()` 前
  调用该入口。
- `project.pbxproj` 同步新增文件的 group 与 Sources 引用。
- 新增计划文档。

### 设计意图

- 根因在系统框架：`TextRecognition.framework` 的 `cr_*_e5.mlmodelc.bundle` 只含
  `model.mil` / `weights` / `coremldata.bin`，缺少 e5rt 期望的按架构预编译子包 `H13*.bundle`，
  因此 e5rt 回落到运行时 ANE 编译。单个重模型编译实测 26–28 秒，多个串行累加即 60–120 秒。
  应用侧无需也无法修复框架，只能把这段一次性开销从「用户第一次查询」挪到「启动后的空闲期」。
- 不复用 `AppleOCREngine.recognizeText`：该路径会写盘诊断图 `snip_image.png` 并打印大量
  observation dump，复用会覆盖排查证据。
- 每次启动都预热、不做缓存探测：热缓存实测 0.05–0.5 秒，代价可忽略，而缓存 hash 算法未公开，
  嗅探目录结构脆弱。即「热时几乎免费，冷时正好救命」。
- 不新增用户开关：收益与代价差距悬殊，不值得增加一个需要用户理解的设置项。
- 预热请求配置必须与真实路径逐项一致，因为需要编译的模型集合由请求配置决定。

### 验证

- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath <agent_dd>`：
  `** BUILD SUCCEEDED **`（PIPESTATUS 0，无新增 warning）。
- `swiftformat --lint AppleOCREngine+WarmUp.swift`：`0/1 files require formatting`。
  `EasydictApp.swift` 的 lint 失败来自 HEAD 既有的 `#if DEBUG` 缩进漂移，与本变更无关，
  已还原以免混入无关改动。
- `git diff --check`：通过。
- `plutil -lint Easydict.xcodeproj/project.pbxproj`：`OK`。
- **模型集合等价性（本变更的核心正确性要求）**：独立 Swift 复现分别用预热合成图（320×96）、
  真实截图（86×48）、以及 `en-US` 单语言请求各跑一次冷缓存，三者产生的
  `com.apple.e5rt.e5bundlecache` hash 集合完全相同
  （`27BD401…` / `131707…` / `572C100…`），且正是 App 自身缓存中的那三个。
- **冷编译确实被预热跑完**：删除
  `~/Library/Caches/com.izual.Easydict-debug/com.apple.e5rt.e5bundlecache` 后启动 App，
  在无任何用户操作的情况下，日志出现
  `Vision OCR warm-up finished, cost time: 125.308 seconds`（复验 117.720 秒），
  同时 3 个 hash 被重建，`ANECompilerService` 出现对应的
  `Start/End of compilation of network` 配对区间。
- **耗时收益**：同一二进制、同一真实截图、同一请求配置下，
  `warmtest_real` 冷启 68.6 秒（另一次 113.0 秒）→ 热启 0.231 秒。
- **无副作用**：预热全程不触碰
  `~/Library/Application Support/com.izual.Easydict-debug/logs/app/Image/snip_image.png`
  （复验后 mtime 仍为 2026-09-25 19:32:45）；预热期间日志无任何 `setupOCRResult` /
  `Original unified OCR observations` 输出。
- 热缓存启动的预热开销：0.499 / 0.407 / 0.203 秒。
- 手动检查：第 4 个缓存 hash `4A26A9F6` 经实验确认来自 `VNDetectBarcodesRequest`
  （二维码检测，0.18 秒），与文本 OCR 无关，因此未纳入预热范围。

### 受影响文件

- `Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine+WarmUp.swift`（新增）
- `Easydict/App/EasydictApp.swift`
- `Easydict.xcodeproj/project.pbxproj`
- `docs/exec-plans/active/2026-09-26-ocr-cold-start-warmup.md`（完成后归档）

### 后续事项

- **未能验证**：App 内首次真实 OCR 的 `Cost time` 实测改善。验证受阻于环境而非代码——
  App 构建实例未获屏幕录制权限（`Failed to capture screenshot`），且另一 checkout 存在同
  bundle id 的并发实例，抢占了全局快捷键并共享同一份日志与缓存。已用「同一二进制 + 同一真实
  截图 + 同一请求配置」的冷/热对照（68.6s → 0.231s）间接证明收益。
- **未能验证**：macOS 26 以下的传统 `VNRecognizeTextRequest` 分支。本机为 macOS 27，只会走
  现代分支；该分支已静态审查，但未经运行时验证。
- 冷缓存首次启动的预热会在后台占用约 60–120 秒 ANE/CPU（已用 `.utility` QoS 与 3 秒延迟
  缓解）。若后续认为需要，可考虑「仅外接电源时预热」，但需先确认该取舍。
- Apple 若补上预编译子包，预热会退化为一次约 0.2 秒的无用调用；因代价极低，不做机型或系统
  版本判断。
- 排查中发现两处与本任务无关的既有现象，未处理：`AppleDictionary.queryAllIframeHTMLResult`
  在 2026-09-25 02:28:33 的 SIGSEGV 崩溃日志；2026-09-25 19:04 那次 OCR 未返回、进程后于
  19:23 重启（该次无 e5rt 报错）。
