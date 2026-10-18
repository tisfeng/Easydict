## 2026-10-19 | 任务：处理 Pods 的 Xcode 推荐设置提示

**Links:** [执行计划](../../exec-plans/completed/2026-10/2026-10-19-xcode-recommended-settings.md)、[Scoco 参考提交](https://github.com/iftechio/Scoco/commit/a43fdba57ff834b428e30e44839dc73f02daf67a)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

参考 Scoco 的 a43fdba57，解决截图中的 Xcode 推荐设置提示。

### 变更

- Podfile 固化已审阅的 `LastUpgradeCheck = 2720`，与当前 Xcode、主工程和 scheme 一致。
- 显式保留 `ENABLE_MODULE_VERIFIER = NO`，避免重新安装 Pods 丢失旧依赖的兼容策略。
- CocoaPods 重新生成 Pods 工程升级标记及两份锁文件的 Podfile checksum。
- 记录执行计划与验证；主工程和 scheme 无最终差异。

### 设计意图

适配 Scoco 已验证的保留兼容配置方案。当前主工程已记录 Xcode 27.2，因此只补齐 Pods 的升级记录；不机械回退到参考提交的 27.1。保持固定已审阅版本，未来 Xcode 的推荐项仍需重新评估。

已审阅推荐项覆盖 Asset Catalog、架构、部署目标、Dead Code Stripping、Module Verifier、Swift 嵌入、symbol stripping、String Catalog 和命令行并行化。全部取消勾选，保留现有构建策略与 macOS 13.0 Pods 兼容目标。

### 验证

- 初始基线：`4fba37b1edbc809dfaaf82d76ca74447080d8c94`，分支 `dev`，工作树与索引干净。
- `ruby -c Podfile`、`pod install --no-repo-update`（CocoaPods 1.16.2）成功。
- Pods 工程完整 plist 对比：仅升级标记改变，全部 project/target build settings 与基线一致；依赖版本、spec checksum、原工具链路径处理保留。
- Podfile SHA-1 与两份锁文件 checksum 一致，锁文件逐字节相同。
- Xcode 中取消全部推荐项并点击 Done 后，Issue Navigator 已无推荐设置警告，原 Debug 实例继续运行。
- Debug arm64 构建成功；SwiftLint 检查 430 个文件，0 violations；产物通过严格签名校验。
- Release 通用架构构建成功，包含 arm64、x86_64，最低 macOS 版本均为 13.0；严格签名校验通过，SwiftLint 为 430 个文件、0 violations。
- Release 命令临时覆盖 `DEBUG_INFORMATION_FORMAT=dwarf` 和专用空 `DWARF_DSYM_FOLDER_PATH`；日志确认因 dSYM 缺失跳过 Sentry 上传。此验证不覆盖 dSYM 生成和上传，仓库发布配置保持不变。
- 按 review 技能审查基线到四个实现文件的完整 raw diff、Podfile 上下文、安装结果及所有 Pod 配置，并复核 SHA-256 快照：无有效 finding，当前最小实现足够。
- 最终 `git diff --check`、锁文件一致性、升级标记和 build settings 检查通过。
- 未新增或扩写测试，未运行测试宿主、功能回归、Intel 实机或 Archive/公证验证。

### 受影响文件

- `Podfile`
- `Podfile.lock`
- `Pods/Manifest.lock`
- `Pods/Pods.xcodeproj/project.pbxproj`
- `docs/exec-plans/completed/2026-10/2026-10-19-xcode-recommended-settings.md`
- `docs/histories/2026-10/2026-10-19-xcode-recommended-settings.md`

### 后续事项

- Release 有 3 条 `target atom is ambiguous` 链接器警告；Debug、Release 均有 App Intents metadata extraction skipped 提示，本次未定位或修复。
- Xcode 中既有 ResponsesAPI 字符串转换 lint 警告不属于本次工程配置修复。
