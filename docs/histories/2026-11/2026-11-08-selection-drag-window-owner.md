## 2026-11-08 | 任务：防止系统浮层拖动触发旧选区取词

**Links:** [PR #1325](https://github.com/tisfeng/Easydict/pull/1325)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B52)`

### 用户请求

修复 PR #1325 中拖动 macOS 控制中心滑杆仍可能触发旧选区取词的问题，保留点进其他应用后直接拖选的行为。

### 变更

- 外部鼠标按下时记录实际命中窗口所属的进程。识别为拖动后，仅在已知窗口所属进程与当前取词目标不一致时跳过取词。
- 鼠标释放后清理本次拖动的进程记录。无法读取窗口信息时沿用原取词行为。

### 设计意图

在拖动结束时比较进程，让点击后激活的新应用可以成为取词目标。控制中心等系统浮层接收拖动但保持原应用为前台时，不读取原应用的旧选区。

### 验证

- `xcodebuild build`、改动文件的 `swiftformat --lint` 和 `git diff --check` 通过。
- 实测 TextEdit 拖选会显示查询图标。保留选区后拖动控制中心亮度滑杆，选区保留且没有新的 Easydict 查询图标窗口。
- 从 Finder 点入接受首次鼠标事件的 AppKit 测试窗口并拖选，确认选区更新且查询图标显示。

### 受影响文件

- `Easydict/Swift/Utility/EventMonitor/Core/EventMonitor.swift`

### 后续事项

- None
