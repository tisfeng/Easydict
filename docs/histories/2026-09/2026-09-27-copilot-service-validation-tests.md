## 2026-09-27 | 任务：为 GitHub Copilot 服务补充本机验证

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-27-copilot-service-validation-tests.md)

### 执行上下文

- **Agent Name:** Unknown
- **Model:** Unknown
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

### 用户请求

移除构建测试文档中关于集成测试本机环境诊断的段落，新增规则，要求实现者为新服务增加专属验证测试，并补充 GitHub Copilot 服务测试。服务验证可以依赖实现者本机安装和配置的 CLI，且只需由实现者本机运行通过。

### 变更

- 在 `build-and-test.md` 说明新增服务必须有独立验证测试；本机环境相关用例通过非默认 test plan 或 Xcode 精确测试选择运行，不要求所有开发者或 CI 持续执行。
- 删除用户指定的 `.tags(.integration)` 本机环境诊断段落。
- 增加 Copilot 专属测试，覆盖服务契约、工厂注册，以及通过真实服务路径调用本机 Copilot CLI 的翻译验证；默认 scheme 跳过该真实调用，可通过精确测试方法路径主动运行。
- 按用户反馈删除 `EASYDICT_RUN_COPILOT_LOCAL_VALIDATION` 环境变量门控；本机验证直接运行真实测试，不需要设置环境变量。

### 设计意图

将环境依赖的服务验证与默认离线回归区分。实现者可以验证本机 CLI、登录状态和应用调用路径；其他开发者不需要提供个人账户配置即可运行普通测试。

### 验证

- `plutil -lint Easydict.xcodeproj/project.pbxproj`：通过。
- `xmllint --noout Easydict.xcodeproj/xcshareddata/xcschemes/Easydict.xcscheme`：通过。
- `xcodebuild test -scheme Easydict -only-testing:EasydictTests/GitHubCopilotServiceTests/validatesLocalCopilotTranslation()`：真实本机 CLI 翻译用例通过。
- 默认 scheme 下显式跳过真实方法后运行服务 suite：2 项契约与注册测试通过。
- 试验发现 `-only-testing:EasydictTests/GitHubCopilotServiceTests` 会覆盖 scheme 的单项跳过配置并运行整个 suite；最终将本机验证固定为精确方法路径，不把该 suite 运行误报为默认隔离验证。
- `rg EASYDICT_RUN_COPILOT_LOCAL_VALIDATION EasydictTests Easydict.xcodeproj`：无结果。
- 构建阶段的 Format 与 Lint 脚本、`git diff --check`：通过。
- 手动检查：确认 `EasydictApp.swift` 的构建格式副作用已恢复，提交范围不包含该文件。

### 受影响文件

- `docs/agents/build-and-test.md`
- `EasydictTests/Service/GitHubCopilot/GitHubCopilotServiceTests.swift`
- `Easydict.xcodeproj/project.pbxproj`
- `Easydict.xcodeproj/xcshareddata/xcschemes/Easydict.xcscheme`
- `Easydict.xcodeproj/xcshareddata/xctestplans/GitHubCopilotLocalValidation.xctestplan`（删除）
- [执行计划](../../exec-plans/completed/2026-09/2026-09-27-copilot-service-validation-tests.md)

### 后续事项

- None
