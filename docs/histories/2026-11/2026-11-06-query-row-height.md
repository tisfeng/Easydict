## 2026-11-06 | 任务：修复服务模型设置触发的查询行高崩溃

**Links:** [执行计划](../../exec-plans/completed/2026-11/2026-11-06-query-row-height.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B52)`

### 用户请求

用户在服务设置中粘贴模型名称后遇到 NSTableView 第 0 行高度为 0 的异常，授权执行已讨论的局部修复方案。

### 变更

- 后台 OCR 重建查询模型时，在绑定控制器和协作者前初始化 `queryViewHeight` 为当前窗口的最小输入高度。
- 输入行行高代理将有限高度限制为至少最小输入高度，非有限值直接使用最小高度。
- 创建并归档任务计划；保留服务通知和模型同步逻辑，未新增或扩写测试。

### 设计意图

后台 OCR 新模型的默认高度为 0，而服务配置通知可触发后台查询控制器的表格刷新。
初始化补齐模型状态，行高出口保证 AppKit 获取有效正值，并保留正常多行输入的较大高度。
此缺陷与用户截图调用链吻合，但未在运行时确认截图中的实例身份。

### 验证

- `xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath "$agent_dd" -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -only-testing:EasydictTests/ReverseTranslationTests -only-testing:EasydictTests/QueryModelCancellationTests -resultBundlePath "$result_bundle"`：Debug 构建成功，2 个 suite、15 个测试通过，0 失败；使用按 checkout 隔离的 Agent DerivedData。
- `xcresulttool get test-results summary`：结果为 Passed，15 个测试，0 失败；结果包名为 `easydict-query-row-height-20261106.xcresult`。
- `git diff --check`：通过。
- review 技能审查：无有效 finding；核对了初始化顺序、窗口最小高度、多行输入及未改动的结果行分支，构建前后生产文件内容一致。
- 构建记录了 App Intents 元数据跳过、既有桥接头弃用警告；测试宿主有 Ollama 本地服务不可达日志，所选离线测试通过。
- 手动检查：确认测试宿主已退出，用户 Xcode 中暂停的原实例保留。

### 受影响文件

- `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.m`
- `docs/exec-plans/completed/2026-11/2026-11-06-query-row-height.md`
- `docs/histories/2026-11/2026-11-06-query-row-height.md`

### 后续事项

- 已有测试不直接覆盖行高崩溃；设置页面粘贴模型、后台 OCR 成功/失败后修改模型，以及输入/缩放视觉验收仍需手动验证。
