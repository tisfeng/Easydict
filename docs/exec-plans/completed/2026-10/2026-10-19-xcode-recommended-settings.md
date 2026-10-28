# 处理 Pods 的 Xcode 推荐设置提示

- 状态：completed
- 创建日期：2026-10-19
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

## 背景

用户截图显示 Pods 的推荐设置对话框，要求参考 Scoco 的 a43fdba57。主工程和 scheme 已记录 Xcode 27.2，Pods 的升级标记仍为 1600；现有 Module Verifier 关闭策略未写入 Podfile。

## 目标与范围

- 目标结果：记录已经审阅的 Xcode 27.2 建议，保留 Pods 兼容设置，并在重新安装后持续生效。
- 允许修改路径：`Podfile`、`Podfile.lock`、`Pods/Manifest.lock`、`Pods/Pods.xcodeproj/project.pbxproj` 及本任务 plan/history。
- 同任务 history：`docs/histories/2026-10/2026-10-19-xcode-recommended-settings.md`
- 用户限制：仅本地交付，不进行外部写入。
- 非目标：批量采纳推荐项、升级依赖、修改第三方头文件或事件处理代码。
- 验收标准：Pod 安装保留升级记录与兼容设置；依赖和 build settings 无意外变化；Debug、Release 构建通过。

## 工作计划

1. 将已审阅版本与 Module Verifier 策略固化到 Podfile。
2. 使用锁定的 CocoaPods 安装并比较全部构建设置与依赖。
3. 在 checkout 专用 DerivedData 构建 Debug 和 Release，核对升级标记。
4. 使用 review 审查，记录 history、归档计划并创建本地提交。

## 风险与决策

- 保留 macOS 13.0 Pods 兼容目标、架构、Dead Code Stripping 和 Swift 嵌入策略。
- 使用固定 2720 标记；未来 Xcode 建议需重新审阅，不自动跟随工具版本。
- 主工程和 scheme 已为 2720，无需修改。
- 不运行测试宿主或重启现有 Xcode Debug 实例。

## 进度

- [x] 固化设置并验证 Pod 安装。
- [x] Debug、Release 构建与升级记录检查。
- [x] 审查、history 与归档完成；随本次本地提交交付。

## 验证

- 初始 HEAD：`4fba37b1edbc809dfaaf82d76ca74447080d8c94`，分支 `dev`，初始工作树与索引干净。
- 本机 CocoaPods 1.16.2 与锁文件一致，xcodeproj 1.27.0。

- `pod install --no-repo-update`（CocoaPods 1.16.2）成功；Pods 工程完整 plist 比较确认仅 `LastUpgradeCheck` 从 1600 改为 2720，所有 build settings 与基线一致。
- 主工程的生成器规范化差异与 scheme 的 XML 格式差异已移除；主工程和 scheme 最终与初始 HEAD 一致。
- Ruby 语法、Podfile SHA-1、锁文件逐字节一致性、依赖版本和 spec checksum 对比通过。
- Xcode 推荐项四个分类全部取消勾选，点击 Done 后 Issue Navigator 已无推荐设置警告；原 Debug 实例继续运行。
- Debug arm64 构建成功，SwiftLint 检查 430 个文件，0 violations；仅 App Intents metadata extraction skipped 警告。Debug 产物通过严格签名验证。
- Release 验证使用 `DEBUG_INFORMATION_FORMAT=dwarf` 和专用空 `DWARF_DSYM_FOLDER_PATH`，使现有 Sentry 阶段因 dSYM 缺失跳过上传。未更改仓库发布配置。

- Release `generic/platform=macOS` 构建成功，产物包含 arm64、x86_64，两者 minos 均为 13.0；严格签名验证通过。SwiftLint 检查 430 个文件，0 violations。
- Release 日志确认跳过 Sentry 上传；存在 3 条 `target atom is ambiguous` 链接器警告和 App Intents metadata extraction skipped 提示，未修改链接设置或 App Intents。
- 按 review 技能审查基线到 4 个实现文件的完整 raw diff、Podfile 上下文、所有 Pod 配置和安装结果；内容 SHA-256 与审查快照一致，无有效 finding。固定审阅版本并保留兼容设置的当前方案足以满足目标。
- 未新增或扩写测试，未运行测试宿主、功能回归、Intel 实机或 Archive/公证验证。

## 完成条件

- 范围内验证通过，无未解决的有效 review finding。
- history 记录验证边界，计划归档并完成本地提交。
