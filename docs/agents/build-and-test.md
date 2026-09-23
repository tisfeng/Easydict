# 构建与测试

## 测试与验证原则

- 只有用户在当前任务中明确要求添加测试代码时，才允许新增或扩写测试。修复真实 bug、新增功能、
  修改复杂逻辑或判断存在回归风险，都不构成添加测试的授权。
- 测试代码包括测试文件、suite、用例、断言、fixture、mock、测试 helper，以及仅为测试引入的
  生产代码 hook。未获授权时可以运行和分析现有测试；如认为需要补充测试，只在结果中提出建议。
- 获得授权后优先更新现有用例，并遵循最小范围原则；不要为了测试简单实现而增加生产抽象、mock
  或测试 hook。
- 优先运行直接覆盖变更风险的检查；共享基础设施、依赖或影响范围不明确时再扩大测试范围。
- 测试只修改已授权的测试与 fixture；不把未运行、失败或环境阻塞的检查写成通过。

## 测试目录与文件组织

- 测试目录按领域对应源码模块。Swift 测试以 `Easydict/Swift/` 为映射根，例如
  `Service/OpenAI/` 对应 `EasydictTests/Service/OpenAI/`；跨模块测试按主要业务归属放置。
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

## 选择 Xcode 验证

根据变更需要证明的结果，选择最小且充分的 Xcode 验证，不按变更行数设置硬阈值。

- 纯治理 Markdown、plan、history、注释，以及不进入 Xcode 构建图的脚本或配置，默认只运行相应
  静态检查。
- 生产源码、工程/workspace、target、build setting、build phase、依赖、entitlement、Info.plist
  或运行时资源发生实质变化时，运行覆盖受影响配置的 `xcodebuild build`。
- 修复 bug、修改可测试行为或测试源码及其 target 引用时，运行覆盖相应行为、suite 或方法的
  `xcodebuild test`。
- `xcodebuild build` 只证明构建集成；`xcodebuild test` 会构建测试所需产物。相同配置的成功测试
  已覆盖编译时不重复运行 build；测试未覆盖的 Release、Archive、签名或其他配置另行验证。
- 重复运行兼容的测试时，可先使用 `build-for-testing`，再使用 `test-without-building`；前者本身
  不构成测试通过证据。
- 并发判据是构建目录，不是构建入口：同一 workspace 与同一 DerivedData 的并发构建，无论来自
  Xcode IDE 还是 `xcodebuild`，都会互相破坏增量状态和 build database；DerivedData 不同就可以
  同时构建。
- agent 运行 `xcodebuild` 时始终显式指定 `-derivedDataPath`，指向与 Xcode 默认目录不相交的
  agent 专用目录，因此 agent 与本地 Xcode 可以在同一个 checkout 上同时编译而互不干扰。
- 专用目录按 checkout 派生，默认位置为
  `~/Library/Developer/Xcode/DerivedData/Easydict-Agent/<checkout-id>`；同一 checkout 复用固定
  路径的增量产物，不同 checkout 互不相交。权限或缓存损坏时删除该目录重建，不切换到 Xcode
  默认 DerivedData。
- `xcodebuild test` 会启动 `Easydict-debug.app` 测试宿主，同 bundle id 的进程共享 UserDefaults、
  沙盒容器和全局注册；不要与 Xcode 的 Run/Test 同时运行，构建与 Archive 不受此限制。

## 常用命令

```bash
# 每个 checkout 一个 agent 专用 DerivedData，与 Xcode 默认目录互不相交
set -o pipefail
checkout_id="$(git rev-parse --show-toplevel \
  | sed -e "s|^$HOME/||" -e 's|^\.||' -e 's|/|_|g')"
agent_dd="$HOME/Library/Developer/Xcode/DerivedData/Easydict-Agent/$checkout_id"

# Build
xcodebuild build \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -derivedDataPath "$agent_dd" | xcbeautify

# Test all tests
xcodebuild test \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -derivedDataPath "$agent_dd" | xcbeautify

# Build for repeated test runs
xcodebuild build-for-testing \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -derivedDataPath "$agent_dd" | xcbeautify

# Run a test suite after a compatible build-for-testing
xcodebuild test-without-building \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -derivedDataPath "$agent_dd" \
  -only-testing:EasydictTests/UtilityFunctionsTests | xcbeautify

# Run one test method after a compatible build-for-testing
xcodebuild test-without-building \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -derivedDataPath "$agent_dd" \
  -only-testing:EasydictTests/UtilityFunctionsTests/testAES | xcbeautify
```

使用 `xcbeautify` 时启用 `pipefail`，保留 `xcodebuild` 的真实退出状态。所有命令使用同一个 agent
专用 DerivedData；需要重建时只删除该目录，不切换到 Xcode 默认目录，也不删除其他 checkout 或
Xcode 自己的 DerivedData。

## 非 Xcode 检查

- 每次变更运行 `git diff --check`。
- 对变更的 `.xcstrings` 或 JSON 数据运行 `jq -e .`。
- 对变更的 Shell 脚本运行 `bash -n`。
- 纯治理 Markdown 默认运行格式、相对链接、锚点和规则语义检查。
