# Easydict CONTRIBUTING.md 语义移植

- 日期：2026-09-02
- 状态：completed
- 关联计划：[`2026-09-02-easydict-contributing-guide-port.md`](../../exec-plans/completed/2026-09-02-easydict-contributing-guide-port.md)
- 来源：Scoco `ae0ecdf46`、`7d74c756a`、`ae7fa25f4`

## 用户请求

将 Scoco 最新的 `CONTRIBUTING.md` 相关提交合并移植到当前 Easydict，并创建一个本地提交。

## 初始状态

- 分支：`dev`
- `initial_head`：`35e9f6cc2ecfde4ad74eaeb0cb452d42bce4285d`
- 初始暂存区：空
- 初始工作树：干净
- 初始冲突：无

## 变更

- 新增 Easydict 中文 `CONTRIBUTING.md`，将参与方式、源码构建入口、PR 要求和详细文档集中为 GitHub 可发现的根目录入口。
- 将 `README.md` 和 `README_ZH.md` 的贡献段落收束到同一指南；英文 README 明确说明其链接目标为中文，保留既有 AI 编程和 Issue/PR 处理说明。
- 保留 Easydict 的 `dev`、分支命名、Angular-style、关联 Issue、验证和 UI 截图契约；未复制 Scoco 的产品、环境或发布事实。
- 经用户复核，取消先前不完整的双语镜像，改为遵循来源最终结构：中文贡献指南承载完整规则，英文 README 明确指向该中文指南。

## 适配决策

- 三个来源提交是一次“扩展、纠正环境前置、收敛”的连续编辑过程，因此按 `ae7fa25f4` 的最终简洁结构合并为一个 Easydict 提交，而非直接 cherry-pick。
- 构建入口链接现有中文 Developer Build Guide；不将 Bundler、常规 `pod install`、签名配置或 CocoaPods 故障排查重复为首次构建前置条件。
- 来源的英文 README 明确指向中文贡献指南；Easydict 复用该结构，而不是维护缺少架构和 Agent 文档译本的双语镜像。
- 既有中英文 GUIDE 的详细贡献章节不在本次来源差异范围内，保持不变以避免无关公共文档重构。

## 验证

- `git diff --check`：通过。
- Markdown 相对链接：通过；所有新增本地目标存在，英文 README 和中文 README 均可定位到根目录贡献指南。
- 贡献契约和负向扫描：通过；保留 Angular-style、分支命名、关联 Issue、UI 截图和 `AGENTS.md`，公开入口未出现 Scoco、`Scoco.xcworkspace`、macOS 14.6、`README_EN.md`、`changelog.md`、Bundler 或常规 `pod install`。
- 语言结构复查：通过；根目录贡献指南为完整中文文档，英文 README 明确标注链接目标为中文，不存在不对等的语言区块。
- 新增 Markdown 无尾随空白；README 的既有尾随空白行未修改。
- 未运行 `xcodebuild` 或产品测试，因为本次仅修改 Markdown 文档。

## 后续事项

- 本计划已归档；全部变更通过一次本地 Angular-style 提交交付，不 push。
