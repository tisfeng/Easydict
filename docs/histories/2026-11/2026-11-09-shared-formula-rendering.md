## 2026-11-09 | 任务：复用上游公式渲染并修复截图回归

**Links:** [PR #1391](https://github.com/tisfeng/Easydict/pull/1391) · [PR #1375](https://github.com/tisfeng/Easydict/pull/1375) · [执行计划](../../exec-plans/completed/2026-11/2026-11-09-shared-formula-rendering.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B52)`

### 用户请求

同步最新 dev，复用 #1375 的公式排版，逐条核对审查，优先修复 OCR 日志和回归，验证后更新原 PR。

### 变更

- 合入 `f5b61fafb4ba4d4778e9360df846f6c29ae368f0`，解决 Xcode 工程、Markdown 标签、渲染器和测试的四处冲突。
- 直接使用上游解析器、SwiftMath 依赖、宽度适配和选中复制实现。在共享公式渲染层兼容粗体、分式变体和简单编号。
- 截图原文和译文均受 Markdown 设置控制，理工科公式模式控制截图输入路径。
- 删除低层 OCR 内容日志，为 Claude Code 和 Copilot 日志增加请求开始与写入时的本地保存检查。
- 保留普通 OCR 自动查询的原图，拒收旧识别结果，保持同图公式重试的语言纠正。
- 恢复公式结果的编辑入口、取消、自动复制和朗读，并完善 Codex 模型目录、登录错误、思考强度和大图提示。

### 设计意图

两个截图面板复用通用 Markdown 渲染，也保留普通 AI 翻译渲染 LaTeX 的路径。按识别请求捕获图像和语言，并在回写时同时核对请求身份和当前模型状态。

### 验证

- `xcodebuild build-for-testing`：Debug arm64 成功。
- `xcodebuild test-without-building`：14 个 suite 共 185 项现有离线用例通过，包括上游公式源文复制和宽度测试、OCR、语言检测、Codex 设置和取消。
- 扩大试跑的唯一失败来自缺少 GitHub Copilot CLI 的在线验证。界面自动化读取指定 Debug 构建超时，未完成截图交互或在线模型实测。
- `git diff --check`、String Catalog JSON 校验与 Xcode 工程语法检查通过。提交前复核识别、保存和共享渲染调用链。

### 受影响文件

- `Easydict/Swift/Feature/Markdown/`、`Easydict.xcodeproj/project.pbxproj` 和上游 Markdown 测试。
- `Easydict/Swift/Model/DetectManager.swift`、Apple OCR 处理、CLI 日志和 Codex 服务。
- QueryView、ResultView、BaseQueryWindow 和中英文使用指南。

### 后续事项

真实界面、截图和 Copilot CLI 在线用例待有可用环境后验证。

### 行内审查逐条核对

| 评论 | 当前处理 |
| --- | --- |
| [保留普通 OCR 图像](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4500079916) | OCR 和剪贴板 OCR 的自动文字查询保留图像。 |
| [公式重试保留语言](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4500079921) | 同一图像重试时恢复清空文本前的语言，新图像重新检测。 |
| [CLI 日志保存设置](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4505368340) | Claude Code 与 Copilot 文件日志检查请求初始设置及实际写入时的设置。 |
| [OCR 请求竞态](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4505385377) | 检查最新请求 UUID 和语言，识别使用请求开始时的图像和语言。 |
| [Debug OCR 原文](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4505385384) | 删除观察内容及跨段文字日志，保留计数和置信度。 |
| [选中公式复制](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4505385397) | 两栏继承上游公式源码还原，上游现有复制测试通过。 |
| [图像编码错误](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4505385409) | 区分编码失败、图像过大和响应无效，过大提示缩小截图范围。 |
| [等待时停止](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4505385420) | 请求处于加载状态时显示停止按钮。 |
| [普通 CLI 模型目录](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4505385436) | 文本目录使用独立会话，并沿用普通 CLI 认证环境。 |
| [仅更改思考强度](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4505385460) | 普通 Codex 卡片沿用服务更新通知重新查询。 |
| [截图登录提示](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4505385468) | 本机 CLI 未登录时显示本机登录指引。 |
| [既有强度设置](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4505385479) | 保留 Defaults 的原始枚举值存储。 |
| [从预览进入编辑](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4505385493) | 输入或粘贴时恢复文本编辑器，选中复制继续走共享标签。 |
| [OCR 图像重复反馈](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4505385514) | 与普通 OCR 图像保留问题同一修复。 |
| [语言纠正重复反馈](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4505385522) | 与公式重试保留语言问题同一修复。 |
| [自动复制译文](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4505385528) | 公式服务安装同一偏好控制的复制回调。 |
| [朗读截图原文](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4505385540) | 扬声器与快捷键共用的朗读入口使用截图原文。 |
