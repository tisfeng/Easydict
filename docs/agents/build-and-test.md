# 构建与测试

## 测试与验证原则

- 只有用户在当前任务中明确要求添加测试，才允许新增或扩写测试，包括测试文件、suite、用例、断言、
  fixture、mock、helper 和仅为测试引入的生产代码 hook；修复 bug、新增功能、修改复杂逻辑和回归
  风险都不构成授权。
- 未获授权时可以运行和分析现有测试，认为需要补充时只在结果中提建议；获授权后优先更新现有用例，
  遵循最小范围，不为测试简单实现增加生产抽象、mock 或 hook。
- 优先运行直接覆盖变更风险的检查，影响范围不明确时再扩大；只修改已授权的测试与 fixture，不把
  未运行、失败或环境阻塞的检查写成通过。

## 测试与工程文件组织

- 测试目录按领域对应源码模块，Swift 测试以 `Easydict/Swift/` 为映射根，例如 `Service/OpenAI/`
  对应 `EasydictTests/Service/OpenAI/`；跨模块测试按主要业务归属放置，现有目录按任务范围渐进调整。
- 每个测试文件聚焦一个主要被测类型或行为领域，最多声明一个 `@Suite`；接近文件规模限制时按职责
  拆分 suite 和 fixture，保留原有覆盖和标签、actor 隔离、共享状态恢复、串行边界。独立 suite 的
  `.serialized` 不提供跨 suite 串行保证。
- 单文件 helper 保持局部，同领域共享工具就近放置，跨目录复用的 fixture 或工具放入
  `EasydictTests/Support/<Domain>/`，资源放入对应测试资源目录。
- 新增、移动或删除由 Xcode 管理的源码文件或运行时资源时，同步
  `Easydict.xcodeproj/project.pbxproj` 中的 group、文件和 build phase 引用，测试文件同时同步测试
  target 的 Sources，删除文件不保留悬空引用。仓库治理 Markdown、plan、history、skill、参考资料
  和 `docs/` 下的公共 Markdown 不需要工程引用，除非作为运行时资源发布。

## 选择验证

根据变更需要证明的结果选择最小且充分的验证，不按变更行数设置硬阈值。

- 纯治理 Markdown、plan、history、注释，以及不进入 Xcode 构建图的脚本或配置，只运行相应静态
  检查：Markdown 的格式、相对链接、锚点和规则语义检查。
- 生产源码、工程/workspace、target、build setting、build phase、依赖、entitlement、Info.plist
  或运行时资源发生实质变化时，运行覆盖受影响配置的 `xcodebuild build`；修复 bug、修改可测试
  行为或测试源码及其 target 引用时，运行覆盖相应行为、suite 或方法的 `xcodebuild test`。
- `xcodebuild build` 只证明构建集成；相同配置的成功测试已覆盖编译，不重复运行 build，测试未覆盖
  的 Release、Archive、签名或其他配置另行验证。重复运行兼容的测试时先 `build-for-testing`，再
  用 `test-without-building`，前者本身不构成测试通过证据。
- 每次变更运行 `git diff --check`；对变更的 `.xcstrings` 或 JSON 运行 `jq -e .`，对变更的 Shell
  脚本运行 `bash -n`。
- 并发判据是构建目录而不是构建入口：同一 workspace 与同一 DerivedData 的并发构建，无论来自
  Xcode IDE 还是 `xcodebuild`，都会互相破坏增量状态和 build database；DerivedData 不同可以并行。
- 因此 agent 运行 `xcodebuild` 时始终显式指定 `-derivedDataPath`，指向按 checkout 派生、与 Xcode
  默认目录不相交的 `~/Library/Developer/Xcode/DerivedData/Easydict-Agent/<checkout-id>`；损坏时
  删除该目录重建，不切换到 Xcode 默认 DerivedData。
- `xcodebuild test` 会启动同 bundle id 的 `Easydict-debug.app` 测试宿主，不要与 Xcode 的 Run/Test
  同时运行；构建与 Archive 不受此限制。

## 常用命令

```bash
# 每个 checkout 一个 agent 专用 DerivedData，与 Xcode 默认目录互不相交
set -o pipefail
checkout_id="$(git rev-parse --show-toplevel | sed -e "s|^$HOME/||" -e 's|^\.||' -e 's|/|_|g')"
agent_dd="$HOME/Library/Developer/Xcode/DerivedData/Easydict-Agent/$checkout_id"

# 构建
xcodebuild build \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -derivedDataPath "$agent_dd" | xcbeautify

# 运行测试
xcodebuild test \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -derivedDataPath "$agent_dd" | xcbeautify

# 构建可复用的测试产物
xcodebuild build-for-testing \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -derivedDataPath "$agent_dd" | xcbeautify

# 复用已构建产物运行指定 suite 或方法，-only-testing 支持 <Suite> 与 <Suite>/<test>
xcodebuild test-without-building \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -derivedDataPath "$agent_dd" \
  -only-testing:EasydictTests/UtilityFunctionsTests | xcbeautify
```

`xcbeautify` 依赖 `pipefail` 才能保留 `xcodebuild` 的真实退出状态。重建时只删除当前 checkout 的
`agent_dd`，不动 Xcode 默认目录或其他 checkout。
