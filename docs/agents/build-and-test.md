# 构建与测试

## 测试范围

- 对有实际行为或正确性风险的变更添加或更新测试，优先验证生产行为和边界条件。
  跳过简单透传、明显 accessor、已有充分覆盖的行为及仅重复实现逻辑的断言。
- 纯视觉调整不要求新增自动测试；UI 交互、状态转换及回归风险按实际行为选择验证。
- 避免为低价值测试添加仅供测试使用的 protocol、mock、override 或侵入式生产 hook。
- 先完成对应范围的检查；通过后仅在新变更、失败或未解决风险出现时扩大或重复验证。
  验证失败先诊断，在授权范围内修复并复验，不跳过必要检查，也不因失败自动停止修复。

## 测试子代理

- 有价值的测试编写或复杂独立验证可委派给 `tester`，配置以
  [`.codex/agents/tester.toml`](../../.codex/agents/tester.toml) 为准；简单检查由主 Agent
  完成。生产实现与测试可独立推进时优先分工，不能独立时先稳定实现再交接验证。
- 委派时传递用户目标、有效授权、行为预期、允许修改的测试与 fixture 路径、当前
  变更和验证范围。子代理保留其他 Agent 的工作，不扩大路径、不递归委派、不交付 Git。
- 主 Agent 协调共享 checkout 和构建时机。测试代码可独立编写，但运行验证前应确认
  相关实现已稳定；同一 workspace 不并发执行 Xcode 构建或测试。
- `workspace-write` 只是沙箱能力，不代表修改整个仓库的授权。只读任务只分析；
  独立验证任务默认不改测试；获准编写测试时才修改分配的测试文件及 fixture。
- `tester` 返回修改路径、实际命令、结果及失败或阻塞证据；生产缺陷交回主 Agent，
  主 Agent 负责修复、复核、history 和最终交付。
- 无法发现 custom agent 时，主 Agent 读取 TOML 的模型、推理强度与完整指令，使用
  显式参数调用并说明回退。工具或配置不可用时由主 Agent 完成必要验证；用户指定
  精确模型为硬性条件时报告无法满足的部分，不静默替换。

## 任务收尾：独立 review 与测试

- 有实际行为风险的 implementation 初步完成后，优先同时启用只读 `reviewer` 和
  `tester`：前者使用 `.agents/skills/review/SKILL.md`，后者编写必要测试并验证。
  reviewer 配置为 `.codex/agents/reviewer.toml`，固定使用 `gpt-6-astra` / `high`；
  tester 使用 `gpt-5.6-terra` / `high`。模型与推理强度以各自 TOML 为准，
  不随主任务模型切换。简单文档、低风险配置或小改动不机械启动两个子代理。
- 主 Agent 在第一次写入前保存初始 HEAD、分层 diff、任务相关 untracked 内容与路径
  归属；交接时给出行为目标、允许范围和冻结实现快照。reviewer 独立判断，不能只
  读取作者总结。tester 只写分配的测试/fixture，主 Agent 暂停相关生产编辑直至首轮
  结果返回；必须修改时通知两者快照失效。
- 首轮可并行审查实现与编写测试。完成后主 Agent 核验 finding，在已有实施授权内
  修复真实问题；无根据或超范围建议说明原因，不盲从。新测试及修复交 reviewer 增量
  复核，由 tester 运行受影响的回归。最终两个结果覆盖同一最终内容快照，再进入交付。
- 不设“固定两轮后通过”；有新修复就按风险复验，没有新变化不重复空转。有效阻塞
  finding、失败验证或必要证据缺失时不能声称完成，也不能自动提交；继续可修复部分，
  需产品决策或新增授权时报告具体阻塞。
- 不可委派时主 Agent 完成必要审查/验证并说明独立性缺失。custom reviewer 不可发现时，
  读取其 TOML 的模型、推理强度与完整指令，以相同配置的只读子任务显式回退，
  不声称已加载 custom role。无法满足配置时说明原因，不静默替换；用户将精确配置
  设为硬性要求时报告受阻部分，否则由主 Agent 完成必要审查并说明降级。
  reviewer 不递归委派、不修复、不处理 GitHub；远程动作由获准的 PR 适配器执行。
- 单独 review 默认只读；此收尾规则不将 review、planning 或 staged 提交请求升级为
  修复任务，也不授权改写用户 staged 代码。测试运行的共享 workspace 约束仍然有效。

## 运行 Xcode 验证的条件

满足以下任一条件时运行 `xcodebuild`：

- Swift、Objective-C 或其他由 Xcode 编译的应用源码发生超过 100 行实质性变更。
  文档、脚本、注释和工程元数据不计入此阈值。
- 新增或修改了 `EasydictTests/**/*.swift` 下的测试源码。
- 用户明确要求构建或测试。

上述条件是默认最低要求，不是风险判断的上限。少量高风险源码、工程配置或依赖修改
也应选择必要的构建或针对性测试。纯治理 Markdown、子代理配置或文档合并使用静态
检查，不因此运行应用构建；PR review 的构建授权遵循根 AGENTS.md。

在实现完成后再评估该阈值。统计任务变更 diff 中新增和删除的实质性行数，排除空行
及无关的既有变更。如果实现再次变化，重新计算。

不要针对同一个 workspace 和 DerivedData 位置并发运行 `xcodebuild`。如果默认
DerivedData 位置不可用，则使用外部临时目录，并在验证后删除。

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

如果已知变更对应的测试映射，使用 `-only-testing:`。如果映射不明确，则运行相关
的更大范围测试目标。所有经 `xcbeautify` 的命令都在启用 `pipefail` 的 shell 中运行，
保留真实退出状态。`test-without-building` 仅用于与当前源码和配置兼容的构建产物；
不能用旧产物验证新修改。测试源码变化时运行对应范围的 `xcodebuild test`。

## 非 Xcode 检查

- 每次变更都运行 `git diff --check`。
- 对变更的 `.xcstrings` 或 JSON 数据（如适用）运行 `jq -e .`。
- 对变更的 Shell 脚本运行 `bash -n`。
- Swift 源码发生变化时运行 `swiftformat --lint` 或仓库现有格式化工具。
