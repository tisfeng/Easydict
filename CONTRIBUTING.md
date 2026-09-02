# Contributing / 贡献指南

- [English](#english)
- [简体中文](#简体中文)

## English

Easydict welcomes contributions through issues and pull requests.

### How to contribute

- Search existing issues before reporting a defect. Include reproducible steps, the
  expected and actual result, version information, and any logs or screenshots
  that can be shared safely.
- Discuss large feature, UI, or architecture changes before implementation.
- Keep each pull request focused. Do not include unrelated cleanup, local
  configuration, secrets, or user data.

### Build from source

Start with the [Developer Build Guide](docs/user-docs/en/GUIDE.md#developer-build).
Open `Easydict.xcworkspace` in Xcode, select the `Easydict` scheme, and build or
run from the workspace rather than `Easydict.xcodeproj`.

### Pull requests

- Submit to `dev` unless a maintainer specifies another target branch.
- Use a `type/short-description` branch name in kebab-case, such as
  `feat/openai-translation` or `fix/ocr-window-focus`. Do not commit directly
  to `dev` or `main`.
- Use Angular-style commit messages and keep each commit semantically focused.
- List related issues in the PR template. Do not use GitHub auto-closing keywords
  or an auto-closing Development sidebar link.
- Describe the purpose, main changes, affected scope, and verification. Include
  screenshots or recordings for UI changes, and update applicable tests and user
  documentation when behavior changes.

### Further reading

- [Developer Build Guide (English)](docs/user-docs/en/GUIDE.md#developer-build)

## 简体中文

欢迎通过 issue 和 Pull Request 参与 Easydict 的改进。

### 如何参与

- 报告缺陷前，请先搜索已有 issue，并提供复现步骤、预期与实际结果、版本信息，以及可安全公开的日志或截图。
- 较大的功能、界面或架构变更，请先讨论目标和用户体验，再开始实现。
- 每个 Pull Request 保持聚焦，不混入无关清理、本地配置、密钥或用户数据。

### 从源码构建

请先阅读[开发者构建指南](docs/user-docs/zh/GUIDE.md#开发者构建)。使用 Xcode 打开
`Easydict.xcworkspace`，选择 `Easydict` scheme 后编译或运行；请使用 workspace，而不是
`Easydict.xcodeproj`。

### 提交 Pull Request

- 默认向 `dev` 提交；维护者指定其他目标分支时以其为准。
- 分支使用 `类型/简短描述` 的 kebab-case 格式，例如 `feat/openai-translation` 或
  `fix/ocr-window-focus`；请勿直接在 `dev` 或 `main` 上提交。
- 提交使用 Angular-style 格式，并保持单个提交语义聚焦。
- 请在 PR 模板的“关联 Issue”区域填写相关 Issue；请勿使用 GitHub 自动关闭关键字或
  Development 侧栏的自动关闭关联。
- 说明目的、主要变化、影响范围和验证结果。UI 变化请附截图或录屏；行为变化请同步必要测试和用户文档。

### 详细文档

- [开发者构建指南（简体中文）](docs/user-docs/zh/GUIDE.md#开发者构建)
- [架构与源码定位](docs/architecture/overview.md)
- 使用 Coding Agent：[AGENTS.md](AGENTS.md)
