## 2026-11-10 | 任务：提前显示公式截图译文

**Links:** [执行计划](../../exec-plans/completed/2026-11/2026-11-10-stream-formula-translation.md) · [Easydict #1391 基线](https://github.com/tisfeng/Easydict/pull/1391)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B52)`

### 用户请求

在同一张论文截图上比较 Luna 默认和 Low 的耗时、分式及上下标，再实现译文先显示、原文最后显示，并在本机复测。

### 变更

- 公式截图请求先生成译文，再生成原文。复用现有 App Server 和流式结果视图，在段落或独立公式完整时推送预览。
- 仅在流完成后提交原文及其语言。最终处理兼容旧响应顺序和模型重复输出的分隔标记。
- GPT-6 Luna 在公式模式中选「默认」时使用 Low。显式选择仍按菜单所选的强度发送，其他模型沿用自己的默认值。

### 设计意图

通过同一个临时视觉请求保留译文和可复制的原文。继续使用现有 LaTeX 渲染、请求取消和结果失效校验。思考强度仍由已有菜单控制。

### 验证

- 在本机隔离 AppKit 宿主中用实际截图查询入口、Codex 服务及 AppKit 结果视图处理同一论文裁片。关闭本地自动保存，两种实现都按默认、Low、Low、默认的顺序在同进程各跑四次。首个默认请求含本地 App Server 冷启动。耗时从将图像交给查询窗口算起，单位为秒。

| 实现 | 强度 | 首段两次 | 完成两次 |
| --- | --- | --- | --- |
| 基线 `2b5a1265` | 默认 | 21.77 / 18.20 | 22.07 / 18.20 |
| 基线 `2b5a1265` | Low | 17.89 / 17.09 | 17.89 / 17.09 |
| 流式版 | 默认 | 12.27 / 9.43 | 19.89 / 17.13 |
| 流式版 | Low | 9.03 / 9.62 | 16.58 / 17.30 |

- 八次结果的原文及译文均保留分式、上下标和范数下标。一次基线 Low 将黑板粗体 X 写成普通 X。裁片右侧有遮挡，因此只用完整可见的公式比较识别。
- 检查了新版首段和最终状态截图。离线解析检查覆盖标记分片、CRLF、多行公式、重复标记和旧格式。离线 App Server 桩实测首段出现后可点击停止，迟到的公式与原文均未回写。
- `xcodebuild build-for-testing` 成功。首次离线回归的一项普通 Vision OCR 文字断言失败，复跑 14 个套件的 185 项测试全部通过。
- 用户在安装的流式版上试用论文截图，确认首段等待改善。切换默认强度后，离线 App Server 桩在真实查询入口收到 Luna 默认的 `low` 和显式 `medium`。另一视觉模型的默认请求不附加强度参数。Codex 与 Markdown 的 132 项现有测试全部通过。

### 受影响文件

- `Easydict/Swift/Service/CodexCLI/CodexCLIService.swift`
- `Easydict/Swift/Service/CodexCLI/CodexManagedAppServer.swift`
- `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.m`

### 后续事项

- 样本为一张图，每档每版两次。测量覆盖截图交给查询窗口后的本机链路。
