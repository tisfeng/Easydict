## 2026-10-06 | 任务：修复划词浮层的光标与清理路径

**Links:** [Issue #1177](https://github.com/tisfeng/Easydict/issues/1177) · [执行计划](../../exec-plans/completed/2026-10/2026-10-06-selection-cursor-lifecycle.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode Unknown (not installed; Command Line Tools available)`

### 用户请求

调查运行较久后箭头和文本光标反复切换的问题，修复有证据支持的代码路径，并向官方仓库提交 PR。

### 变更

- 不再将 AppKit cursorUpdate 事件纳入划词输入监听，避免它落入默认的浮层关闭分支。
- 关闭自动划词或停止监听时，关闭已有浮层并取消待执行/尚未返回的自动取词工作。
- 普通关闭复用现有的 transient cleanup，先更新状态、清理监听器，再关闭实际可见的窗口。
- 强制关闭在浮层尚未显示时也使旧请求失效；异步返回和实际展示前重新检查自动划词开关。
- 未添加或修改仓库测试；保留独立诊断实验与现有测试的验证边界。

### 设计意图

AppKit 的光标更新不是新的选区操作。图标的消失、停止监听和异步结果应共享一致的生命周期，
避免旧请求在关闭后重新创建浮层。修复复用现有 generation 和 cleanup，不新增状态机或依赖，
保留点击激活、Cmd+C 忽略规则和主动取词回调。

### 验证

- 使用生产 EventMonitorEngine、实际事件 mask 和模拟默认关闭回调的 AppKit 对照实验：修改前 cursorUpdate 回调 1 次并关闭浮层；修改后回调 0 次，浮层保持可见。
- 现有 ThrottleGateTests：5/5 通过独立 Swift Testing runner，未更改 suite 或断言；不视为新增生命周期回归覆盖。
- 修改文件通过 Swift parser；相关监听器、浮层控制器和节流器通过独立 typecheck。
- `git diff --check`：通过。
- `xcodebuild test`：环境阻塞，未安装完整 Xcode；没有产出或安装修复后的应用。
- review：基线 `cfda6e2f43741a3210a290e422846f1d83742d38`；核对完整源码差异、窗口点击入口、延迟回调和 Cmd+C 规则。未发现有证据的阻塞代码缺陷，验证限制保留在 PR。

### 受影响文件

- `Easydict/Swift/Utility/EventMonitor/Core/EventMonitor.swift`
- `docs/exec-plans/completed/2026-10/2026-10-06-selection-cursor-lifecycle.md`
- 本 history 文件。

### 后续事项

- 在完整 Xcode 环境构建和运行应用测试。
- 验证划词图标点击/悬停、双击/三击、Cmd+A、强制 Cmd+C 取词和开关切换。
- 使用修复后的完整应用进行长时间复现；当前证据不足以宣布 #1177 已彻底解决，因此提交 Draft PR，不自动关闭 issue。
