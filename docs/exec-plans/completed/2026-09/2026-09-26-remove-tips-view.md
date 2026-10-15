# 移植 Scoco 提交：移除废弃的 TipsView

- 状态：completed
- 创建日期：2026-09-26
- 负责人：tisfeng
- 关联 Issue/PR：Scoco 提交 `b3b143ef4`（refactor(query-window): 移除废弃的 TipsView）

## 执行上下文

- **Agent Name:** `Mavis`
- **Model:** `deepseek-flash`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

## 背景

Scoco 提交 `b3b143ef4` 移除了查询窗口的 TipsView：删除 `EZTableTipsCell`、`disableTipsView`
配置项、9 个 `tips_*` 本地化键，并把 OCR 错误提示改为 Toast。该提交在 Easydict 上的落点几乎
一一对应，但不能直接 cherry-pick，原因有两点：

1. Scoco 提交只删了 `disableTipsView` 的**定义**，它的 UI 开关与本地化键在 Scoco 是由
   `ed1d18a2b`、`bc23f1768` 两个独立提交移除的；Easydict 侧这三处都还在，若只照搬本提交会留下
   「开关存在但永远无效」的半成品。
2. Easydict 的 `EZWindowManager.m` 已在 `eedc89391` 把空文本规范化收窄到 `isSelectionQuery`，
   而显示 tips 的条件要求 `!keepPrevResultWhenEmpty`，两者互斥 —— 即 `showTipsView:YES` 在
   Easydict 已是不可达分支，`disableTipsView` 是死开关。Scoco 的 `EZWindowManager` 没有这段
   规范化，其 tips 分支仍是活的，这是两个仓库的既有分叉。

因此在 Easydict 上，本次移植的实际行为变化只剩一处用户可见项：**OCR 失败提示从带
FAQ 按钮的 tips 卡片降级为 Toast**。

## 目标与范围

- 目标结果：Easydict 查询窗口不再包含 TipsView 相关状态、表格行实现、配置项与专用本地化；
  OCR 失败仍通过 Toast 给出可见反馈。
- 允许修改路径：
  - `Easydict/objc/ViewController/Cell/EZTableTipsCell.h`、`.m`（删除）
  - `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.h`、`.m`
  - `Easydict/objc/ViewController/Window/WindowManager/EZWindowManager.m`
  - `Easydict/Swift/Feature/Configuration/Defaults.Keys+Extension.swift`
  - `Easydict/Swift/Feature/Configuration/MyConfiguration.swift`
  - `Easydict/Swift/View/SettingView/Tabs/TabView/AdvancedTab.swift`
  - `Easydict/App/Localizable.xcstrings`
  - `Easydict.xcodeproj/project.pbxproj`
- 同任务 history：`docs/histories/2026-09/2026-09-26-remove-tips-view.md`
- 用户限制：
  - 保留 `updateQueryTextAndParagraphStyle:` 中的 `[self focusInputTextView]`（B 方案），本次不夹带
    聚焦时序变化。
  - `disableTipsView` 彻底移除（UI + 属性 + Defaults key + 本地化键四件套）。
- 非目标：
  - 不恢复 Scoco 侧被同批删掉的 `[self focusInputTextView]`（另行处理）。
  - 不新增或扩写测试（仓库规则：未获授权不新增测试）。
  - 不做 Objective-C → Swift 迁移，不重构查询窗口其它逻辑。
- 验收标准：
  - 仓库内不再有 `EZTableTipsCell`、`EZTipsCellType`、`showTipsView`、`disableTipsView`、
    `tipsCell` 引用，工程文件无悬空引用。
  - `xcodebuild build` 通过。
  - 截图 OCR 失败时 Toast 可见；取词浮窗行偏移与窗口高度正确；输入框聚焦/全选行为不变。

## 工作计划

1. 删除 `EZTableTipsCell.h` / `EZTableTipsCell.m`，并从 `project.pbxproj` 移除对应的
   build file、file reference、group children 与 Sources 引用（共 4 处）。
2. `EZBaseQueryViewController.h`：移除 `#import "EZTableTipsCell.h"` 与 `showTipsView:` 声明。
3. `EZBaseQueryViewController.m`：移除 cell id、`tipsCell`/`tipsCellType`/`tipsCellContent`/
   `isTipsViewVisible`/`tipsCellIndex` 属性、三个 `showTipsView:` 方法、`isCustomTipsType`、
   `isTipsViewAtRow:`；简化 `updateWindowConfiguration:` 的索引计算；清理 `startOCRImage:`、
   `viewForTableColumn:`、`heightOfRow:`、enter/clear 回调、`resultCellOffset` 中的 tips 分支；
   把 OCR 错误提示改为 `EZToast`，同时保留 `[self focusInputTextView]`。
4. `EZWindowManager.m`：移除 nil-text 分支中的 `showTipsView:YES` 调用块。
5. 彻底移除 `disableTipsView`：`Defaults.Keys+Extension.swift` 的 key、`MyConfiguration.swift` 的
   属性、`AdvancedTab.swift` 的 Toggle 与 `@Default`。
6. 删除 9 个 `tips_*` 本地化键与 `setting.advance.disable_tips_view` 键。
7. 验证：`jq -e .` 校验 xcstrings、`git diff --check`、`xcodebuild build`。
8. review 技能审查，修复有效 finding 后重新验证。
9. 写 history，创建本地提交。

## 风险与决策

- **OCR 错误提示降级（用户已确认接受）**：`EZTipsCellTypeErrorTips` 是当前唯一活路径，由 Apple OCR
  失败且未启用 Youdao OCR 时触发（`DetectManager.handleOCRResult` 透传 error）。原卡片含
  `tips_solve` / `tips_more` 两个跳转 FAQ 的按钮，改为 Toast 后这两个入口消失，属用户可见的
  信息量下降；技术上无风险，且 `EZToast` 与 `dispatch_block_on_main_safely` 在本文件已存在。
- **保留 `[self focusInputTextView]`（B 方案）**：Scoco 整块删除了该调用。该块在 tips 未显示时本就
  直接执行 completion，即聚焦逻辑是设置新文本后的唯一聚焦来源；截图 OCR 异步回填文本这条路径
  没有别的聚焦入口。本次只删 tips 判断，保留聚焦调用，使改动范围严格限定为「移除 TipsView」。
- **孤儿 UserDefaults 键**：老用户配置中会留下 `disableTipsViewKey`，无引用、无害，不做迁移。
- **工程文件格式**：`project.pbxproj` 刚由 `70f20d456` 按 Xcode 27.2 重新序列化（isa-first、
  `objectVersion = 55`）。只删目标行，不顺带重排或改格式。

## 进度

- [x] 计划创建
- [x] 步骤 1-6 源码与本地化改动
- [x] 步骤 7 验证
- [x] 步骤 8 review
- [x] 步骤 9 history 与提交

## 验证

- `jq -e . Easydict/App/Localizable.xcstrings`：通过；删除仅按行移除，未触发全文件重排。
- `git diff --check`：无空白错误。
- `plutil -lint Easydict.xcodeproj/project.pbxproj`：OK；grep 确认无悬空引用。
- 仓库级残留检查：`EZTableTipsCell`、`EZTipsCellType`、`showTipsView`、`disableTipsView`、
  `isTipsViewAtRow`、`isCustomTipsType`、`tipsCell*`、9 个 `tips_*` 键与
  `setting.advance.disable_tips_view` 均已无引用。
- `xcodebuild build`：`** BUILD SUCCEEDED **`，并自动清理陈旧产物 `EZTableTipsCell.o`。
- `xcodebuild test -only-testing:EasydictTests/ReverseTranslationTests`：`** TEST SUCCEEDED **`
  （7 tests）。该 suite 经 KVC 访问私有协作者、不覆盖本次改动的表格行映射与 OCR 错误路径，
  故只证明编译与既有行为未回归，不构成新增行为的功能验证。
- review（`review` 技能）：无 findings。重点核查了「OCR 错误分支不再调用
  `resetQueryAndResults` 是否残留旧结果」——两条 OCR 入口（`showFloatingWindowWithOCRImage:`
  经 `resetTableView:`、`retryQueryWithLanguage:` 经 `closeAllResultView:`）都在进入错误分支前
  已清结果，故无回归。
- 未验证：真机运行（截图 OCR 失败 Toast 可见性、浮窗窗口高度与结果行偏移、输入框聚焦与全选）。

## 完成条件

- 验收标准全部满足：已完成。
- `xcodebuild build`、`jq -e .`、`git diff --check` 通过：已完成。
- review 通过，无待修复 finding：已完成。
- history 已写入，本地提交已创建：已完成。
- plan 归档到 `docs/exec-plans/completed/2026-09/`：已完成。
