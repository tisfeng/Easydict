# 修复服务模型设置触发的查询行高崩溃

- 状态：completed
- 创建日期：2026-11-06
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B52)`

## 背景

用户在服务设置中粘贴模型名称后，查询控制器返回第 0 行高度 0，触发 NSTableView 异常。
静态检查发现后台 OCR 重建查询模型时没有初始化输入行高度；模型设置变更广播可触发后台控制器刷新。
尚未通过运行时检查确认用户暂停的实例是否为后台控制器。

## 目标与范围

- 目标结果：重建模型后输入行高度有效，行高代理为无效高度提供最小值。
- 允许修改路径：`Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.m` 和本任务 plan/history。
- 同任务 history：`docs/histories/2026-11/2026-11-06-query-row-height.md`
- 用户限制：执行已确认的局部修复方案；遵守仓库测试新增授权边界。
- 非目标：修改模型同步、服务通知传播或 OCR 识别流程。
- 验收标准：构建和已有查询相关测试通过；审查无未解决有效 finding；说明直接复现场景的验证边界。

## 工作计划

1. 初始化后台 OCR 新模型的 queryViewHeight。
2. 输入行代理对非有限高度和低于最小值的高度兜底。
3. 运行已有查询控制器和模型测试，检查源码集成及范围。
4. 使用 review 审查，完成 history、计划归档及本地提交。

## 风险与决策

- 保留正常多行输入高度，使用当前窗口的 miniQueryViewHeight 作为下限。
- 不新增测试文件、断言或生产 hook；已有测试不覆盖完整设置页面复现。
- 保留 Xcode 中暂停的用户实例；使用独立 Agent DerivedData 运行测试宿主。

## 进度

- [x] 两处生产代码修复。
- [x] 现有测试和静态检查。
- [x] Review、history 和计划归档；本地提交作为交付末步执行。

## 验证

- `xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath "$agent_dd" -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -only-testing:EasydictTests/ReverseTranslationTests -only-testing:EasydictTests/QueryModelCancellationTests -resultBundlePath "$result_bundle"`：成功，2 个 suite、15 个测试通过，0 失败。`agent_dd` 遵循构建规则，独立于 Xcode 默认目录；结果包名为 `easydict-query-row-height-20261106.xcresult`。
- 测试覆盖 Debug 构建；没有重复执行同配置 build。
- `git diff --check`：通过。
- 使用 review 技能自审 HEAD `221f5be81ea1bf3e3df3c7f6597e86773f0da4de` 上的任务差异：无有效 finding。检查了模型替换、输入行出口、当前窗口最小高度、正常多行输入高度和结果行分支；生产文件内容在构建前后及审查时一致。局部初始化和出口兜底足以覆盖已发现的缺口，无需扩大通知逻辑改动。
- 测试宿主正常结束，原 Xcode 暂停实例仍保留。构建有 App Intents 元数据跳过和既有桥接头弃用警告；宿主启动记录了 Ollama 本地服务不可达，不影响所选离线测试结果。
- 未执行设置页面粘贴模型的完整 UI 复现、后台 OCR 成功/失败后的手动回归，以及输入/缩放视觉验收；已有 suite 不直接覆盖这些路径，未新增测试。

## 完成条件

- 限定范围的修复完成，必要检查通过，Review 无未解决有效 finding。
- history 记录真实结果及未验证项，计划归档并创建本地提交。
