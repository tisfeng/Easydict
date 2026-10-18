# OCR 冷启动预热

- 状态：completed
- 创建日期：2026-09-26
- 负责人：isfeng
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Mavis`
- **Model:** `deepseek-flash`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

## 背景

在 macOS 27（26A428）上，首次 OCR 会出现 60–120 秒的卡顿。实测定位结果：

- `TextRecognition.framework` 的 `cr_*_e5.mlmodelc.bundle` 只含 `model.mil` / `weights` /
  `coremldata.bin`，缺少 e5rt 期望的按架构预编译子包 `H13*.bundle`，因此 e5rt 回落到运行时
  ANE 编译，并打印 `Unable to find a valid E5 in provided path ...`。
- 单个重模型编译耗时 26–28 秒，多个模型串行累加。`log show --predicate 'process ==
  "ANECompilerService"'` 显示应用侧编译区间 `19:32:45.317 → 19:33:12.120`（26.8s）与
  `19:33:45.316 → 19:34:13.702`（28.4s），与三次 OCR 同时返回（19:34:14.113）完全对齐。
- 独立 Swift 复现（仅调用 Vision，不经 Easydict）在冷缓存下同样耗时 63.7 秒（现代
  `RecognizeTextRequest`）与 64.2 秒（传统 `VNRecognizeTextRequest`），证明与调用方代码和
  API 选择无关。
- 编译结果按 App 隔离缓存于
  `~/Library/Caches/<bundle-id>/com.apple.e5rt.e5bundlecache/<系统build>/<模型hash>/`，
  缓存热后同一请求仅需 0.05–0.10 秒。

因此该卡顿只在「冷缓存后首次 OCR」发生，代价由用户第一次划词承担。

## 目标与范围

- 目标结果：把冷编译从用户第一次 OCR 挪到 App 启动后的后台空闲期，使首次真实 OCR 不再
  出现分钟级等待；热缓存下预热退化为可忽略开销。
- 允许修改路径：
  - `Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine+WarmUp.swift`（新增）
  - `Easydict/App/EasydictApp.swift`
  - `Easydict.xcodeproj/project.pbxproj`（同步新增文件引用）
  - `docs/exec-plans/`、`docs/histories/`
- 同任务 history：`docs/histories/2026-09/2026-09-26-ocr-cold-start-warmup.md`
- 用户限制：
  - 接入点在 `EasydictApp.swift`（Swift），不使用 `AppDelegate.m`。
  - 入口不加 `@objc`，不需要 Objective-C 可见性。
- 非目标：
  - 不修改任何 OCR 识别逻辑、结果处理或语言映射行为。
  - 不为用户增加可见开关或设置项。
  - 不处理会话中途系统清理缓存的场景。
  - 不尝试修复 Apple 的框架打包缺陷。
- 验收标准：
  1. 冷缓存下，无任何用户操作即完成 ANE 编译（`ANECompilerService` 日志出现配对区间）。
  2. 随后的真实截图 OCR 耗时从 88–118 秒降到个位数秒量级。
  3. 预热不覆盖 OCR 诊断图 `snip_image.png`，不打印 OCR 结果 dump。
  4. 启动无可感延迟；热缓存下额外开销低于 1 秒。

## 工作计划

1. 新建 `AppleOCREngine+WarmUp.swift`，在 `AppleOCREngine` extension 中提供一次性预热入口，
   使用与真实识别完全一致的请求配置（`.accurate` + `usesLanguageCorrection` +
   `automaticallyDetectsLanguage` + 同一语言列表映射），macOS 26 以上走现代
   `RecognizeTextRequest`，以下走 `VNRecognizeTextRequest`。
2. 预热图用 CoreGraphics + CoreText 在后台合成（小尺寸、白底黑字、含中英混合文本），不经过
   `AppleOCREngine.recognizeText` 抛出的写盘与日志路径。
3. 在 `EasydictApp.swift` 的 `EasydictCmpatibilityEntry.main()` 中接入，延迟数秒后在
   `.utility` 优先级后台任务中执行。
4. 同步 `project.pbxproj` 的 group 与 Sources build phase 引用。
5. 构建验证、冷/热两态真机验证。

## 风险与决策

- **决策：不新增用户开关。** 热态实测开销 0.05–0.10 秒，冷态收益是分钟级，不值得增加一个
  需要用户理解的设置项。
- **决策：每次启动都预热，不探测缓存是否存在。** 缓存 hash 算法未公开，嗅探目录结构脆弱；
  而热态代价可忽略，「热时几乎免费，冷时正好救命」。
- **决策：延迟启动并在 `.utility` QoS 执行。** 避开启动期 CPU/磁盘竞争，避免影响启动体验。
- **决策：不复用 `AppleOCREngine.recognizeText`。** 该路径会写盘诊断图并打印大量 observation
  dump，复用会覆盖最有价值的排查证据。
- **风险：冷缓存首次启动会有约 60 秒后台 ANE/CPU 占用**，笔记本上表现为耗电与发热。已通过
  `.utility` QoS 与延迟启动缓解。
- **风险：与用户真实 OCR 并发时会排队等待同一份系统编译**，但不会比现状更差（起点已提前）。
- **风险：Apple 修复框架打包后，预热退化为一次约 0.2 秒的无用调用**，可接受，因此不做机型或
  系统版本判断。
- **最大不确定项：合成图能否触发与真实截图相同的模型集合。** 已知需编译的模型集合由请求配置
  决定而非图片内容，但必须真机验证。

## 进度

- [x] 新建预热实现文件
- [x] 接入 `EasydictApp.swift`
- [x] 同步 `project.pbxproj`
- [x] 构建验证
- [x] 冷/热两态真机验证
- [x] Review、history 与归档

## 验证

- `xcodebuild build`：`** BUILD SUCCEEDED **`（PIPESTATUS 0，无新增 warning）。
- `swiftformat --lint AppleOCREngine+WarmUp.swift`：`0/1 files require formatting`。
  `EasydictApp.swift` 的 lint 失败来自 HEAD 既有漂移，与本变更无关，已还原。
- `git diff --check` 通过；`plutil -lint project.pbxproj` 为 `OK`。
- 模型集合等价性：预热合成图、真实截图、`en-US` 单语言请求三者的编译缓存 hash 集合完全相同
  （`27BD401…` / `131707…` / `572C100…`），且正是 App 缓存中的那三个。
- 冷缓存启动（无用户操作）：预热耗时 125.308 秒（复验 117.720 秒），3 个 hash 被重建。
- 热缓存启动：预热耗时 0.499 / 0.407 / 0.203 秒。
- 耗时收益：同一二进制、同一真实截图、同一请求配置下，冷启 68.6 秒（另一次 113.0 秒）
  → 热启 0.231 秒。
- 无副作用：`snip_image.png` mtime 未被改写；预热日志无 OCR observation dump。
- 第 4 个缓存 hash `4A26A9F6` 来自 `VNDetectBarcodesRequest`（0.18 秒），不在预热范围。

### 未验证

- App 内首次真实 OCR 的 `Cost time` 实测改善：受阻于环境（构建实例无屏幕录制权限，
  且另一 checkout 的同 bundle id 实例抢占全局快捷键并共享日志与缓存），已用同一配置的
  冷/热对照间接证明。
- macOS 26 以下的传统 `VNRecognizeTextRequest` 分支：本机只会走现代分支，仅静态审查。

## 完成条件

- 验收标准 1–4 均取得证据，或明确记录无法验证的项与原因。
- 冷编译行为无法由离线单测覆盖，须记录真机冷/热两态的实测结果。
