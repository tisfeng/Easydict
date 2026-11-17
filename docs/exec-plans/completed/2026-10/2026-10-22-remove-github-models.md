# 移除已退役的 GitHub Models 服务

- 状态：completed
- 创建日期：2026-10-22
- 负责人：Codex
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/issues/1372

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

## 背景

GitHub Models 已退役，应用仍保留服务入口及实现。

## 目标与范围

- 目标结果：移除 GitHub Models 服务类型、实现及专属资源，更新服务文档。
- 允许修改路径：GitHubService.swift、QueryServiceFactory.swift、EZEnumTypes.h/m、Localizable.xcstrings、GitHub.imageset、project.pbxproj、中英文 SERVICES.md 及本任务 plan/history。
- 同任务 history：`docs/histories/2026-10/2026-10-22-remove-github-models.md`
- 用户限制：仅删除服务，不进行旧配置迁移。
- 非目标：更改 LocalStorage、清理用户偏好、自动添加替代服务、新增测试。
- 验收标准：移除可用服务入口及编译引用，保留 GitHub Copilot，通过必要验证和审查。

## 工作计划

1. 删除服务实现、注册、常量、工程引用和专属资源，更新文档。
2. 执行静态检查和构建，运行相关现有离线测试。
3. 审查差异，记录结果并归档计划，创建本地提交。

## 风险与决策

- 按用户要求保留已存储配置，依赖工厂现有的未注册服务跳过逻辑。
- 不修改 GitHub Copilot 或历史 changelog/OCR 样本。

## 进度

- [x] 删除服务及文档入口。
- [x] 完成验证和审查。
- [x] 记录 history 并归档，创建本地提交。

## 验证

- `git diff --check`、`jq -e .` 和 `plutil -lint`：通过。
- `.pbxproj` 解析后语义比较：仅删除服务 group、文件和 Sources 引用。
- String Catalog JSON 比较：仅删除 `github_models`，其余条目一致。
- `xcodebuild test`（专用 DerivedData，`EASYDICT_RELEASE_PACKAGING=YES` 跳过 SwiftFormat）：编译通过；首次方法筛选匹配 0 项，不计为测试通过证据。
- `xcodebuild test-without-building`：修正 Swift Testing 方法选择为 `serviceContract()`、`factoryRegistration()` 后，两项现有 GitHubCopilotServiceTests 测试通过。
- Review：基线 `ebd47acd56155b634e785a87fd72c9213a358275`，检查完整任务差异、工厂未注册类型处理及引用；未发现有效 finding。直接删除已足够，无需引入迁移框架。
- 未执行 UI 手动验证或外部翻译请求；未新增测试。

## 完成条件

- 必要验证通过、无有效未修复 finding，history 与归档计划完整，并完成本地提交。
