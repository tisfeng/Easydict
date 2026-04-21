# AppleScript

## 目录职责

这个目录封装 Easydict 的 AppleScript 能力，包括业务 facade、浏览器与系统脚本模板，以及底层执行后端。上层调用方统一依赖 `AppleScriptTask`，不直接选择 `NSAppleScript` 或 `osascript`。当前正式业务路径默认走 `NSAppleScript`。

## 关键组件

- `AppleScriptTask.swift`：对外 facade，暴露统一入口并保留快捷指令脚本模板生成。
- `AppleScriptExecutor.swift`：`NSAppleScript` 后端，负责主线程执行、超时控制和错误映射。
- `AppleScriptProcessExecutor.swift`：`Process` / `osascript` 后端，作为内部兼容工具保留。
- `AppleScriptTask+Browser.swift`：浏览器相关 AppleScript 模板与动作封装。
- `AppleScriptTask+System.swift`：系统音量等系统脚本能力。

## 主要流程

浏览器选中文本、浏览器插入文本、系统音量脚本，以及 Apple Translation 的快捷指令 fallback，都会先进入 `AppleScriptTask`，再统一转发到 `AppleScriptExecutor`。只有明确需要子进程执行时，内部代码才应直接使用 `AppleScriptProcessExecutor`。

## 调试入口

先确认问题出在脚本模板还是执行后端。业务脚本优先排查 `AppleScriptExecutor` 的主线程执行、timeout 和 `QueryError` 映射；如果涉及 `osascript` 子进程行为，再检查 `AppleScriptProcessExecutor` 的 stdout、stderr 与进程生命周期。浏览器异常通常从 `AppleScriptTask+Browser.swift` 的脚本模板开始定位。
