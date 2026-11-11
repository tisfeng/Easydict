# 修复 Bing 可选 Cookie 的验证按钮

- 状态：completed
- 创建日期：2026-10-24
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

## 背景

Bing 的 Cookie 可选，但设置组件将监听字段全部当作必填字段，导致空 Cookie 时无法验证。

## 目标与范围

- 目标结果：空 Cookie 可以验证，验证期间禁止重复点击。
- 允许修改路径：BingService.swift、ServiceConfigurationSecretSectionView.swift、Localizable.xcstrings 及本任务 plan/history。
- 同任务 history：`docs/histories/2026-10/2026-10-24-bing-optional-cookie-validation.md`
- 用户限制：验证后本地提交，不 push；保持当前 checkout 状态。
- 非目标：修改 Bing 网络请求流程、迁移视图架构、新增测试。
- 验收标准：区分监听与必填字段，默认保留其他服务行为，所有现有语言标注 Cookie 可选，相关现有测试通过。

## 工作计划

1. 增加独立必填字段参数，Bing 使用空列表；补充验证中按钮保护。
2. 更新现有本地化，运行定向测试和静态检查。
3. 使用 review 技能审查变更，更新 history、归档计划并本地提交。

## 风险与决策

- 必填字段默认使用监听字段，避免放开其他服务的密钥校验。
- 仓库规则禁止未明确授权的新增测试，运行现有 Bing suite；按钮状态按源码检查，说明验证边界。

## 进度

- [x] 实现及本地化。
- [x] 验证及审查。
- [x] history 与计划归档；本地提交随本记录交付。

## 验证

- `git diff --check`、`jq -e . Easydict/App/Localizable.xcstrings`：通过。
- 定向 `xcodebuild test -only-testing:EasydictTests/BingServiceTests`：通过（2 项测试），使用 checkout 专用 DerivedData，覆盖 Debug 编译。
- 构建内 SwiftLint：429 个文件、0 violations。
- review：以 `63463ee1cf9e55a88b24261df4854710f5cf6d17` 为基线，审查本次三个生产文件差异及相关调用者，未发现有效 finding。
- 源码核对：Cookie 空值、填写及再次清空均不阻止 Bing 验证；验证中禁用并防重入；百度与腾讯沿用必填字段。
- 限制：现有 Bing 测试覆盖服务响应处理，不覆盖按钮 UI；未替换其他构建目录正在运行的用户实例，未执行 UI 实测或真实 Bing 联网验证。
- 初次依赖准备曾被主动中断以复用本机同版本缓存；最终完整测试退出码为 0。

## 完成条件

- 实现满足验收标准，必要检查通过，无有效未修复 finding；更新 history 并归档。
