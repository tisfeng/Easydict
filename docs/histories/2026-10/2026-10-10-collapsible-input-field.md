## 2026-10-10 | 任务：支持折叠输入框并记住状态

**Links:** None

### 执行上下文

- **Agent Name:** `Claude Code`
- **Model:** `claude-opus-5-5`
- **Environment:** `macOS 15.8.1 / Xcode 26.3 (17C529)`

### 用户请求

开启 Show Input Text Field 后，结果区块可以折叠并记住状态，但原文输入区块不能折叠。需要为输入区块
增加折叠控件并持久化其状态。

### 变更

- `EZQueryView` 底部按钮栏最右侧新增箭头按钮（清除按钮移至其左侧，与结果区块箭头位置一致），复用结果区块的 `arrow-down`/`arrow-left`
  图标及 `show`/`hide` 提示文案；折叠时隐藏文本区域，只保留底部按钮栏。
- 折叠状态按窗口类型保存在 Defaults 键 `EZConfiguration_kInputFieldCollapsedKey_<windowType>`，
  切换时更新行高与窗口高度。
- 仅划词翻译（`EZActionTypeAutoSelectQuery`、`EZActionTypeShortcutQuery`，以及 PopClip、系统“服务”
  等经 URL scheme 调用的 `EZActionTypeInvokeQuery`）读取并保存折叠状态；
  输入翻译、OCR、剪贴板等其他动作一律展开，期间手动折叠只在当前会话生效、不写入偏好。
  `EZBaseQueryViewController` 在 `updateActionType:` / `updateQueryTextAndParagraphStyle:actionType:`
  中按动作类型应用状态；`EZWindowManager` 在计算窗口位置前先更新动作类型，避免窗口高度变化导致
  顶部位置偏移。
- 折叠状态下用户直接输入或粘贴时自动展开，避免输入内容不可见；此时动作类型已变为输入查询，
  不会覆盖已保存的划词折叠偏好。
- 修复：新窗口带入选中文本时，`updateInputText:` 按文本高度上报行高，导致折叠的输入区块被撑高且
  按钮错位；改为上报 `heightOfQueryView`，并在折叠时不再固定滚动视图顶部，避免与按钮栏约束冲突。
- 修复（Review 反馈）：OCR 加载动画是 `EZQueryView` 的子视图并锚定在文本视图上，折叠时不会随
  滚动视图隐藏，其计时器还会反复将其设为可见，导致点状动画覆盖底部按钮或溢出到下一单元格。
  `startOCRImage:actionType:autoQuery:` 在开始加载前先按动作类型展开输入框；`EZQueryView` 记录
  加载状态，折叠时停止动画，加载仍在进行时展开则恢复动画。
- 调整（用户反馈）：OCR 不再为显示加载动画而展开折叠的输入框。`EZQueryView` 为加载视图维护两组
  约束：展开时锚定在文本视图左上角，折叠时位于按钮栏中清除按钮左侧并与箭头按钮垂直居中，
  `setCollapsed:` 切换约束；不使用 `mas_remakeConstraints`，以免移除加载视图内部的宽度约束。
  OCR 完成后仍由 `updateQueryTextAndParagraphStyle:actionType:` 按动作类型应用折叠状态。
- 调整（用户反馈）：OCR 完成后也保持折叠。新增 `isOCRActionType:`（`EZActionTypeOCRQuery`、
  `EZActionTypeScreenshotOCR`、`EZActionTypePasteboardOCR`），`updateInputFieldCollapsedWithActionType:`
  对 OCR 动作不改变当前折叠状态（既不展开也不读取偏好），手动切换仍只在当前会话生效。
- 调整（用户反馈）：折叠时加载视图改为位于按钮栏左侧按钮之后：默认紧跟复制按钮，语言检测按钮
  可见时（`showAutoLanguage` 或检测语言非 auto）通过单独约束排在其右侧；`updateDetectButton`
  更新检测语言后同步该约束。
- 修复（Review 反馈）：结果区右键 “Query in App” 命中当前窗口或已固定窗口时直接调用
  `startQueryText:actionType:`，不经过折叠状态同步，`EZActionTypeInvokeQuery` 不会恢复已保存的
  折叠状态；互换翻译语言以 `EZActionTypeInputQuery` 重新查询时，折叠的输入框也不会展开。
  新增 `switchActionType:`，在 `startQueryText:actionType:` 与 `toggleTranslationLanguages` 中使用，
  仅在动作类型变化时应用折叠状态，同类型重新查询（重试、切换语言、点击结果中的单词）保留当前会话
  中手动切换的状态。
- 修复（合并 `dev` 后的 Review 反馈）：`dev` 中 #1327 移除了 `updateQueryCellWithAnimation:`，
  行高改为立即提交、仅窗口动画；折叠切换的两处调用改为 `updateQueryCell`。

### 设计意图

沿用结果区块的箭头交互和既有窗口高度更新链路，只在输入视图与查询控制器之间增加折叠状态，
不改变窗口配置开关的语义。按窗口类型保存与其他窗口级布局偏好保持一致。

### 验证

- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath <agent_dd>`：
  默认配置在 actool 的 `.icon` 图标导出阶段因本机环境失败（`Icon export exited with status 255`），
  与本次改动无关；附加 `'EXCLUDED_SOURCE_FILE_NAMES=*.icon' ASSETCATALOG_COMPILER_APPICON_NAME=AppIcon`
  后构建成功，改动文件无新增警告。
- `git diff --check`：通过。
- 手动检查：用户在本地构建中发现新窗口折叠区块被撑高的问题，已修复并重新构建成功，待用户复测。
- OCR 加载动画修复：同一构建命令（附加上述图标参数）构建成功；`git diff --check` 通过；
  未进行手动 UI 验证。
- OCR 加载视图移至折叠按钮栏：同一构建命令（附加上述图标参数）构建成功，改动文件无新增警告；
  `git diff --check` 通过；未进行手动 UI 验证。
- OCR 保持折叠状态：同一构建命令（附加上述图标参数）构建成功，改动文件无新增警告；
  `git diff --check` 通过；未进行手动 UI 验证。
- 加载视图移至左侧按钮之后：同一构建命令（附加上述图标参数）构建成功，改动文件无新增警告；
  `git diff --check` 通过；未进行手动 UI 验证。
- Query in App / 互换语言修复：同一构建命令（附加上述图标参数）构建成功；`git diff --check` 通过；
  未进行手动 UI 验证。
- 合并 `dev` 后替换已移除的 `updateQueryCellWithAnimation:`：默认构建命令构建成功（无需附加图标参数）；
  `git diff --check` 通过；未进行手动 UI 验证。

### 受影响文件

- `Easydict/Swift/Feature/Configuration/Configuration+Extension.swift`
- `Easydict/Swift/Feature/Configuration/Defaults.Keys+Extension.swift`
- `Easydict/objc/ViewController/View/QueryView/EZQueryView.h`
- `Easydict/objc/ViewController/View/QueryView/EZQueryView.m`
- `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.m`
- `Easydict/objc/ViewController/Window/WindowManager/EZWindowManager.m`

### 后续事项

- None
