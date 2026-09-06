# 贡献指南

欢迎通过 issue 和 Pull Request 参与 Easydict 的改进。

## 如何参与

- 报告缺陷前，请先搜索已有 issue，并提供复现步骤、预期与实际结果、版本信息，以及可安全公开的日志或截图。
- 较大的功能、界面或架构变更，请先讨论目标和用户体验，再开始实现。
- 范围明确的小修复、文档、本地化和测试改进可以直接提交 PR。
- 每个 PR 保持聚焦，不混入无关改动、本地配置、密钥或用户数据。

## 开始开发

从源码构建请参阅[开发者构建指南](docs/user-docs/zh/GUIDE.md#开发者构建)。使用 Xcode
打开 `Easydict.xcworkspace`，选择 `Easydict` scheme 后编译或运行；请使用 workspace，
而不是 `Easydict.xcodeproj`。

## 提交 Pull Request

- 默认向 `dev` 提交；维护者指定其他目标分支时以其为准。
- 分支使用 `类型/简短描述` 的 kebab-case 格式，例如 `feat/openai-translation` 或
  `fix/ocr-window-focus`；请勿直接在 `dev` 或 `main` 上提交。
- 提交使用 Angular-style 格式，并保持单个提交语义聚焦。
- 请在 PR 模板的“关联 Issue”区域填写相关 Issue；请勿使用 GitHub 自动关闭关键字或
  Development 侧栏的自动关闭关联。
- PR 应说明目的、主要变化、影响范围和验证结果。UI 变化请附截图或录屏；行为变化请同步必要测试和用户文档。

## 详细文档

- [开发者构建指南](docs/user-docs/zh/GUIDE.md#开发者构建)
- [架构与源码定位](docs/architecture/overview.md)
- [构建与测试](docs/agents/build-and-test.md)
- [Xcode 工程](docs/agents/swift-xcode.md)
- [本地化](docs/agents/localization.md)
- [代码质量](docs/agents/code-quality.md)
- 使用 Coding Agent：[AGENTS.md](AGENTS.md)
