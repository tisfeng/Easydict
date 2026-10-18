# GitHub Copilot 服务验证测试

- 状态：completed
- 创建日期：2026-09-27
- 负责人：Unknown
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** Unknown
- **Model:** Unknown
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

## 背景

构建与测试规则当前解释了全服务集成测试的本机依赖，但用户要求移除该段，并补充新增服务时由实现者在本机完成专属验证的要求。GitHub Copilot 服务依赖本机安装并登录的 CLI，验证应能覆盖实际服务调用路径，同时避免默认要求其他开发者或 CI 提供 Copilot 账户。

## 目标与范围

- 目标结果：更新测试规范并新增一个通过 Xcode 精确测试选择运行的 GitHub Copilot 本机验证测试。
- 允许修改路径：`docs/agents/build-and-test.md`、`EasydictTests/Service/GitHubCopilot/`、`Easydict.xcodeproj/xcshareddata/xcschemes/` 及本任务 plan/history。
- 同任务 history：`docs/histories/2026-09/2026-09-27-copilot-service-validation-tests.md`
- 用户限制：本机真实 CLI 验证由实现者运行；默认测试流程不要求每位开发者或 CI 拥有 Copilot 登录态。
- 非目标：修改 GitHub Copilot 生产服务行为或引入测试专用生产抽象。
- 验收标准：测试规则符合用户说明；Copilot 有专属测试文件；专属入口直接验证本机真实服务翻译，不使用环境变量门控；测试文件正确加入 Xcode 测试 target。

## 工作计划

1. 删除旧集成测试环境诊断段落，增加新增服务本机专属验证规则。
2. 新增 Copilot 专属测试，覆盖服务契约和真实本机验证；由默认 scheme 排除真实调用，通过精确方法路径主动运行。
3. 注册 Xcode 测试源文件，运行本机真实验证及默认 scheme 的隔离检查，完成 Review、history 和本地提交。

## 风险与决策

- 真实 Copilot 验证依赖当前用户 CLI、登录态、网络和账户配额；默认 scheme 跳过真实调用，使用精确 `-only-testing` 方法路径单独运行，不使用环境变量门控。
- 验证将使用应用实际的 `GitHubCopilotService.validate()` 调用链，不以单独运行 CLI 的 smoke test 冒充产品路径验证。

## 进度

- [x] 文档规则和 Copilot 测试已实现。
- [x] 精确本机验证已通过，默认 scheme 已配置跳过真实调用；差异审查、history 与计划归档已完成。

## 验证

- `plutil -lint Easydict.xcodeproj/project.pbxproj`：通过。
- `xmllint --noout Easydict.xcodeproj/xcshareddata/xcschemes/Easydict.xcscheme`：通过。
- `xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict -only-testing:EasydictTests/GitHubCopilotServiceTests/validatesLocalCopilotTranslation()`：真实本机 CLI 翻译用例通过。
- 默认 scheme 对真实本机调用的排除由 `Easydict.xcscheme` 中的 `SkippedTests` 配置；显式选择精确测试方法会运行该用例，不使用环境变量。
- `rg EASYDICT_RUN_COPILOT_LOCAL_VALIDATION EasydictTests Easydict.xcodeproj`：无结果。
- 默认 scheme 下显式跳过真实方法后运行服务 suite：2 项契约与注册测试通过。
- 构建阶段的 Format 与 Lint 脚本、`git diff --check`：通过。

## 完成条件

- 专属验证可通过精确测试方法选择运行，并在当前本机登录环境中通过。
- 离线契约测试和目标 test target 构建通过。
- 变更范围为文档、测试及 Xcode 测试配置；完成提交前差异审查。
- plan 归档且 history 完成。
