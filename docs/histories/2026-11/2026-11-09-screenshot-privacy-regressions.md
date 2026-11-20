## 2026-11-09 | 任务：修复截图隐私日志并复测审查回归

**Links:** [PR #1391](https://github.com/tisfeng/Easydict/pull/1391) · [执行计划](../../exec-plans/completed/2026-11/2026-11-09-screenshot-privacy-regressions.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B52)`

### 用户请求

修复两处可能写入 OCR 原文的日志，用测试截图检查落盘内容，逐项复测原 PR 的剩余回归。

### 变更

- OCR 段落和行宽诊断只记录策略、尺寸和数量。音频诊断记录服务、错误域和错误码，移除可能包含文本的 URL 及完整错误信息。
- 以字符串内容比较 Swift 模型返回的截图动作，修复普通 OCR、公式重试和等待时的停止按钮。剪贴板图片使用现有的剪贴板 OCR 动作。

### 设计意图

查询模型的动作是字符串值，跨 Swift 和 Objective-C 边界后仍应按内容判断。截图身份继续按原图对象判断。日志保留排障所需的状态，语音请求与缓存逻辑保持原有流程。

### 验证

- Debug arm64 构建成功。现有 14 个套件共 185 项测试通过。`git diff --check` 通过。
- 关闭本地自动保存后，将多行截图和一个未缓存英文单词截图交给实际 Vision OCR。第二张触发自动朗读及有道远程音频路径。新建的隔离日志包含 OCR 合并和播放状态，所有测试原文标记均未出现在文件日志和标准输出。
- 在测试宿主中运行控制器，验证普通截图和剪贴板图片自动查询后仍能换语言重识别，公式截图重试保留语言纠正。快速切换 OCR 语言后仅最后一次结果回写。
- 实际 AppKit 组件验证了公式等待时的停止按钮和取消回调，原文预览接收输入和粘贴后恢复编辑器。控制器验证了自动复制写入隔离剪贴板，按钮及快捷入口均把原文和语言交给朗读。
- 离线 Codex 协议桩验证了普通模型列表保留 API Key 环境、截图使用独立认证路径并显示本机登录提示。相同模型从 low 改为 medium 时发起新请求，收到新强度译文，旧结果未回写。

### 受影响文件

- `Easydict/Swift/Service/Apple/AppleOCREngine/OCRLineMeasurer.swift`
- `Easydict/Swift/Service/Apple/AppleOCREngine/OCRSectionMerger.swift`
- `Easydict/objc/Service/AudioPlayer/EZAudioPlayer.m`
- `Easydict/objc/ViewController/View/ResultView/EZResultView.m`
- `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.m`
- `Easydict/objc/ViewController/Window/WindowManager/EZWindowManager.m`

### 后续事项

独立测试宿主覆盖了上述行为。测试版窗口无法经界面自动化读取，Codex 场景使用离线协议桩验证。
