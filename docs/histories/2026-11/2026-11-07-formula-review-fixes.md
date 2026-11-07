## 2026-11-07 | 任务：修复公式截图 PR 审查意见并同步上游

**Links:** [PR #1391](https://github.com/tisfeng/Easydict/pull/1391) · [执行计划](../../exec-plans/completed/2026-11/2026-11-07-formula-review-fixes.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B52)`

### 用户请求

解决两处上游冲突，修复四条行内审查意见，包含本机公式兼容修复，测试通过后更新原 PR。

### 变更

- 合入上游 dev `3801364f5da5dcb0392a78c6b4e2d84ba22809b2`，两处冲突保留上游截图焦点与清理顺序，同时接回本地保存开关及公式模式入口。
- 数学附件按 TextKit 当前可用栏宽等比缩放，并保留自然尺寸用于窗口扩宽后的重新排版。
- 将 `\boldsymbol` 兼容映射至 SwiftMath 支持的 `\bm`，保留命令边界与原始复制内容。
- 清空、重置和进入文字查询时停止 OCR 加载动画；原有过期 OCR 结果丢弃条件继续生效。
- 从模型返回的原文检测语言，并将与请求提示词一致的目标语言同步到结果、原文模型、界面和历史；原文模型复制保留截图元数据。
- 收藏入口在可编辑输入为空时使用截图原文 Markdown。

### 设计意图

复用上游截图生命周期和本地语言检测，保持一次视觉模型调用。附件通过 TextKit 的布局协商适应宽度，避免修改原始 LaTeX；截图原文继续独立于可编辑输入。语言回写复用当前查询与截图身份检查，防止过期结果覆盖新查询。

### 验证

- `xcodebuild test`：Debug、arm64，隔离 DerivedData，7 个 suite 共 133 项现有测试通过，覆盖 Markdown、Codex 服务/执行器/协调器/托管翻译、OCR QR 与 Apple 语言检测。
- 既有独立渲染检查：inline/display 粗体希腊符号、截图中的式 (12)、分式、代码、金额、未知命令和未闭合公式通过。检查脚本显式启用公式模式。
- TextKit 手动布局测量：260/520/260 点栏宽下，长公式实际 glyph 宽度为 250/510/250 点，缩放后保持完整布局。
- `git diff --check`、`jq -e . Easydict/App/Localizable.xcstrings`：通过。
- 使用仓库 review 技能只读审查相对原 head `f6f45827ac1670a23cf540b16f6890ce19e50328` 的整合结果，以及相对最新 dev 的冲突处理；未发现新增有效 finding。
- OCR 加载、语言回写与收藏路径完成调用链复核；本轮未重复真实截图/收藏 GUI 场景。

### 受影响文件

- `Easydict/Swift/Feature/Screenshot/Screenshot/Screenshot.swift`
- `Easydict/objc/ViewController/Window/WindowManager/EZWindowManager.m`
- `Easydict/Swift/Feature/Markdown/MarkdownRenderer.swift`
- `Easydict/Swift/Model/QueryModel.swift`
- `Easydict/Swift/Service/CodexCLI/CodexCLIService.swift`
- `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.m`
- `Easydict/objc/ViewController/View/Titlebar/EZTitlebar.m`
- 上游 dev 自带的截图、行高、设置和对应文档更新。

### 后续事项

- `10b8667a46aa9fcf0c44954936a404702974a66a` 已推送同一 PR 分支，保留上游 dev 为第二 parent。
- 四条审查意见均已回复修复依据并 resolve：[公式宽度](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4500036292)、[OCR 加载](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4500037118)、[自动语言](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4500037656)、[收藏](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4500038076)。
- PR 说明已更新验证结果并保留原截图；GitHub 确认可合并，等待维护者审核与合并。
