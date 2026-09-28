# 修复 Copilot 输出收尾竞态

- 状态：completed
- 创建日期：2026-09-27
- 负责人：Codex
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/pull/1332#discussion_r4114397251

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

## 背景

读取回调取走字节后、提交队列前，进程结束回调可能先完成流，导致最后的译文或控制事件丢失。
串行队列屏障不能等待尚未入队的读取回调。

## 目标与范围

- 目标结果：每个输出管道只有一个读取者，全部输出处理完毕后才结束请求。
- 允许修改路径：`Easydict/Swift/Service/GitHubCopilot/GitHubCopilotRunner.swift` 及本任务文档。
- 同任务 history：`docs/histories/2026-09/2026-09-27-fix-copilot-output-finalization.md`
- 用户限制：在 `feat/github-copilot-service` 上实现；本轮只交付本地提交。
- 非目标：工程文件重复对象、review-pr 技能修改及多个 CLI 服务的公共重构。
- 验收标准：进程退出和两个读取者完成后统一收尾；启动失败、取消、读取失败均释放资源；构建通过。

## 工作计划

1. 替换 readabilityHandler 与结束回调的双重管道读取。
2. 实现请求级串行处理和退出、EOF 完成条件，覆盖异常与取消路径。
3. 运行范围匹配的检查与构建，使用 review 技能审查最终差异。
4. 记录验证边界，归档计划并创建本地提交。

## 风险与决策

- 阻塞读取使用后台 Dispatch 队列，不占用主线程或 Swift 并发执行器。
- stdout 与 stderr 必须并行读取，避免单个管道写满阻塞子进程。
- 不以固定延时判断输出结束；取消后的强制终止仅用于释放忽略 SIGTERM 的子进程。
- 当前 Xcode 调试宿主运行中；不并行运行同 bundle id 的应用宿主测试。

## 进度

- [x] 确认基线 `f7ce8757f58eba8517abf2547166c354871d06d9` 与空索引、干净工作区。
- [x] 完成修改、验证和 review。
- [x] 完成 history，与归档计划一起交付本地提交。

## 验证

- `swiftformat --lint Easydict/Swift/Service/GitHubCopilot/GitHubCopilotRunner.swift`：通过。
- `git diff --check`：通过。
- 独立 DerivedData 的 `xcodebuild build`（workspace `Easydict.xcworkspace`、scheme `Easydict`、
  Debug、`EASYDICT_RELEASE_PACKAGING=YES`）：通过；日志确认重新编译 Runner。
- 最终源码 SHA-256：`849a74e6c1ed73ec8882494961dee95bb2989113f46d7f6cb8cf855cef4114a2`。
- review：检查完整 diff、Service 取消调用者、Logger 和输出解析路径，无未处理的有效 finding。
  数据处理在读取者完成标记之前，finalizer 只能在两个完成标记和退出码均已到达时执行。
- 仓库规则要求显式授权才能新增测试，本轮未新增；现有测试目录没有 Copilot Runner 专项用例。
  Xcode 调试宿主运行中，未运行应用宿主测试；未声称完成快速退出、读取错误注入或取消压力测试。

## 完成条件

- 代码与异常路径审查无未处理的有效 finding。
- 构建及静态检查通过，未运行验证明确记录。
- history 完成，计划归档，创建本地提交。
