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
