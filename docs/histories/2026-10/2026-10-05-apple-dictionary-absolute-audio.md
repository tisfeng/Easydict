## 2026-10-05 | 任务：修复 Apple Dictionary 绝对音频路径

**Links:** [#1308](https://github.com/tisfeng/Easydict/issues/1308)、[#1322](https://github.com/tisfeng/Easydict/issues/1322)

### 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `Unknown`
- **Environment:** `macOS 26.5.2 / Xcode 26.6 (17F113)`

### 用户请求

修复 Apple Dictionary 本地音频无法嵌入的问题，并补充路径处理的回归测试。

### 变更

- 允许词典 Contents 内的绝对音频文件路径参与现有 data URL 嵌入流程。
- 继续拒绝网络路径及 URL scheme；绝对路径与相对路径均经过符号链接解析和目录边界检查。
- 从公开 HTML 查询入口增加合法路径、目录穿越、相邻同前缀目录与符号链接越界的回归用例。

### 设计意图

词典条目可能使用绝对路径引用本地音频，旧 guard 会直接拒绝该路径，导致音频无法嵌入 HTML。
统一支持当前词典 Contents 内的绝对与相对音频路径，复用原有安全检查、资源大小限制和嵌入缓存。

### 验证

- 源码提取的临时 Swift 验证程序：修复前 16 个场景中 4 个合法绝对路径失败，修复后全部通过。
  使用系统 `System.FilePath`，覆盖实际音频嵌入方法和字符串处理；属于补充验证，不替代应用测试。
- `swiftc -frontend -parse`：生产文件与测试文件语法检查通过。
- SwiftLint 使用 `--use-script-input-files --config .swiftlint.yml --strict --no-cache`：
  仅检查生产文件与测试文件，0 violations。
- SwiftFormat 0.63.0 使用仓库 `.swiftformat` 配置，仅格式化新增测试的声明分组标记；
  `--lint` 复查生产文件与测试文件，0/2 files require formatting。
- `git diff --check`：通过。
- Review：以干净的 `cfda6e2f43741a3210a290e422846f1d83742d38` 为基线，检查调用链、
  路径边界和新增测试，未发现有效 finding；现有嵌入流程足以承载本次修复。
- `xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict -destination 'platform=macOS,arch=arm64'
  -derivedDataPath <checkout-derived Easydict-Agent> -only-testing:EasydictTests/AppleDictionaryTests
  -disableAutomaticPackageResolution -skipPackageUpdates EASYDICT_RELEASE_PACKAGING=YES`：构建失败，测试未执行。
  `actool` 编译现有 `Easydict-26.icon`、`Easydict-27.icon` 和 `Assets.xcassets` 时抛出
  `attempt to insert nil object from objects[0]`。图标资源不属于本次变更范围。

### 受影响文件

- `Easydict/Swift/Service/Dictionary/AppleDictionary/AppleDictionary.swift`
- `EasydictTests/Service/AppleDictionaryTests.swift`
- `docs/histories/2026-10/2026-10-05-apple-dictionary-absolute-audio.md`

### 后续事项

- 解决本机构建工具的图标编译异常后，运行 AppleDictionaryTests；构建验证尚未完成。
- 在 macOS 27 上使用包含本地音频的真实词典复测发音按钮；本机没有验证该系统上的实际播放。
