## 2026-11-10 | 任务：升级 Sparkle 安全修复版本

**Links:** [执行计划](../../exec-plans/completed/2026-11/2026-11-10-sparkle-security-update.md) · [Sparkle 2.9.2](https://github.com/sparkle-project/Sparkle/releases/tag/2.9.2) · [Sparkle 2.10.1](https://github.com/sparkle-project/Sparkle/releases/tag/2.10.1)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B52)`

### 用户请求

继续修复 Dependabot 报告的 Sparkle 告警。

### 变更

- Xcode 工程的 Sparkle 最低版本从 `2.6.4` 提升至 `2.9.2`。工作区锁文件从 `2.8.1` 更新至 `2.10.1`。

### 设计意图

Sparkle 2.9.2 包含 #16 的增量更新修复和 #17 的安装器 XPC 校验修复。工程约束排除受影响版本，锁文件采用验证过的稳定版。Sparkle 2.10.1 支持 macOS 12 起，Easydict 继续部署到 macOS 13 起。

### 验证

- Xcode 按锁文件解析，macOS arm64 Debug 干净构建通过，内嵌 Sparkle 2.10.1，应用代码签名验证通过。增量构建曾使用旧模块缓存，干净构建排除该问题。
- 使用同一框架和公开 appcast 的独立探针，验证稳定通道与 Beta 通道分别选中 build 69 和 build 70。
- 用新版工具和临时密钥生成 Beta appcast，验证了 macOS 13.0 下限、归档长度和 EdDSA 签名。发布脚本的 8 项公开产物测试通过。
- 工程与锁文件格式检查及 `git diff --check` 通过，审查未发现可操作问题。工程文件中既存的本地差异排除在提交之外。

### 受影响文件

- `Easydict.xcodeproj/project.pbxproj`
- `Easydict.xcworkspace/xcshareddata/swiftpm/Package.resolved`

### 后续事项

- Debug 菜单栏实例的更新入口无法通过界面工具访问，未取得截图。真实发布版的下载与安装仍待端到端验证。
