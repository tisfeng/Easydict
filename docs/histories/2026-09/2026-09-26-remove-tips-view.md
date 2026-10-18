## 2026-09-26 | 任务：移植 Scoco 提交，移除废弃的 TipsView

**Links:** Scoco `b3b143ef4`（refactor(query-window): 移除废弃的 TipsView）、计划 [`docs/exec-plans/completed/2026-09/2026-09-26-remove-tips-view.md`](../../exec-plans/completed/2026-09/2026-09-26-remove-tips-view.md)

### 执行上下文

- **Agent Name:** `Mavis`
- **Model:** `deepseek-flash`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

### 用户请求

将 Scoco 提交 `b3b143ef4` 移植到 Easydict，先给方案再执行；确认接受 OCR 错误提示降级为
Toast、保留 `[self focusInputTextView]`（B 方案），并要求 `disableTipsView` 彻底移除。

### 变更

- 删除 `EZTableTipsCell.h` / `EZTableTipsCell.m`（355 行），并从
  `Easydict.xcodeproj/project.pbxproj` 移除 4 处引用（1 个 build file、2 个 file reference、
  group children 与 Sources 各 1 条）。
- `EZBaseQueryViewController.h`：移除 `#import "EZTableTipsCell.h"` 与 `showTipsView:` 声明。
- `EZBaseQueryViewController.m`：移除 `EZTableTipsCellId`、`tipsCell`/`tipsCellType`/
  `tipsCellContent`/`isTipsViewVisible`/`tipsCellIndex` 属性、三个 `showTipsView:` 方法、
  `isCustomTipsType`、`isTipsViewAtRow:`；删除 `startOCRImage:`、`viewForTableColumn:`、
  `heightOfRow:`、enter/clear 回调、`resultCellOffset` 中的 tips 分支；`updateWindowConfiguration:`
  的索引计算简化为 `self.selectLanguageCellIndex = self.isInputFieldCellVisible ? 1 : 0;`；
  OCR 错误提示改为 `EZToast`（沿用既有 `dispatch_block_on_main_safely`）。
- `EZWindowManager.m`：移除 nil-text 分支中的 `showTipsView:YES` 调用块（含 FAQ wiki 链接注释）。
- 彻底移除 `disableTipsView`：`Defaults.Keys+Extension.swift` 的 key、`MyConfiguration.swift`
  的属性、`AdvancedTab.swift` 的 Toggle 与 `@Default`。
- `Localizable.xcstrings`：删除 9 个 `tips_*` 键与 `setting.advance.disable_tips_view`，
  共 409 行（Scoco 为 4 locale/252 行，Easydict 为 6 locale）。

### 设计意图

不能直接 cherry-pick，原因有两点。其一，Scoco 该提交只删了 `disableTipsView` 的**定义**，
它的 UI 开关与本地化键在 Scoco 由 `ed1d18a2b`、`bc23f1768` 两个独立提交移除；Easydict 侧这三处
都还在，只照搬会留下「开关存在但永远无效」的半成品，故一并移除四件套。

其二，两个仓库的查询窗口链路已分叉：Easydict 的 `EZWindowManager.m` 已在 `eedc89391` 把空文本
规范化收窄到 `isSelectionQuery`，因此 `queryText == nil` 只可能出现在
`keepPrevResultWhenEmpty == true` 时；而显示 tips 的条件要求 `!keepPrevResultWhenEmpty`，两者
互斥 —— `showTipsView:YES` 在 Easydict 已是不可达分支，`disableTipsView` 是死开关。Scoco 的
`EZWindowManager` 没有这段规范化，其 tips 分支仍可达，这是该提交在 Scoco 成立、在 Easydict 只
剩清理价值的原因。因此本次移植的实际行为变化只有一处：OCR 失败提示从带 FAQ 按钮的 tips 卡片
降级为 Toast（用户已确认接受）。

`updateQueryTextAndParagraphStyle:` 内的 `[self focusInputTextView]` 按 B 方案保留。原代码是
`[self showTipsView:NO completion:^{ [self focusInputTextView]; }]`，而 `showTipsView:NO` 在
`isTipsViewVisible == NO` 时走早返回分支直接执行 completion，即 tips 从未显示过的实际行为就是
「直接调用 `focusInputTextView`，不 reload」；保留该调用是行为等价的，且避免了截图 OCR 异步回填
文本这条路径失去唯一聚焦来源。注释同步改写为不再引用已移除的机制。

### 验证

- `jq -e . Easydict/App/Localizable.xcstrings`：通过；删除仅按行移除，未触发全文件重排。
- `git diff --check`：无空白错误。
- `plutil -lint Easydict.xcodeproj/project.pbxproj`：OK；`grep` 确认无悬空引用。
- 仓库级残留检查：`EZTableTipsCell`、`EZTipsCellType`、`showTipsView`、`disableTipsView`、
  `isTipsViewAtRow`、`isCustomTipsType`、`tipsCell*`、9 个 `tips_*` 键与
  `setting.advance.disable_tips_view` 均已无引用（仅计划文档作为描述提及）。
- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath <agent_dd>`：
  `** BUILD SUCCEEDED **`（exit 0），并自动清理陈旧产物
  `Objects-normal/arm64/EZTableTipsCell.o`。
- `xcodebuild test -only-testing:EasydictTests/ReverseTranslationTests`：`** TEST SUCCEEDED **`
  （7 tests in 1 suite）。该 suite 覆盖 `EZBaseQueryViewController` 的语言反转逻辑，通过 KVC
  访问私有协作者，不触碰本次改动的表格行映射与 OCR 错误路径，因此结果只证明编译与既有行为未回归，
  **不构成新增行为的功能验证**。
- 手动检查：未执行真机运行验证（需人工确认截图 OCR 失败时的 Toast 可见性、取词浮窗窗口高度与
  结果行偏移、输入框聚焦与全选行为）。

### 受影响文件

- `Easydict/objc/ViewController/Cell/EZTableTipsCell.h`（删除）
- `Easydict/objc/ViewController/Cell/EZTableTipsCell.m`（删除）
- `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.h`
- `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.m`
- `Easydict/objc/ViewController/Window/WindowManager/EZWindowManager.m`
- `Easydict/Swift/Feature/Configuration/Defaults.Keys+Extension.swift`
- `Easydict/Swift/Feature/Configuration/MyConfiguration.swift`
- `Easydict/Swift/View/SettingView/Tabs/TabView/AdvancedTab.swift`
- `Easydict/App/Localizable.xcstrings`
- `Easydict.xcodeproj/project.pbxproj`

### 后续事项

- 恢复 Scoco 侧被同批删除的 `[self focusInputTextView]`（用户明确提出的后续项）。
- 需要真机确认 OCR 失败 Toast 与浮窗行偏移；现有测试不覆盖查询窗口的表格行映射与 OCR 错误路径。
- 老用户 UserDefaults 会留下无引用的孤儿键 `disableTipsViewKey`，无害，不做迁移。
