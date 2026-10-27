## 2026-10-18 | 任务：默认收起 Anki Connect 详细配置（已撤回）

**Links:** None

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

缩小高级设置中 Anki Connect 的默认占用空间，保留启用开关，将详细配置默认折叠。用户实测后认为展开布局不合适，明确要求撤回，并仅讨论参照 Scoco SheetChevronRow 的二级窗口方案。

### 变更

- 已按用户要求撤回 `d3618bdc8b8ac80795e6e4fa3e8620fde509422c` 中的视图与本地化修改，恢复修改前版本；保留本记录说明撤回结果。二级窗口方案尚未实现。

原实现（已撤回）：

- 在启用开关下增加原生 DisclosureGroup，收纳端点、牌组、笔记类型、字段映射与预览。
- 展开状态独立于功能开关；从关闭切换到开启时展开，关闭设置窗口后重置为收起。
- 为“连接与卡片设置”补齐现有六种语言的文案。

### 设计意图

使用视图局部状态管理临时展开状态，保持既有配置与 Anki 功能独立。仅在所属设置窗口关闭时重置，避免切换标签或关闭其他窗口影响展开状态。本次属于局部低风险 UI 变更，无需单独执行计划。

### 验证

撤回验证：

- 视图与 String Catalog 与原提交的 parent 逐文件比对一致；移除折叠状态、窗口通知监听及新增文案。
- 撤回后相同配置的 `xcodebuild build`：通过；`git diff --check` 与 String Catalog JSON 检查通过。
- 审查撤回差异及文件字节一致性：未发现有证据的缺陷；仅恢复已知基线，无新增产品逻辑。

原实现验证：

- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath <checkout 专属 agent DerivedData>`：通过（Debug）；包含仓库 SwiftFormat 构建步骤。
- `git diff --check` 与 `jq -e . Easydict/App/Localizable.xcstrings`：通过。
- String Catalog 内容比对：仅新增一个 key，覆盖现有六种 locale，所有原有条目不变。
- 按 review 技能检查本任务相对 `e7d28a35d875a06f1afc36ea7db679e1d32049e2` 的代码与本地化差异：未发现有证据的缺陷；局部 DisclosureGroup 与独立状态已足够，无需额外偏好设置或弹窗。
- 手动检查：尝试启动新构建并连接界面，但界面工具多次超时，未完成点击、键盘及布局验证；构建通过不代表交互验证通过。
- 未新增测试；现有测试未发现覆盖该设置折叠交互的用例，未运行不相关的单元测试。

### 受影响文件

- `Easydict/Swift/View/SettingView/Tabs/TabView/AdvancedTabAnkiSection.swift`
- `Easydict/App/Localizable.xcstrings`
- `docs/histories/2026-10/2026-10-18-collapse-anki-settings.md`

### 后续事项

- 二级窗口方案待用户确认；本次没有实现新方案。
