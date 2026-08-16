# 构建与测试

## 运行 Xcode 验证的条件

满足以下任一条件时运行 `xcodebuild`：

- Swift、Objective-C 或其他由 Xcode 编译的应用源码发生超过 100 行实质性变更。
  文档、脚本、注释和工程元数据不计入此阈值。
- 新增或修改了 `EasydictTests/**/*.swift` 下的测试源码。
- 用户明确要求构建或测试。

在实现完成后再评估该阈值。统计任务变更 diff 中新增和删除的实质性行数，排除空行
及无关的既有变更。如果实现再次变化，重新计算。

不要针对同一个 workspace 和 DerivedData 位置并发运行 `xcodebuild`。如果默认
DerivedData 位置不可用，则使用外部临时目录，并在验证后删除。

## 常用命令

```bash
# Build
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

如果已知变更对应的测试映射，使用 `-only-testing:`。如果映射不明确，则运行相关
的更大范围测试目标。

## 非 Xcode 检查

- 每次变更都运行 `git diff --check`。
- 对变更的 `.xcstrings` 或 JSON 数据（如适用）运行 `jq -e .`。
- 对变更的 Shell 脚本运行 `bash -n`。
- Swift 源码发生变化时运行 `swiftformat --lint` 或仓库现有格式化工具。
