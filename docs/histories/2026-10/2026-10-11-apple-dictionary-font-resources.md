## 2026-10-11 | 任务：修复 Apple Dictionary 图标字体资源

**Links:** [PR #1351](https://github.com/tisfeng/Easydict/pull/1351)、[计划](../../exec-plans/completed/2026-10/2026-10-11-apple-dictionary-font-resources.md)

### 执行上下文

- **Agent Name:** `Codex`（首轮）；`Claude Code`（字体大小上限）
- **Model:** `GPT-6`（首轮）；`claude-opus-5-5`（字体大小上限）
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

修复朗文词典在 Easydict 中显示方框、系统词典中显示正常的发音图标，复用当前本地分支。
随后按 review 结论修复大体积正文字体被整体嵌入的问题。

### 变更

- 在内联 `@font-face` 声明中支持带引号和不带引号的字体 URL，以及多个字体来源。
- 将词典内 TTF、OTF、WOFF、WOFF2 字体嵌入 data URL。
- 音频与字体共享资源解析、缓存和大小限制，保留 URL scheme、网络路径、目录越界及符号链接保护。
- 字体单文件嵌入上限为 512 KB；更大的正文字体保留原 URL，音频仍沿用 8 MB 上限。大小检查移到缓存
  读取之前，使较小上限同样约束已缓存资源。
- 新增测试覆盖小字体嵌入，以及超限字体、缺失字体、非字体扩展名和 `@font-face` 外 URL 保持原样。

### 设计意图

真实朗文 `test` 词条使用 `lm5pp_icomoon` 字体的 `\ea27` 绘制喇叭，相对字体路径在 `iframe srcdoc` 与
`baseURL:nil` 的加载方式下不可用。音频绝对路径修复不会处理字体。将字体同样嵌入 HTML，避免放宽
WebView 的本地文件访问权限；字体类型限制只应用于新字体路径，不改变既有音频匹配行为。

`现代汉语词典` 的 `hei_xdhy.woff` 与 `song.woff` 各约 4.3 MB，整体嵌入会让单个词条 HTML 从约 11.7 KB
增至约 11.5 MB，并占用每次查询 16 MB 嵌入预算的约 70%。图标字体只有 KB 级，因此只嵌入小字体；
大字体在 macOS 26 及以前仍可从文件加载，在 macOS 27 上回退为系统字体，与本任务前一致。

### 验证

- `xcodebuild build-for-testing`：使用 checkout 对应的独立 Easydict-Agent DerivedData，成功。
- `xcodebuild test-without-building -only-testing:EasydictTests/AppleDictionaryTests`：4 个测试通过。
- SwiftLint：使用工程解析的 SwiftLint binary，针对生产文件 `--strict --no-cache` 检查，0 violations。
- `swiftc -frontend -parse` 与 `git diff --check`：通过。
- 从本机 Dictionary Services 提取真实朗文 `test` 词条，使用生产资源嵌入方法的源码提取程序处理：
  2 份字体、39 处音频引用全部嵌入，图标字体的原相对 URL 不再残留。此诊断不替代应用单元测试。
- 在 macOS 27.0.1 的 WKWebView 中用 `iframe srcdoc`、`baseURL:nil` 加载同一真实词条：
  原始 HTML 两份字体均为 `NetworkError`，处理后两份字体均为 `loaded`。
- Review：以首次写入前的 `251e302f3c8d6296749e2dc5db4421675660af3e` 为基线，复核完整 diff、
  HTML 嵌入调用链、反向范围替换、缓存及路径边界；未发现有效 finding。共用资源嵌入方式足以覆盖本次目标。
- 已启动新构建的调试版；界面自动化读取窗口连续超时，未完成应用内图标截图与实际播放点击验证。
- 字体大小上限：`xcodebuild test -only-testing:EasydictTests/AppleDictionaryTests` 共 5 个测试（含参数化
  用例）通过；临时将上限改回 8 MB 时新测试按预期失败，恢复后通过。SwiftLint 0 violations，
  `git diff --check` 通过。
- 字体大小上限：用修改后的嵌入函数处理本机真实词条，`现代汉语词典` `好` 保持约 11.7 KB、不占预算；
  朗文 `test` 仍嵌入 2 份字体与 39 处音频，输出与修改前一致。

### 受影响文件

- `Easydict/Swift/Service/Dictionary/AppleDictionary/AppleDictionary.swift`
- `docs/exec-plans/completed/2026-10/2026-10-11-apple-dictionary-font-resources.md`
- `docs/histories/2026-10/2026-10-11-apple-dictionary-font-resources.md`
- `EasydictTests/Service/AppleDictionaryTests.swift`

### 后续事项

- 在修复后的调试版中查询朗文 `test`，人工确认图标显示并点击英美及例句发音。
