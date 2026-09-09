# 构建与测试

## 验证原则

- 对有实际行为或正确性风险的变更添加或更新测试，优先覆盖生产行为和边界条件。
- 不为简单透传、明显 accessor、已有充分覆盖的行为或纯视觉调整机械添加测试。
- 避免为了低价值测试引入仅供测试使用的 protocol、mock、override 或生产 hook。
- 先运行与变更直接对应的检查；只有出现新变更、失败或未解决风险时才扩大或重复验证。
- 验证失败先诊断，在授权范围内修复并复验，不跳过必要检查，也不把环境阻塞写成产品通过。

## 测试目录与文件组织

- 测试目录尽量对应被测主项目的功能和模块结构。Swift 测试以 `Easydict/Swift/` 为映射根，
  例如 `Service/OpenAI/` 对应 `EasydictTests/Service/OpenAI/`。
- 按明确的领域或职责建立子目录，避免将不同模块的测试长期堆积在 `Service/`、`Utility/`
  等顶层目录。跨模块测试按主要业务归属放置，不要求机械复制所有源码层级。
- 每个测试文件聚焦一个主要被测类型或行为领域，并遵循
  [`swift-xcode.md`](swift-xcode.md) 的单文件单 `@Suite` 规则。接近文件规模限制时按职责
  拆分 suite 和 fixture，并保留原有覆盖。
- 单文件使用的 helper 保持局部；同一领域共享的测试工具就近放置，跨目录复用的 fixture
  或工具放入 `EasydictTests/Support/<Domain>/`，资源放入对应测试资源目录。
- 拆分测试时保留标签、actor 隔离、共享状态恢复和串行执行边界。独立 suite 的
  `.serialized` 不提供跨 suite 串行保证。
- 新增或移动测试文件时同步 Xcode group 和测试 target 的 Sources 引用，具体遵循
  [`swift-xcode.md`](swift-xcode.md)。现有目录按任务范围渐进调整。

## Reviewer 与 Tester

- 有行为风险的 implementation 优先使用只读 `reviewer`；需要编写测试或复杂独立验证时使用
  `tester`。简单文档、低风险配置或小改动由主 Agent 完成必要检查。
- 生产实现与测试可独立推进时可以分工；Git index 和本地交付始终串行。
- 除请求边界规定的通用输入外，委派 tester 时补充行为预期和验证范围。reviewer 只读；tester
  只修改明确分配的测试与 fixture，不修改生产代码、工程配置或 history，也不执行 stage、
  commit、push 或 Git ref 操作。
- tester 返回测试目的、修改路径、实际命令、结果和阻塞证据；生产缺陷交回主 Agent。
- 主 Agent 核验审查意见，在已有授权内修复真实问题；无依据或超范围建议说明原因。实现变化后
  按风险增量复核，最终采用的审查和验证必须覆盖最终快照。
- 尚未解决且经核实的阻塞问题、失败验证或必要证据缺失时不能声称完成或自动提交。无法委派时按
  [`request-boundary.md`](request-boundary.md#子代理委派与回退) 回退并说明独立性缺失。
- 单独 review 默认只读；上述收尾规则不把 review、planning 或 staged 提交升级为修复任务。

## 运行 Xcode 验证的条件

满足以下任一条件时运行 `xcodebuild`：

- Swift、Objective-C 或其他由 Xcode 编译的应用源码发生超过 100 行实质性变更；文档、脚本、
  注释和工程元数据不计入阈值。
- 新增或修改 `EasydictTests/**/*.swift` 下的测试源码。
- 用户明确要求构建或测试。

以上是默认最低要求，不是风险判断的上限。少量高风险源码、工程配置或依赖修改也应选择
必要构建或针对性测试。纯治理 Markdown、子代理配置或文档合并默认只运行静态检查；用户明确
要求构建或测试时仍按上述触发条件执行。PR review 能否运行构建以根入口和请求边界为准。

实现变化后重新计算阈值。不要针对同一 workspace 和 DerivedData 并发运行 `xcodebuild`；
默认 DerivedData 不可用时使用外部临时目录，并在验证后删除。

## 常用命令

```bash
# Build
set -o pipefail
xcodebuild build \
  -workspace Easydict.xcworkspace \
  -scheme Easydict | xcbeautify

# Test all tests
xcodebuild test \
  -workspace Easydict.xcworkspace \
  -scheme Easydict | xcbeautify

# Build for repeated test runs
xcodebuild build-for-testing \
  -workspace Easydict.xcworkspace \
  -scheme Easydict | xcbeautify

# Run a test suite after a compatible build-for-testing
xcodebuild test-without-building \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -only-testing:EasydictTests/<TestSuiteOrClass> | xcbeautify

# Run one test method
xcodebuild test-without-building \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -only-testing:EasydictTests/<TestSuiteOrClass>/<testMethod> | xcbeautify
```

使用 `xcbeautify` 时启用 `pipefail`，保留真实退出状态。`test-without-building` 只能复用与
当前源码和配置兼容的产物；测试源码发生变化时运行对应范围的 `xcodebuild test`。

## 非 Xcode 检查

- 每次变更运行 `git diff --check`。
- 对变更的 `.xcstrings` 或 JSON 数据运行 `jq -e .`。
- 对变更的 Shell 脚本运行 `bash -n`。
- Swift 源码变化时运行 `swiftformat --lint` 或仓库现有格式化工具。
- 文档结构变化时检查现行相对链接、锚点和已删除路径引用。
