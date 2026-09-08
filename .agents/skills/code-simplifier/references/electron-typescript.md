# Electron/TypeScript 专项规则

仅在目标代码包含 Electron、TypeScript、React、IPC、preload 或 renderer 时加载本 reference。
这些规则适用于一般 Electron/TypeScript 项目；项目自己的 `AGENTS.md`、构建配置、安全模型和代码约定优先。

## TypeScript 与模块边界

- 遵循仓库声明的 TypeScript 版本、`tsconfig` 继承关系、模块边界和导入规则，不假设固定模块系统或构建工具。
- 保持公开 API、序列化格式、错误语义、调用方可见类型和运行时行为；不要为了缩短代码放宽类型。
- 不使用新增的 `any`、无根据类型断言、非空断言或忽略指令掩盖不确定性；在交付边界进行类型收窄和输入校验。
- 重构异步流程时保留错误传播、取消、竞争顺序、重复调用和资源释放语义。

## Electron 进程与 IPC

- 保持 main、preload 与 renderer 的职责边界，以及项目既有的 `contextIsolation`、sandbox、Node integration 和 `contextBridge` 策略。
- preload 只暴露 renderer 真正需要的最小 API；不将文件系统、进程、环境变量、凭据或未校验输入直接引入 renderer。
- 保留 IPC channel 名称、调用方向、payload/响应结构、序列化限制和错误语义；同时检查发送方、preload 桥接与处理方。
- 不为了减少封装层数而跨越信任边界、绕过权限检查或隐藏窗口与 WebContents 的归属关系。

## React 与 renderer 界面

- 保持组件身份、状态所有权、数据流、effect 清理和可访问性语义；不要为了减少行数引入隐藏副作用或不稳定的 key。
- 事件、IPC 和外部 store 的订阅必须与清理对称，避免组件重新挂载、热更新或窗口重建后出现重复监听。
- 只在能明确改善职责边界或复用性时拆分组件；纯视觉调整不应伪装成行为重构。

## 生命周期与资源

- 保留 `BrowserWindow`、`WebContents`、session、tray、menu 和其他长生命周期对象的所有权与释放时机。
- 检查事件监听、定时器、`AbortController`、文件句柄和后台任务在取消、窗口关闭与应用退出时的收尾行为。
- 不改变应用启动、单实例处理、窗口恢复、关闭或退出时序，除非它们明确属于当前任务。

## 验证

- 使用项目已声明的包管理器、脚本、类型检查、测试和构建入口；不假设固定的 Node、Electron 或测试命令。
- 修改 IPC 时同时验证发送方、preload 桥接、处理方及共享类型；修改进程边界时检查相关构建产物。
- 只运行当前任务和仓库规则要求的检查，并明确记录未验证部分。静态检查不能证明打包应用、原生集成、真实 GUI 或跨平台行为。
