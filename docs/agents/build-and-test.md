# 构建与测试

## 测试与验证原则

- 除新增服务外，仅在用户当前明确授权时新增或扩写测试及其配套 fixture、mock、helper 或生产 hook。
  未获授权可运行、分析现有测试，并在交付时建议补充。获授权时优先扩展现有用例，避免为简单实现
  增加生产抽象、mock 或 hook。
- 服务测试必须调用真实服务，使用实际可用的 endpoint，并从用户本机配置读取所需的 API key、
  登录态或 CLI 配置。禁止在测试代码中写入真实密钥、伪造 endpoint 或凭据，以及用模拟响应代替
  真实服务结果。测试必须对实际返回的译文、识图文本等关键结果做断言。缺少本机配置时，明确记录
  跳过原因。跳过的用例计为未验证。
- 新增服务必须有专属验证测试文件，并由实现者在本机运行通过。依赖 CLI、登录态、密钥、语言包等本机配置的
  测试标记为 `.tags(.requiresLocalEnvironment)`。测试套件中只有部分用例依赖本机时，将标签加在
  对应的 `@Test` 上。
- `Easydict` scheme 的共享默认计划 `Default` 排除该标签。`LocalEnvironment` 只选择该标签。
  在 Xcode 中通过 **Product > Test Plan > LocalEnvironment** 切换计划，再点击用例旁的运行按钮。
  完成后切回 `Default`，因为 ⌘U 使用当前选中的计划。
- 命令行可通过 `-testPlan LocalEnvironment` 选择计划，再用
  `'-only-testing:EasydictTests/CodexFormulaImageTests/testRecognizesFormulaImage()'` 选择一个用例。

## 测试与工程文件组织

- 测试按主要业务归属映射源码目录，例如 `Easydict/Swift/Service/OpenAI/` 对应
  `EasydictTests/Service/OpenAI/`。现有目录随任务渐进调整。
- 每个测试文件聚焦一个类型或行为领域，最多一个 `@Suite`。接近文件规模限制时按职责拆分，
  保留覆盖、标签、actor 隔离、共享状态恢复与串行边界。`.serialized` 只在单个 suite 内生效。
- 单文件 helper 留在本地，同领域工具就近放置，跨目录复用的工具和 fixture 放入
  `EasydictTests/Support/<Domain>/`，资源放入对应测试资源目录。
- 新增、移动或删除 Xcode 管理的源码或运行时资源时，同步 `Easydict.xcodeproj/project.pbxproj`
  的 group、文件和 build phase 引用，包括测试 target 的 Sources。文档仅在作为运行时资源发布时加入工程。

## 选择验证

按变更风险选择最小充分的检查，影响范围不清时再扩大。报告实际结果，区分通过、失败、未运行和受阻。

- 仅改文档、注释或 Xcode 构建图之外的脚本与配置时，做相应静态检查。Markdown 检查格式、相对链接、
  锚点和规则一致性。每次变更运行 `git diff --check`，变更的 `.xcstrings` 或 JSON 用 `jq -e .`，
  Shell 脚本用 `bash -n`。
- 生产源码、工程配置、依赖或运行时资源有实质变化时，用 `xcodebuild build` 覆盖受影响配置。
  修复 bug 或修改可测试行为、测试源码及其 target 引用时，用 `xcodebuild test` 覆盖相关行为。
  同配置测试通过即可覆盖构建检查，Release、Archive、签名等未覆盖项另行验证。
- 重复运行兼容测试时，先 `build-for-testing` 生成产物，再用 `test-without-building` 验证结果。
- 每次运行 `xcodebuild` 均显式指定 `-derivedDataPath`，使用当前 checkout 专属的
  `~/Library/Developer/Xcode/DerivedData/Easydict-Agent/<checkout-id>`。并行构建须使用不同
  DerivedData。目录损坏时只删除当前 checkout 的 `agent_dd` 并重建。
- 构建、运行和测试沿用项目 bundle ID，除非用户明确要求覆盖 `PRODUCT_BUNDLE_IDENTIFIER`。
  构建、测试和归档由 Xcode 管理 `ENABLE_PREVIEWS`，Agent 不通过命令行或环境变量设置。
  常规构建和测试按项目配置运行 SwiftFormat。

## 应用实例与界面验证

- `xcodebuild test` 和 `test-without-building` 使用独立测试宿主。按偏好、文件、快捷键等共享资源的
  实际冲突决定是否隔离或串行。仅运行测试时保留用户的调试会话。
- 界面验收只复用本次构建的实例。新构建完成后，核对 bundle ID、产物路径、PID 和实例数，
  无需询问，直接停止目标 Easydict Debug 应用或其 Xcode 调试会话。确认退出后按新产物路径启动并复核进程。
  自动替换仅限目标 Debug 实例。多实例启动（`open -n`）须由用户明确要求。
- 区分测试宿主和应用实例。目标不明、旧实例未退出或自动化异常时暂停启动，仅查询进程排查，
  并继续其余可执行的验证。
- 验收结束后，仅退出本任务启动的实例并恢复临时设置。需要恢复原应用时，按原路径启动一次并查询确认。

### 界面验证与截图

凡是改变用户可见结果或交互的改动，交付前须实测并截图。PR 审查以准确的 head 构建实测，
并在审查授权内报告发现。

1. 用固定、脱敏的输入从正常入口走通受影响路径，实测关键边界和交互。记录构建对应的提交或
   工作区状态。受阻时注明原因、已有证据和缺失场景。
2. 截取相关窗口或区域并检查效果。有必要对照时使用相同输入、窗口宽度和主题。截图无法证明的
   操作另记实测结果，必要时录屏。修复后用最终构建重测并重新截图。
3. 将脱敏截图存到仓库外，交付时内嵌关键截图并注明场景、输入和结果。区分本次实测、单测、
   CI、作者截图和未验证场景。

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

保留 `set -o pipefail`，以便通过 `xcbeautify` 输出时仍能发现 `xcodebuild` 失败。
