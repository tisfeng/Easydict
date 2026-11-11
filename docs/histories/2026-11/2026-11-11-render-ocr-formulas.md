## 2026-11-11 | 任务：渲染 OCR 原文和译文中的公式

**Links:** [执行计划](../../exec-plans/completed/2026-11/2026-11-11-render-ocr-formulas.md)

### 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-6
- **Environment:** macOS 27.2 / Xcode 27.2 (27B52)

### 用户请求

保留翻译窗口布局，支持在原文框内预览、编辑和复制 LaTeX，并渲染 DeepL 和 Google 译文中的公式。

### 变更

- 原文框使用同一个滚动区域承载预览和编辑器，通过右键菜单切换。
- 含公式的非流式译文复用现有 Markdown 渲染器和结果卡开关。

### 设计意图

编辑器保留原始文本。预览复用 Markdown 公式附件及选中复制逻辑。

### 验证

- 常规 Debug 测试构建运行了 SwiftFormat，31 项 Markdown 与公式 OCR 测试通过。
- 用用户提供的截图验证原文、DeepL 和 Google 均渲染分式、根号及编号。源码中将 53 改为 54 后，两家译文同步更新。预览复制取回了 LaTeX。
- 复核了视图切换、查询状态和非流式服务渲染条件。字符串目录及 Git 差异检查通过。

### 受影响文件

- `Easydict/Swift/Feature/Markdown/`
- `Easydict/objc/ViewController/` 下的原文框、结果卡与查询窗口控制器。
- `Easydict/App/Localizable.xcstrings`

### 后续事项

- None
