## 2026-08-30 | 任务：原位截图翻译与自动重译

**Links:** `docs/exec-plans/completed/2026-08-30-in-place-screenshot-translation.md`

### 用户请求

在现有截图翻译之外新增完整的“原位截图翻译”：用户框选固定屏幕区域后，常驻浮窗按原文
布局覆写译文，并可切换语言、服务、原文/译文、置顶和自动更新；区域稳定变化时自动重新
OCR 和翻译。本次同时完成产品交互、界面、架构、隐私、本地化、测试与工程闭环，不拆分
交付阶段。

### 变更

- 新增菜单栏入口、可配置但默认未绑定的全局快捷键，以及 Objective-C/Swift 窄桥接；保留
  原有截图翻译、截图 OCR 和静默 OCR 调用路径。
- 将截图框选扩展为不可变 `ScreenshotSelection`，携带 display ID、单屏相对选区、scale 和
  首帧；选择取消、过小、权限与显示器失败使用 typed result，重新框选取消时恢复旧会话。
- 新增独立 `NSPanel`。浮窗默认置顶、失焦不消失、可缩放，并通过
  `sharingType = .none` 和 ScreenCaptureKit 排除 Easydict 进程避免自采集；内容区保持截图
  aspect-fit，底部工具栏在常规、紧凑和 360 pt 窄窗之间自适应。
- 完成原文/译文切换、按住 Space 临时查看原文、源/目标语言、语言交换、单一 provider、
  自动更新、手动刷新、复制、置顶、重新框选和关闭；块支持选择、双击/菜单复制、溢出详情、
  键盘操作和 VoiceOver 描述。
- 为 Apple Vision OCR 新增纯内存、不可变的 layout result，并抽出可单测的坐标映射；原位
  路径不调用远程 OCR、不生成 `snip_image.png`，短文本也保留 observation/layout block。
- 使用 ScreenCaptureKit 以 2 fps 采集固定区域；实现 dirty-rect/视觉指纹变化检测、400 ms
  稳定去抖、1 秒 OCR gate、最新帧选择、单 OCR 上限和 display/睡眠/锁屏/miniaturize 生命周期。
- 新增 session actor、generation gate、OCR block builder/matcher、会话内 LRU cache 和块级
  translation coordinator。只有稳定变化块重新翻译；旧 OCR/provider 结果不能覆盖新画面，
  同批等价块合并成一次请求，网络翻译最多 3 并发且不跨 provider fallback。
- provider request boundary 将 service 创建、语言配置、免费配额 prehandle 和 usage 写入置于
  cancellation-safe 串行 permit 内，实际网络阶段仍可并发；cache hit、失败的 prehandle 和
  被合并的重复块不会重复记账。
- provider resolver 仅暴露 Fixed Window 中已启用、支持 translation/sentence 的服务；服务
  删除或关闭时回退到下一个有效项，无可用服务时清空，网络、鉴权或限流失败不静默换服务。
- 首次使用显示隐私说明，明确 Apple Vision 在本地识别、只把 OCR 文字发送给当前服务、
  自动更新会产生新请求且不上传截图像素；用户继续后才记录 runtime acknowledgement。
- 新增 Advanced 设置中的默认服务、自动更新和置顶开关；Defaults 只保存偏好，首次隐私确认
  作为 runtime 状态，live 截图、文字和坐标不进入 Defaults。独立上游 PR 不依赖尚未合入的
  配置备份 registry；相关能力合入后再补充 portable descriptor。
- 抑制 Codex CLI 与 Claude Code 在该调用链的 plaintext debug logger，并将 Doubao SSE
  解码错误改为只记录字节数；截图几何日志也改为不含坐标。47 个新增 String Catalog key
  均覆盖 `en`、`es`、`ja`、`sk`、`zh-Hans`、`zh-Hant`。

### 界面与行为意图

浮窗只在 Easydict 内叠加译文，不修改目标应用或屏幕像素。画布与工具栏分离，因此窗口缩放
只重算 normalized rect，不触发 OCR。自动更新采用“视觉变化、稳定去抖、语义变化”三层门禁，
避免动画或字幕抖动造成请求风暴；语言与 provider 变化只使依赖它们的工作失效。失败块保留
当前一致快照并显示分类状态，权限或 display 失效会先取消旧 pipeline，再进入可恢复暂停态。

### 验证

- Debug `build-for-testing`：原实现分支通过；最新上游适配分支重新执行并在 PR 中报告结果。
- focused suites 覆盖 selection/geometry、变化检测、OCR blocks/pipeline/matching、cache、resolver、
  request accounting/coalescing、session stale generation/lifecycle、view model、render snapshot
  和快捷键；独立适配分支不宣称尚未合入的配置备份回归。
- Release build：原实现分支通过；最新上游适配分支重新执行并在 PR 中报告结果。
- 最新上游适配分支的 Debug `build-for-testing` 通过；15 个 focused suites 共 94 项测试通过，
  0 失败、0 跳过；Release build 通过并生成 `Easydict.app`。
- 最新上游适配分支的 SwiftFormat lint 为 `0/410 files require formatting`，10 files skipped；
  `git diff --check` 通过。SwiftLint 扫描 412 个文件，5 个 warning、0 serious；warning 均为
  session/coordinator 产品或测试的 file/type length。
- String Catalog JSON 有效，47 个 feature key 的六语言覆盖完整；两个 Info plist 和 PBX 的
  `plutil -lint` 均通过。
- 静态隐私检查：新功能目录没有文件、历史、收藏或 UserDefaults 内容写入；只有显式“复制”
  写剪贴板；Apple OCR 不再引用 `snipImageFileURL`；Release 主程序不含 focused test 的正文
  fixture。独立旁路复审最终 P0/P1 阻断项为 0。
- 测试未调用真实翻译 provider，也未更改用户 TCC 或第三方应用；copy 测试使用注入的唯一
  命名 pasteboard，不访问系统 general pasteboard。

### 受影响文件

- `Easydict/Swift/Feature/InPlaceScreenshotTranslation/`
- `Easydict/Swift/Feature/Screenshot/Screenshot/`
- `Easydict/Swift/Service/Apple/AppleOCREngine/`
- `Easydict/Swift/Service/CodexCLI/`
- `Easydict/Swift/Service/ClaudeCode/`
- `Easydict/Swift/Service/Doubao/DoubaoService.swift`
- `Easydict/Swift/Service/Model/QueryService.swift`
- `Easydict/Swift/Feature/Configuration/`
- `Easydict/Swift/Feature/Shortcut/`
- `Easydict/Swift/View/MenuItemView.swift`
- `Easydict/Swift/View/SettingView/`
- `Easydict/objc/ViewController/Window/WindowManager/`
- `Easydict/App/Localizable.xcstrings`
- `EasydictTests/Feature/InPlaceScreenshotTranslation/`
- `EasydictTests/Support/TestSuites.swift`
- `Easydict.xcodeproj/project.pbxproj`

### 发布前手工门禁与后续事项

- 当前环境没有执行 macOS 13/14/15、Intel、不同 scale 双屏/负 origin、显示器热插拔、
  Spaces/full-screen、首次授权和运行中撤权矩阵；这些仍需签名 app 的桌面 QA。
- 真实 provider、断网/鉴权/限流、Codex CLI/Claude Code、Release 日志/历史/Defaults/网络代理
  canary、镜厅检测、10 分钟动态 soak、120-block UI 响应和 VoiceOver 必须在发布前验证。
- `InPlaceTranslationBlockView` 当前在 MainActor 中测量文字并采样小图；若 120-block soak 出现
  卡顿，应把 layout/appearance 预计算并缓存。运行时递归画面检测器也可作为防御增强。
- 后续可拆分较长的 session 和测试 suite，消除本批 5 个非 serious SwiftLint 长度 warning。
