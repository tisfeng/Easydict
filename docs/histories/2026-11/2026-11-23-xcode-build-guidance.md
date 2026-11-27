## 2026-11-23 | 任务：更正源码构建的 Xcode 要求

**Links:** [PR #1274](https://github.com/tisfeng/Easydict/pull/1274)、
[Apple 的 Xcode 27 发布说明](https://developer.apple.com/documentation/Xcode-Release-Notes/xcode-27-release-notes)

### 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-6
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

### 用户请求

更正中英文构建及翻译指南中的 Xcode 版本，补充 Xcode 27 的主机要求。

### 变更

- 中英文开发者构建指南指引开发者使用 Xcode 27 和 CocoaPods，并说明构建主机需要 Apple 芯片和
  macOS Tahoe 26.6 或更高版本。
- 中英文翻译指南的安装步骤更新为 Xcode 27，继续链接到对应语言的开发者构建指南。

### 设计意图

Xcode 26.6 的 CI 构建在 `actool` 编译仍由 Easydict target 引用的图标资源时失败，而
`dev` 的计划构建使用 Xcode 27.1 成功。主机要求写在开发者构建章节。应用的最低部署版本为 macOS 13.0。

### 验证

- 静态核对四份指南与 CI 工具链，旧指南检查失败，更新后通过。两份构建指南的主机要求检查通过。
- Markdown 格式、相对链接、锚点和 `git diff --check` 检查通过。
- 本地未运行应用构建或测试。

### 受影响文件

- `docs/user-docs/en/GUIDE.md`
- `docs/user-docs/en/How-to-translate-Easydict.md`
- `docs/user-docs/zh/GUIDE.md`
- `docs/user-docs/zh/How-to-translate-Easydict.md`

### 后续事项

- None
