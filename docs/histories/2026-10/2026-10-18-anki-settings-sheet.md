## 2026-10-18 | 任务：将 Anki Connect 配置移入二级 Sheet

**Links:** [执行计划](../../exec-plans/completed/2026-10/2026-10-18-anki-settings-sheet.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

按照已确认的方案，以 Scoco SheetChevronRow 为交互参考，将 Anki Connect 改为单行入口及二级 Sheet，并实际检查布局和交互。

### 变更

- 高级页面只保留图标、Anki Connect 名称、启用状态和箭头组成的整行 Button。
- 提取原有配置到独立 Sheet，分组展示连接、卡片和预览；顶部标题及底部完成按钮固定，表单可滚动。
- 补齐新增文案的六种语言及 Xcode 源码引用。

### 设计意图

保持 Defaults 即时保存和原有 Anki 业务逻辑，仅改变设置入口及展示空间。使用原生 Button 支持键盘，Sheet 内部自行关闭；关闭 Anki 功能时仍可编辑配置。

### 验证

- 提取前后 helper 和业务逻辑逐字比对一致。
- Catalog 比对：仅新增五个 key，六种 locale 完整，原有字符串不变。
- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath <checkout-agent-derived-data> -clonedSourcePackagesDirPath <existing-package-cache> -disableAutomaticPackageResolution`：通过（Debug）。首次依赖下载较慢，停止该尝试后复用相同版本的本机 package cache；编译目录始终独立。
- `git diff --check`、`jq -e . Easydict/App/Localizable.xcstrings`、`plutil -lint Easydict.xcodeproj/project.pbxproj`：通过。
- 运行当前 worktree 构建产物（已通过进程路径与 PID 确认），在 macOS 27.0.1、简体中文、深色外观实际检查。
- 单行入口：只显示名称、启用状态、图标和箭头；启用后关闭 Sheet，入口同步显示“已启用”，关闭功能后恢复“未启用”。
- 860 × 620 Sheet 首屏及滚动后的布局检查：字段映射和控件无重叠；新增第三项映射后可继续滚动到预览；标题与完成按钮保持固定。
- 临时修改牌组，关闭并重新打开 Sheet，值保留；关闭 Anki 功能时也可编辑；Esc 关闭仍保留即时编辑。
- 使用有道词典查询 `hello`，成功呈现变量值和 Front/Back 字段预览，长结果可滚动到底，完成按钮不被遮挡。
- “完成”按钮、Esc、Return 关闭通过；文本模板编辑器中的 Return 保持换行，不误触默认完成动作。
- 验证后恢复功能关闭、Default 牌组、Basic 笔记类型、Front={Word} 与 Back={FullResult} 两项映射；移除临时第三项映射。
- 按 review 技能审查本任务相对 `36123e1014bb308b43d99964b716bc444f741bd5` 的最终工作树快照：未发现有证据的缺陷。Sheet 与局部状态足够，无需独立 NSWindow 或额外持久化状态；审查后源码指纹复验一致。
- 未新增测试代码；本次验证覆盖构建与实际 UI 行为，未运行不相关单元测试。未进行向 Anki 写入笔记的验证，其他 macOS 版本及语言布局未进行运行检查。

### 受影响文件

- `Easydict/Swift/View/SettingView/Tabs/TabView/AdvancedTabAnkiSection.swift`
- `Easydict/Swift/View/SettingView/Tabs/TabView/AnkiConnectSettingsView.swift`
- `Easydict/Swift/View/SettingView/Tabs/TabView/SheetChevronRow.swift`
- `Easydict/App/Localizable.xcstrings`
- `Easydict.xcodeproj/project.pbxproj`
- `docs/exec-plans/completed/2026-10/2026-10-18-anki-settings-sheet.md`
- `docs/histories/2026-10/2026-10-18-anki-settings-sheet.md`

### 后续事项

- None
