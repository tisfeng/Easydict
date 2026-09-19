## 2026-08-29 | 任务：截图浮层前台时跳过自动取词触发

**Links:** 用户报告（截图双击保存到剪贴板偶发失败）；关联本地 dev 分支 `ca102d5d`（前台误判校验，本仓库尚未推送）

### 用户请求

用户反馈：截图时双击选区将截图保存到剪贴板的操作偶发失败，疑似与 Easydict 冲突，要求查日志定位并解决。

### 变更

- `AppContextProvider` 新增 `overlayHelperIDs` 默认触发排除列表（当前仅 `com.electron.lark.helper`），该类进程处于前台时不响应任何自动取词触发（拖选、双击、三击、Shift 点击、Cmd+A）。
- 新增本 history 记录。

### 设计意图

运行日志（`~/Library/Caches/com.izual.Easydict` MMLogs）显示截图流程中飞书截图浮层进程 `com.electron.lark.helper` 处于前台且不支持 Accessibility（kAXErrorNoValue），Easydict 对拖选和双击各触发一次强制取词：先尝试菜单栏复制，失败后向该进程模拟 ⌘C，并伴随 SelectedTextKit 的"备份 → 复制 → 轮询 → 条件恢复"剪贴板窗口（实测跨度可达 1 秒）。用户双击确认截图时飞书恰好在同一窗口期内写入图片，后续 ⌘C 诱导的写入/清空或备份恢复都会覆盖图片，导致保存偶发失败。

`com.electron.lark.helper` 是 Electron 辅助进程，只承载截图浮层、通知小组件等辅助窗口，其前台状态不意味着用户在其中划词；对它执行强制取词永远不是用户意图。处理方式与既有 `screenMirrorIDs`（投屏宿主的拖拽不是划词）一致：在最前端的事件触发层直接跳过，而不是在强制取词层打补丁，从而避免 AX 查询、延迟任务和剪贴板备份/恢复窗口整体发生。快捷键显式查询路径不受影响。

dev 分支已有的 `ca102d5d`（校验鼠标下窗口归属）针对"前台进程误判"场景，无法覆盖本场景：截图浮层窗口本身就属于 `lark.helper`，归属校验必然通过。两个修复互补。

### 验证

- `git diff --check`：通过。
- 变更规模统计：新增 8 行，低于 `docs/agents/build-and-test.md` 的 100 行 xcodebuild 阈值，未运行 xcodebuild。
- `swiftformat --lint`：本机未安装 swiftformat/swiftlint，未运行；已人工核对缩进与周边代码一致。
- 运行时行为（真实飞书截图双击复制）：未验证，需重新构建并在开启"强制取词"后复现原场景确认。

### 受影响文件

- `Easydict/Swift/Utility/EventMonitor/Core/AppContextProvider.swift`
- `docs/histories/2026-08/2026-08-29-screenshot-overlay-force-get-skip.md`

### 后续事项

- 其他截图工具（如微信截图，其浮层承载于主进程）理论上存在同类竞争，当前无日志证据，未纳入本次最小改动。
- SelectedTextKit 的"备份 → ⌘C → 恢复"窗口对任意第三方剪贴板写入仍存在毫秒级竞争（恢复守卫无法识别备份与动作写入之间夹带的第三方写入），属上游包层面的已知限制。

## 第二轮（2026-08-29 同日）：SelectedTextKit 剪贴板恢复语义加固

用户要求把上列"后续事项"一并处理。经评估，微信类主进程截图浮层无法照搬触发层拉黑（会同时废掉正常划词），根治方案落在 SelectedTextKit 层，同时覆盖所有应用的清空与覆盖两类破坏。

### 变更（hyperdai/SelectedTextKit）

- 分支 `fix/pasteboard-restore-semantics`（基于上游 dev bb42db5），提交 `b72ecda`；已合入 fork main（`839a3cb`），上游 PR：tisfeng/SelectedTextKit#9。
- 恢复判定从单一条件改为三分支：动作产生文本写入且其后无第三方写入时恢复（原行为）；剪贴板被动作改变但当前为"有效空"（无类型或仅空字符串）时恢复——修复"模拟 ⌘C 对空选区复制导致剪贴板被清空"的原生丢失路径；其余情况保留现状——截图图片等第三方新写入不再被过期备份覆盖。
- `initialChangeCount` 基线移动到动作执行前一刻（与 backupItems 之间无异步间隙），压缩第三方写入被误判为动作结果的窗口。
- Easydict 本地 dev 同步：cherry-pick 本任务触发层修复（f9aa6a52）＋ 更新 fork main 锁定（6881df35），使本地构建可同时验证两层修复。

### 已知残余限制

第三方在"动作执行 → 轮询首轮"的毫秒级窗口内写入文本仍会被误认作动作结果并被恢复覆盖；changeCount 无法区分写入者，根治需 marker 类方案（如自有写入打私有 UTI 标记），本轮未实施。

### 验证（第二轮）

- `swift build -Xswiftc -target -Xswiftc arm64-apple-macos13.0`：编译通过（裸 `swift build` 因包内既有 macOS 12 可用性问题失败，与本次改动无关）。
- 运行时行为未验证；本地 dev 构建后按原场景（飞书截图双击复制）回归。

## 第三轮（2026-08-31）：简化默认触发列表构造

- 合并两个禁用 ID 列表的共同 `map`，保持列表顺序、`triggerType` 和后续追加逻辑不变。
- 通过 `swiftformat --lint`、`swiftc -parse` 和 `git diff --check` 验证。
