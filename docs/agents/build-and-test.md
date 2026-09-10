# 构建与测试

## 验证原则

### 什么时候添加测试

- 修复真实 bug 时，添加能复现问题的回归测试。
- 新增或修改复杂逻辑时，覆盖关键分支和边界，例如取消、超时、状态切换和错误恢复。
- 优先更新现有用例，不重复覆盖已有场景。

### 什么时候不添加测试

- 简单赋值、固定返回值、getter/setter、参数透传等明显逻辑。
- 不改变行为的重命名、移动文件、拆分和重构，以及文档、注释、纯视觉调整。
- 为简单逻辑专门构造测试子类、mock 或辅助设施，测试成本明显超过收益。
- 只验证人为构造的调用过程或内部实现细节，无法说明能防止什么实际问题。

### 如何验证

- 优先通过真实生产逻辑验证结果，不为凑测试增加生产抽象或测试 hook。
- 先运行与改动直接相关的检查；只有新变化、失败或未解决风险影响结论时才扩大验证。
- 同一任务中，相同内容快照、命令和环境的有效结果可以复用。执行者保留命令、退出状态和必要
  输出，主 Agent 核验覆盖范围；快照或环境变化、失败、证据缺口影响结论时重跑相关检查。
- 相互独立且没有共享写入冲突的检查可以并行；同一 workspace 和 DerivedData 的 Xcode 操作仍
  按下文保持串行。
- 不把未运行、失败或环境阻塞的检查写成通过。

## 测试目录与文件组织

- 测试目录尽量对应被测主项目的功能和模块结构。Swift 测试以 `Easydict/Swift/` 为映射根，
  例如 `Service/OpenAI/` 对应 `EasydictTests/Service/OpenAI/`。
- 按明确的领域或职责建立子目录，避免将不同模块的测试长期堆积在 `Service/`、`Utility/`
  等顶层目录。跨模块测试按主要业务归属放置，不要求机械复制所有源码层级。
- 每个测试文件聚焦一个主要被测类型或行为领域，且最多声明一个 `@Suite` 类型。接近文件规模
  限制时按职责拆分 suite 和 fixture，并保留原有覆盖。
- 单文件使用的 helper 保持局部；同一领域共享的测试工具就近放置，跨目录复用的 fixture
  或工具放入 `EasydictTests/Support/<Domain>/`，资源放入对应测试资源目录。
- 拆分测试时保留标签、actor 隔离、共享状态恢复和串行执行边界。独立 suite 的
  `.serialized` 不提供跨 suite 串行保证。
- 测试文件的工程引用同步见下节；现有目录按任务范围渐进调整。

## 工程文件与资源

新增、移动或删除由 Xcode 管理的源码文件或运行时资源时，同步
`Easydict.xcodeproj/project.pbxproj` 中的 group、文件和 build phase 引用；测试文件同时同步
测试 target 的 Sources，删除文件不保留悬空引用。仓库治理 Markdown、
计划、history、skill、参考资料和 `docs/` 下的公共 Markdown 不需要工程引用；除非文档作为
运行时资源发布，否则不加入 build phase。

## Tester

- 需要编写测试或复杂独立验证时使用 `tester`。简单文档、低风险配置或小改动由主 Agent 完成
  必要检查。
- 生产实现与测试可独立推进时可以分工；Git index 和本地交付始终串行。
- 除请求边界规定的通用输入外，委派 tester 时补充行为预期和验证范围。tester 只修改明确分配的
  测试与 fixture，不修改生产代码、工程配置或 history，也不执行 stage、commit、push 或 Git
  ref 操作。
- tester 返回测试目的、修改路径、实际命令、结果和阻塞证据；生产缺陷交回主 Agent。
- 尚未解决且经核实的阻塞问题、失败验证或必要证据缺失时不能声称完成或自动提交。无法委派时按
  [`request-boundary.md`](request-boundary.md#子代理委派与回退) 回退并说明独立性缺失。

## 选择 Xcode 验证

根据变更需要证明的结果，选择最小且充分的 Xcode 验证。变更行数只用于决定是否扩大验证范围，
不作为运行 `xcodebuild` 的硬阈值。

- 纯治理 Markdown、plan、history、注释，以及不进入 Xcode 构建图的脚本或配置，默认只运行相应
  静态检查。
- Xcode 编译的生产源码发生实质变化，且本轮不会运行能覆盖同一内容和构建配置的测试时，运行
  `xcodebuild build`，验证应用 target 的编译、链接和资源集成。
- 工程/workspace、target、build setting、build phase、依赖、entitlement、Info.plist 或运行时资源
  发生变化时，运行覆盖受影响配置的 `xcodebuild build`；如果同一配置已由后续要求的测试覆盖，
  不重复运行 `build`。
- 修复 bug 或修改可测试行为且存在对应自动化测试时，直接运行覆盖该行为的 `xcodebuild test`。
- 新增、修改或删除 `EasydictTests/**/*.swift` 下的测试源码，或调整测试 target 引用时，运行覆盖
  相应 suite 或方法的 `xcodebuild test`。

`xcodebuild build` 只证明构建集成，不证明业务行为正确。`xcodebuild test` 会构建测试所需产物；
在 workspace、scheme、destination、configuration 和 DerivedData 兼容时，成功的测试同时满足相应
编译验证，不预先重复运行 `build`。只有测试动作未覆盖的 Release、Archive、签名或其他配置需要验证
时，才追加对应构建。

优先运行能覆盖风险的最小测试范围。共享基础设施、依赖升级、跨模块行为变化或无法可靠确定受影响
测试时，扩大到相关 suite，必要时运行完整测试 target。同一内容和配置需要反复测试时，先执行一次
`build-for-testing`，再使用 `test-without-building`；`build-for-testing` 本身不构成测试通过证据。

在实现稳定后选择验证；实现、构建配置或测试发生影响结论的变化时，重新评估并复验相关范围。
不要针对同一个 workspace 和 DerivedData 位置并发运行 `xcodebuild`。

默认不传 `-derivedDataPath`，优先使用 Xcode 默认 DerivedData，复用与当前 workspace、scheme、
destination 和 configuration 兼容的本地缓存。只有默认构建或测试失败，且证据表明原因来自
DerivedData 权限、缓存损坏或 runner 状态时，才使用显式临时 DerivedData 重试；普通源码、编译、
链接或测试失败不能据此切换目录。报告 fallback 的使用情况，并只删除本任务创建且未被使用的临时目录。

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
  -only-testing:EasydictTests/UtilityFunctionsTests | xcbeautify

# Run one test method after a compatible build-for-testing
xcodebuild test-without-building \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -only-testing:EasydictTests/UtilityFunctionsTests/testAES | xcbeautify
```

使用 `xcbeautify` 时启用 `pipefail`，保留 `xcodebuild` 的真实退出状态。默认命令不指定
DerivedData；仅在上节规定的 fallback 条件成立时，才改用以下形式：

```bash
# Fallback only when the default DerivedData is proven unusable
xcodebuild build \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -derivedDataPath ~/Library/Developer/Xcode/DerivedData/Easydict-Temporary | xcbeautify
```

测试命令需要 fallback 时，在对应命令中添加相同的 `-derivedDataPath` 参数，不重复维护另一套
命令矩阵。

## 非 Xcode 检查

- 每次变更运行 `git diff --check`。
- 对变更的 `.xcstrings` 或 JSON 数据运行 `jq -e .`。
- 对变更的 Shell 脚本运行 `bash -n`。
- 纯治理 Markdown 默认运行格式、相对链接、锚点和规则语义检查。
