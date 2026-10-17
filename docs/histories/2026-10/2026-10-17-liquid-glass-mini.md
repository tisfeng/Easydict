## 2026-10-17 | 任务：增加 Liquid Glass 迷你窗口

**Links:** [执行计划](../../exec-plans/completed/2026-10/2026-10-17-liquid-glass-mini.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 26.5 (17F42)`

### 用户请求

在 Easydict 中增加可选的特殊迷你窗口，沿用划词触发，只显示一个服务的译文。加载时显示三点玻璃胶囊，完成后轻弹性展开为圆角卡片；服务名弱化，固定按钮为卡片内部右上角的小图标，默认淡显、悬停加深，不叠加玻璃底或边框，不显示蓝色焦点框。

### 变更

- 新增独立玻璃模式开关。开启后，左侧 ServiceTabViewModel 的服务开关变为单选圆点，选择其他服务即切换翻译提供商；右侧移除重复下拉菜单。关闭模式后恢复经典迷你窗口的原有多服务配置。左侧所有服务（包括自定义及仅翻译的 AI 服务）均可选择，不按句子解析能力筛选。
- 用 SwiftUI 原生玻璃绘制译文、低对比服务名、20 点固定按钮、加载及失败/重试状态。
- 桥接现有 Objective-C 查询生命周期，取消旧查询并校验查询代次，完成流式输出后再展开。
- 动画调整真实窗口边界，并限制在可见屏幕范围；长文滚动，支持减少动态效果及降低透明度。
- 隐藏原文、语言选择和经典工具栏；新增复制、重试和关闭的上下文菜单。
- 接入 macOS 26 及更新版本，更新六种语言的 String Catalog 和 Xcode 文件引用。
- 未新增或扩写测试。按用户截图调整固定按钮位置、大小、悬停和焦点外观。
- 根据最终截图去除 pin 自身的圆形玻璃底，整张卡片只应用一次玻璃效果，并让焦点高亮抑制覆盖内部按钮。
- 新增原生可选文本视图与 3 点宽的无轨道滚动滑块，保留滑块拖动和系统淡出。上沿 16 点高区域调用系统窗口拖动，固定后仍可移动，不拦截正文选取或 pin 点击。

### 设计意图

继续使用原窗口管理和翻译服务，只替换迷你窗口的呈现层，避免复制划词和语言检测逻辑。特殊模式每次只构造选中的查询服务，不持久化修改经典服务的启用标记，点击已选圆点不会取消唯一选择；选定服务失效时提示重新选择，不自动向其他提供商发送内容。移除经典表格的布局约束，确保加载胶囊可真正缩小。

### 验证

- Debug arm64 编译与 `ReverseTranslationTests`、`OpenAIStreamTaskControlTests` 共 10 项现有测试通过。实际命令如下，`agent_dd` 指向该 checkout 的独立 DerivedData：

  ```sh
  xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict \
    -configuration Debug -destination 'platform=macOS,arch=arm64' \
    -derivedDataPath "$agent_dd" ENABLE_PREVIEWS=YES \
    'EXCLUDED_SOURCE_FILE_NAMES=Easydict-27.icon' \
    ASSETCATALOG_COMPILER_APPICON_NAME=Easydict-26 \
    -only-testing:EasydictTests/ReverseTranslationTests \
    -only-testing:EasydictTests/OpenAIStreamTaskControlTests
  ```

- 构建环境修复：`xcodebuild -runFirstLaunch` 解决初始框架符号不匹配。`ENABLE_PREVIEWS=YES` 按项目脚本跳过全库自动格式化；Xcode 26.5 的图标编译问题用命令行覆写解决，未改变工程中的默认图标。
- 对新增窗口 Swift 文件及 WindowConfigurationView 运行 SwiftLint，无违规；后续四个界面改动文件复检通过。
- 用户补充的内部 pin 悬停、细滚动条及固定后拖动修改再次通过 `xcodebuild build`，使用上列相同 Debug 配置和本地图标覆写。此轮只改界面，未重复执行无关测试。
- `git diff --check`、`jq -e . Easydict/App/Localizable.xcstrings`、工程 `plutil -lint` 均通过。
- `codesign --verify --deep --strict build/Easydict-debug.app` 通过。增量覆盖曾残留旧 XCTest 组件，干净替换整个 app 后校验通过并启动。产物使用临时签名，不是正式发布签名。
- 使用仓库 review 技能检查基线 `af5b654f2890341a48f32237118ad2a686ea8f9d` 到最终工作树，包含四个未跟踪 Swift 文件。记录内容摘要并在审查结束复验；修复隐藏输入视图不再更新模型、错误被经典视图规则隐藏、关闭中断加载以及低系统版本设置禁用等问题，最终无进一步有效 finding。
- 增量 review：以 `8b99947dbf8c6616b643b2c7361b853b850797f7` 为基线记录七个变更/新增文件摘要，复核顶部拖动区与 pin/正文不相交、文本测量宽度、原生 scroller 绘制和事件契约、工程引用及辅助功能降级，无进一步有效 finding。最终生产文件内容摘要复验一致。
- 服务列表修复再次通过同一组 10 项现有测试；复核菜单直接使用左侧列表、UUID 选择保持稳定、选定服务被删除时不回退，以及普通 AI 翻译不会再被句子解析开关过滤。最终六文件增量快照中的生产内容未变化，无进一步有效 finding。
- 左侧单选最终修改再次通过 Debug 编译和同一组 10 项现有测试，三个设置 Swift 文件的 SwiftLint、差异空白及 String Catalog 检查通过。以 `c1b1b4ec6993c96fa8377e52d4f94c9830f734f1` 为基线冻结六文件快照，审查单选不可取消、经典启用标记保留、模式切换通知、查询取消、服务删除及 CLI 确认路径；生产内容摘要复验一致，无进一步有效 finding。现有测试不直接覆盖设置单选交互，该交互尚未人工验证。干净替换调试 app 后签名校验通过并启动。
- 方案评估：以薄桥接复用既有查询管线符合范围；无需另建窗口管理器或翻译请求管线。侧栏单选沿用独立服务 ID，将其映射为单选状态，不需要迁移或覆盖经典多服务设置。
- 手动检查：用户截图确认玻璃材质和单一译文窗口可运行。用户后续截图确认重新授权后可用且蓝框消失。用户进一步确认布局、长文滚动及固定后上沿拖动正常，并确认最近一次重启后翻译正常显示。随后根据截图去除 pin 的独立玻璃底；这次纯外观微调尚未再次人工确认。长文、错误重试、多屏边缘和模式往返的完整交互未逐项验证。
- 界面工具超时，随后返回 ScreenCaptureKit -3811，未把自动截图验证记为通过。
- 调试版重编译后系统仍显示开启的旧授权，但应用检查返回未授权。核查原有 `AXIsProcessTrustedWithOptions` 调用未修改；当前临时签名的 designated requirement 绑定代码哈希。曾退出调试版，引导用户移除旧条目并重新添加固定的 `build/Easydict-debug.app`，随后用户截图确认再次可用。后续重编译仍可能需要重新授权。

### PR #1365 review 修复

- [C1 词典结果格式遗漏](https://github.com/tisfeng/Easydict/pull/1365#discussion_r4301696681) 成立：原实现仅使用 translatedText 和 parts，成功的 HTML 词典或 simpleWords 查询可能显示没有结果。
- 新增 GlassMiniResultText：优先保留非空译文，其次合并词性释义和 simpleWords，再使用 Apple Dictionary 的 innerTexts，最后解析 HTML/iframe srcdoc。空字符串不再阻断后续回退。全部服务仍可在左侧选用。
- HTML 通过 Foundation DOM 提取纯文本，保留段落和表格单元格分隔，忽略脚本、样式及隐藏元素；不执行网页、不加载外部实体。解析放在后台，主线程接收结果前校验任务取消，防止已关闭、已切换服务或新查询后出现旧结果。
- 使用原生文本适配而非嵌入完整网页，可保留单层玻璃、可选文本和原滚动行为，不引入 HTML 词典的背景、控件或第三方解析依赖；不呈现图片、音频及网页交互。
- Xcode 27.1 (27A9275) Debug arm64 构建及 MDictReaderTests、ReverseTranslationTests、OpenAIStreamTaskControlTests 共 32 项既有测试通过；本次使用默认 macOS 27 图标，无需旧 SDK 图标覆写。MDict 外部词典集成用例未设置环境路径，因此提前返回；测试通过不等于真实词典 UI 验收。
- 新增/修改的 Swift 文件通过 SwiftLint，git diff --check 与工程 plutil 校验通过。手动运行 Foundation HTML 解析检查实体、段落与 srcdoc 保留；未新增或扩写测试。
- 使用 review 技能检查新适配器、调用者和生命周期，验证后重新核对生产文件摘要，无进一步有效 finding。真实 Apple/MDict 的窗口视觉效果与新适配器边界仍未直接覆盖。

### 2026-10-18：固定窗口手动查询状态修复

- [C2 固定玻璃窗口未重置](https://github.com/tisfeng/Easydict/pull/1365#discussion_r4301904889) 成立：关闭自动查询后，固定窗口接收新选中文字时跳过 resetTableView 与 startQueryText，只更新隐藏输入，旧结果及进行中的请求仍可能保留。
- 在玻璃输入更新入口比较新旧文本；变化时先递增查询代次、停止旧服务并取消呈现任务，再清空结果并进入 ready 状态，显示现有“翻译”按钮，然后更新输入及 actionType。
- 重复输入保持当前结果；自动查询仍由原调用者启动；经典窗口路径不变。复用已有取消与 ready 逻辑，无新 UI、配置或本地化。
- Xcode 27.1 (27A9275) Debug arm64 build-for-testing 成功；test-without-building 的 ReverseTranslationTests、OpenAIStreamTaskControlTests 共 10 项既有测试通过，git diff --check 通过。
- review 核对固定/非固定、手动/自动、同文/新文、旧网络与语言检测回调代次、HTML 解析取消及 ready 按钮；源码摘要复验一致，无进一步有效 finding。
- 未新增或扩写测试，现有测试不直接覆盖该固定窗口交互；界面工具超时，手动划词场景尚未完成视觉验收。

### 受影响文件

- `Easydict/Swift/View/Window/GlassMiniConfiguration.swift`
- `Easydict/Swift/View/Window/GlassMiniView.swift`
- `Easydict/Swift/View/Window/GlassMiniTextView.swift`
- `Easydict/Swift/View/Window/GlassMiniDragArea.swift`
- `Easydict/Swift/View/Window/GlassMiniAnimator.swift`
- `Easydict/Swift/View/Window/GlassMiniPresentation.swift`
- `Easydict/Swift/View/Window/GlassMiniResultText.swift`
- `Easydict/Swift/View/SettingView/Tabs/View/WindowConfigurationView.swift`
- `Easydict/Swift/View/SettingView/Tabs/TabView/ServiceTab.swift`
- `Easydict/Swift/View/SettingView/Tabs/TabView/ServiceTabListViews.swift`
- `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.h`
- `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.m`
- `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryWindow.h`
- `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryWindow.m`
- `Easydict/App/Localizable.xcstrings`
- `Easydict.xcodeproj/project.pbxproj`
- 本任务计划及 history。

### 后续事项

- 翻译显示、滚动和拖动已获用户确认；左侧单选的最终交互、无玻璃底的 pin 视觉效果及其余人工边界场景可继续试用。
- 若持续开发或分发，使用稳定开发者签名，以减少每次重编译后的重复授权。
- 本机源码约 95 MB、调试 app 约 127 MB，附带测试组件的测试构建约 196 MB、编译缓存约 5.8 GB；产物保留在忽略的 `build/` 目录。
