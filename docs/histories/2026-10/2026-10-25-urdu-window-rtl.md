## 2026-10-25 | 任务：实现 Urdu 全窗口界面方向

**Links:** [PR #1374](https://github.com/tisfeng/Easydict/pull/1374) ·
[RTL 评论](https://github.com/tisfeng/Easydict/pull/1374#discussion_r4366888318) ·
[执行计划](../../exec-plans/completed/2026-10/2026-10-25-urdu-window-rtl.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode Unknown (Unknown)`

### 用户请求

在现有 Urdu PR 上实现剩余 AppKit/hosted-window RTL，取代仅文档化限制的方案；沿用此前普通
push 与维持 Ready 的授权，不新建 PR、不合并、不发布，保留无关工作并如实记录验证限制。

### 变更

- 初始工作树和索引为空，保留 `076f23b6` 的本地提交，安全 fast-forward 到准确远程 head
  `5708742dd6dc84c377d72f4bb75c4d2674ffc7dc`；保留其中上游集成和维护者测试桥接修复。
- 新增共享 SwiftUI modifier，沿用现有语言偏好，同时设置 locale 与 layoutDirection；覆盖设置、
  菜单、About/致谢、OCR、三种 CLI debug 面板、截图覆盖窗口及 Apple Translation 的 hosting 根。
  已打开窗口通过偏好更新重绘，
  窗口所有者可以同步刷新本地化标题。
- 新增 AppKit adapter，在新建、语言切换和 table row/result 重建时更新 native 视图方向；
  查询工具栏、语言选择、服务标题和结果工具栏使用 leading/trailing 约束，标题栏镜像位置及按钮顺序。
- 原生 popup 菜单与主菜单跟随界面方向，popup 锚点使用对应 leading 角。
- 截图提示按界面方向定位并同步命中区域，图像与选区坐标保持物理坐标；OCR 图像区域保留 LTR
  坐标空间。结果文本和字典内容保持独立方向，不修改段落样式、不翻转图像或 WebView。
- 同步 Xcode 对新源码的引用；没有改动 catalog、测试、服务能力或翻译源/目标语言。

### 设计意图

复用平台语义方向和既有语言偏好，避免只给两个 SwiftUI 根加环境值而遗漏 AppKit 窗口。
采用应用自身视图树的方向更新和语义约束，保留文本、图像与系统窗口框架的边界。
保持现有 LTR 控件顺序，切回 English 时恢复方向，不增加全局 swizzle 或镜像变换。

### 验证

- `arm64-apple-macosx13.0` / Swift 5：实际共享本地化源码和通知/popup 源码的 typecheck、
  module emit 与 Objective-C header emit 成功；导入真实应用头文件，未声明假的应用类型。
- 核对生成的 `interfaceLayoutDirection`、`applyInterfaceLayoutDirectionToView:` 和
  `popUpBelowView:` 与调用位置一致；Swift actor 隔离检查通过。
- 本轮 13 个 Swift 文件的语法解析、`plutil -lint`、`git diff --check` 通过。
- 工程对象审计确认仅注册两个源码，既有 build settings 未改；两个 catalog 与起始 head 逐字节
  相同，仍有 564/4 个 Urdu 条目。未新增或扩写测试。
- 平台布局观察显示相同 leading 约束在 LTR/RTL 下从 x=12 镜像到 x=158，控件宽度不变；
  这是 AppKit 语义约束证据，不是 Easydict GUI 验证。
- `xcodebuild build` 和 LocalizationTests 调用均在入口因只有 Command Line Tools 而失败。
  维护者在 `5708742` 记录的五项 hosted tests 通过属于旧实现，不视为本轮通过。
- 手动检查：按 review 技能审查完整本轮 diff、新文件、所有 hosting 入口及 AppKit 重建调用链，
  当前方式覆盖 C2 指出的传播缺口；没有确认的未修复实现 finding。运行时视觉结果仍未知。
- 初始 PR 的五项 CI 成功，两个线程完整读到各自翻译回复。C1 在起始 head 已不适用，C2 已有
  实现修复；没有发送远程回复或 resolve。最终 head/CI 和 PR 正文在 push 后读回确认并报告。

### 受影响文件

- `Easydict/Swift/Feature/Localization/I18nHelper+Layout.swift`
- `Easydict/Swift/Feature/Localization/InterfaceLanguageModifier.swift`
- `Easydict/App/EasydictApp.swift` 和 Xcode 工程。
- hosted window 入口、截图/OCR 界面及 native popup 扩展。
- AppKit query controller、titlebar、query/language/result chrome。
- 本 history 与归档 plan。

### 后续事项

- 在完整 Xcode 环境运行 build 和 LocalizationTests，并检查 Urdu/English 往返切换、新建/已开
  主/浮动/迷你窗口、About/致谢、OCR/截图与 debug 面板的布局、点击、复制、浅色/深色和长文案。
- 没有修改后应用截图或独立流利 Urdu 审校；Release/Archive、Intel 和服务行为仍未验证。

### 后续修正：RTL popup 右侧对齐

- `7ea15d8d` 的 [popup review](https://github.com/tisfeng/Easydict/pull/1374#discussion_r4371069380)
  指出把菜单左上角放到按钮右侧不能实现右对齐；确认该 finding 有效。翻译 bot 的回复是同一问题。
- 只修改共享 popup helper：RTL 时先 `update()` 确保菜单尺寸反映当前内容，再使用
  `view.bounds.maxX - size.width` 计算物理左边缘。LTR 的 x=0、原有垂直间距和调用 API 保持不变。
  五处语言、通用选项、模型和快捷操作调用均已在弹出前构造菜单，没有新增 delegate 延迟填充路径。
- [Apple popup 文档](https://developer.apple.com/documentation/appkit/nsmenu/popup(positioning:at:in:))
  说明 nil positioning 使用内容框左上角；[size 文档](https://developer.apple.com/documentation/appkit/nsmenu/size)
  提供菜单宽度，并说明屏幕空间可能限制最终显示尺寸。
- 对修改后的实际本地化、通知和 popup 源码重新运行 Swift 5 / macOS 13 typecheck，通过；
  `git diff --check` 通过。没有新增或扩写测试。
- build 与 LocalizationTests 再次因缺少完整 Xcode 在入口失败；没有运行修改后应用或获取截图。
  屏幕边缘夹紧及 Urdu/English 视觉对齐仍需运行时确认。
- 使用 review 技能冻结基线 `7ea15d8de6726a4e3e13b358946d82d66291d6b3`，复查完整补丁、
  全部五处调用和 AppKit 定位契约；修正覆盖该 finding，未确认其他缺陷。沿用最小 helper 修正，
  没有引入自定义菜单窗口或改变选项选择行为。
