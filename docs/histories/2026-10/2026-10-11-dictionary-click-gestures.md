## 2026-10-11 | 任务：修复词典网页点击被表格手势拦截

**Links:** [PR #1351](https://github.com/tisfeng/Easydict/pull/1351)、[计划](../../exec-plans/completed/2026-10/2026-10-11-dictionary-click-gestures.md)、[Apple TN3212](https://developer.apple.com/documentation/technotes/tn3212-adopting-gesture-recognizers-for-sidecar-touch-support)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

复用当前分支，修复调查已确认的朗文发音点击失效。

### 变更

- 查询结果使用 EZQueryTableView，在 macOS 27 及以后为表格单击手势安装局部代理。
- 命中 WKWebView 的点击让表格单击手势退出识别；其他事件与可选代理方法转发原代理。
- 在手势添加、窗口挂载与布局时检查安装，避免重复包装，并覆盖手势重建。
- 同步 Xcode 工程；不修改现有音频嵌入或播放逻辑，不纳入既有调试脚本差异。

### 设计意图

原生鼠标事件已命中 WKWebView，但表格单击手势使 iframe 无法收到 click。真实页面移出表格、移除该手势、仅过滤网页区域三个对照均恢复播放，恢复原代理则再次失效。
采用 Apple TN3212 建议的候选手势过滤阶段处理冲突，避免删除系统手势、修改私有 action 或替换播放器。原代理转发保留非网页区域的决策。

### 验证

- 独立 Easydict-Agent DerivedData 下 `xcodebuild build -scheme Easydict -configuration Debug`：成功。
- 同一配置 `xcodebuild test -only-testing:EasydictTests/AppleDictionaryTests`：5 个测试通过。未新增测试。
- 新构建真实坐标点击：英音 0.7053 秒、美音 0.5224 秒、例句 2.5339 秒均触发 iframe click 和 playing；滚动后再次点击仍成功。
- 播放期间的系统音频电平采样记录 160 个非零 buffer；采样为整个系统输出，仅作为播放日志的补充证据。
- 结果折叠与原生按钮展开完成，展开后内容和滚动位置保留。
- 运行时重复 layout 后代理实例不变；临时表格释放后弱引用集合为空，未发现表格循环引用。
- `git diff --check`：通过。
- Review：基线 `f670cbf89955aad0b9cc7c28b3dea6618a45fd4b`，仅本任务新增 4 个生产/工程文件差异及任务文档，排除初始 AppleDictionary.swift 差异。检查命中范围、原代理转发、初始化、重复布局与平台限制；未发现有效 finding。局部代理比全局删除手势更符合保留现有交互的目标。

### 受影响文件

- `Easydict/objc/ViewController/Cell/EZQueryTableView.h`
- `Easydict/objc/ViewController/Cell/EZQueryTableView.m`
- `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.m`
- `Easydict.xcodeproj/project.pbxproj`
- 本任务 plan 和 history。

### 后续事项

- macOS 26 及以前未运行实机验证，代码通过 availability 保持原表格手势行为。
- 首次激活窗口、Sidecar 直接触摸、链接跳转与选择复制未完成专项验证；本次复现与验收覆盖鼠标点击发音。
