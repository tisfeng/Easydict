## 2026-11-02 | 任务：规范 static 使用并精简 OCR 实例成员

**Links:** [编码规范](../../agents/coding-guidelines.md) ·
[执行计划](../../exec-plans/completed/2026-11/2026-11-02-swift-static-member-guidelines.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B48)`

### 用户请求

补充仅在必要时使用 static 的编码规则，评估 AppleOCREngine 的 static 成员。后续认可 5 秒
实例超时和二维码规范化调整，并要求解释 claim/release 与协调对象的必要性；该共享控制组
保持现有实现，只解释和补充说明。不新增或修改测试，不 push。

### 变更

- 编码规范明确优先采用实例或局部定义，仅在有类型级契约或确需跨实例共享时使用 static。
  共享状态须明确所有权、生命周期及同步方式，常量不变和无状态都不是 static 的自动理由。
- `recognitionTimeout` 改为 5 秒实例常量，accurate（包含槽位等待）与 fast 分别使用该值。
- 二维码规范化移为文件私有的 String 计算属性，三个调用点仍只用规范化值比较与去重，
  返回的 QR payload 内容保持原样，后台闭包无需捕获引擎来调用该操作。
- 保留现有锁、忙碌标志、claim/release 四处必要的 static，补充跨实例共享原因，没有新增
  协调对象或改变槽位状态机。引擎内 static 从 6 处降为 4 处。
- 更新本 history 并归档同任务计划。

### 设计意图

配置与字符串值操作具有实例语义；accurate 执行名额则要跨实例共享。claim 是在锁保护下检查并
占用名额，release 在底层 Vision 真正退出后归还名额；锁仅保护短临界区，不跨 OCR 的 await
持有。调用方 timeout 不等于底层退出，因此不提前释放槽位，以免挂起工作堆积。
新增协调对象只是封装选择，当前代码已能满足该策略，不为减少 static 数量引入额外类型。

### 验证

- 初始 HEAD：`90f4a9527ce052f2bd71bbe9a370ee9eb186a558`；工作区和索引干净。
- 初始提交相对 `0f05fb13466c9793897d102a2f0d26dec21396e9` 仅改变文档，源码、测试与工程
  配置相同，复用上一轮相同 Development 签名、arm64 的现有 12 测试结果为 10 秒基线。
- 5 秒版本仍为 12 个测试中 9 个通过、3 个 golden 测试失败；逐条比较 21 条失败消息，
  实际识别输出、预期值和样例完全相同，没有新增失败或输出变化。5 个超时工具测试和
  4 个二维码测试全部通过；日文、中文与英文 golden 差异保持原记录，没有修改测试以消除失败。
- 签名 Debug `xcodebuild build` 退出码为 0；Swift parser、SwiftFormat lint、
  `git diff --check`、文档格式与相对链接检查通过。整体测试退出码仍为 65，不表述为全部通过。
- 使用 review 审查本轮完整 diff、字符串调用点、超时引用和保留的共享控制边界，未发现新增
  有效 finding；原有应用实例保留，测试宿主已退出。
- 没有新增测试或生产代码测试 hook；所选回归结果不代表所有模型冷启动和系统版本的表现。

### 受影响文件

- `docs/agents/coding-guidelines.md`（上一阶段已提交的规则补充）
- `Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine.swift`
- `docs/exec-plans/completed/2026-11/2026-11-02-swift-static-member-guidelines.md`
- 本 history。

### 后续事项

- 两阶段等待预算为 5+5 秒，图像准备、二维码检测及结果处理另计，不是端到端 5 秒保证。
- 更短 timeout 在其他冷启动场景下可能更容易进入 fast，后续体验验证需关注中日文。
- 既有 golden 差异继续作为独立事项记录，不改变之前的失败接受范围。
