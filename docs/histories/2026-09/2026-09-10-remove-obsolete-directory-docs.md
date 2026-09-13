## 2026-09-10 | 任务：清理废弃目录文档

### 用户请求

删除代码目录中不再需要的说明和配图，保留词典、MDict、OCRImages 和 DarkReader 文档及许可证。

### 变更

- 删除 ClaudeCode、CodexCLI 测试目录说明。
- 删除 AppleScript、WordResultView 的目录概览和架构图。
- 清理对应 Xcode 文件及 group 引用，保留词典和 MDict 的文档与架构图。

### 设计意图

按用户指定范围清理旧目录文档，不改变产品代码、测试或运行时资源。

### 验证

- `git diff --check`：通过。
- `plutil -lint Easydict.xcodeproj/project.pbxproj`：通过。
- 删除文件引用检查：现行文件中无残留引用；保留文档与 SVG 无差异。
- 未运行构建或测试，本次仅删除文档、说明配图和工程导航引用。

### 受影响文件

- `EasydictTests/Service/ClaudeCode/README.md`
- `EasydictTests/Service/CodexCLI/codex-cli-overview.md`
- `Easydict/Swift/Utility/AppleScript/apple-script-overview.md`
- `Easydict/Swift/Utility/AppleScript/apple-script-architecture.svg`
- `Easydict/objc/ViewController/View/WordResultView/word-result-view-overview.md`
- `Easydict/objc/ViewController/View/WordResultView/word-result-view-architecture.svg`
- `Easydict.xcodeproj/project.pbxproj`

### 后续事项

- 无。
