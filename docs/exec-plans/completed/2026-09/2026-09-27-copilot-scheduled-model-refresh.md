# Copilot 启动与每日模型刷新

- 状态：completed
- 创建日期：2026-09-27
- 负责人：Codex
- 关联 Issue/PR：None

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

## 背景

模型选择已直接使用持久化目录。用户希望自动更新，但明确只采用启动一次和随后每 24 小时一次的简单策略。

## 目标与范围

- 目标结果：启动约 5 秒后检查启用状态并刷新，随后每 24 小时重复；菜单保持同步读取缓存。
- 允许修改路径：AppDelegate、GitHubCopilotModelStore/Service/Catalog、缓存设计说明、中英文指南及任务记录。
- 同任务 history：`docs/histories/2026-09/2026-09-27-copilot-scheduled-model-refresh.md`
- 用户限制：不增加激活、唤醒、设置页打开或首次启用触发，不增加缓存过期或失败冷却策略。
- 非目标：修改模型菜单、自动重译、测试扩写、PR 或推送。
- 验收标准：每进程只注册一个定时器；任何查询窗口启用 Copilot 时才执行自动请求；手动/自动请求合并，失败保留缓存；退出停止调度。

## 工作计划

1. Store 管理单一定时器，Service 提供 Objective-C 启停桥接，AppDelegate 接入启动/退出。
2. 复用已有刷新和缓存逻辑，更新实际行为说明。
3. 运行格式、构建和范围检查，完成代码 review。
4. 更新 history、归档计划并自动创建本地提交。

## 风险与决策

- 定时器仅调度短回调，CLI 工作仍使用现有异步后台路径，不阻塞界面。
- 每次触发读取当前启用状态；未启用时跳过该轮，但保留日程供以后使用。
- 不改变本次翻译或已展开菜单；新目录仅供后续选择/请求使用。
- 执行前 HEAD：`d4656629607de6ed9dc7b55b64ec99cbc284b6c6`；工作树、索引均为空。

## 进度

- [x] 定时器与生命周期接入
- [x] 文档与验证
- [x] review 与归档，随任务范围创建本地提交

## 验证

- 独立 Agent DerivedData 下的 `xcodebuild build`（Debug、`EASYDICT_RELEASE_PACKAGING=YES`）：通过。
- 三个变更 Swift 文件的 SwiftFormat lint、工程固定版本 SwiftLint，以及 `git diff --check`：通过。
- 生成的 Swift Objective-C 头已导出两个生命周期类方法，AppDelegate 编译成功。
- review：以执行前 HEAD 为基线，冻结全部任务文件内容并复验无漂移；检查单次注册、三个窗口的启用状态、请求合并、取消、原子缓存写入及菜单通知路径，未发现有效 finding。现有 Store 加单一定时器已足够，无需独立调度模块。
- 没有覆盖此调度的现有测试；未新增测试。Xcode 正运行同 bundle ID 的调试实例，未另起应用或 app-hosted tests；首次触发及完整 24 小时周期未做运行时验证。

## 完成条件

- 必要构建与静态检查通过，review 无未处理有效 finding。
- history 与最终行为一致，归档计划并提交任务范围。
