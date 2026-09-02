# Easydict CONTRIBUTING.md 语义移植

**Status:** completed
**Created:** 2026-09-02
**Updated:** 2026-09-02
**Owner:** Codex
**Links:** Scoco commits `ae0ecdf46`, `7d74c756a`, `ae7fa25f4`

## 任务契约

- 任务模式：`implementation`
- 用户目标：将 Scoco 最新三个与 `CONTRIBUTING.md` 相关提交的最终语义合并移植到 Easydict。
- 允许动作：新增根目录中文贡献指南，更新两个 README 的贡献入口，创建本计划与 history，运行文档级验证并自动创建本地提交。
- 允许修改路径：`CONTRIBUTING.md`、`README.md`、`README_ZH.md`、`docs/exec-plans/`、`docs/histories/2026-09/`。
- 禁止动作：不直接 cherry-pick；不修改产品代码、Xcode 工程、用户 GUIDE、PR 模板、`AGENTS.md` 或外部服务；不 push、pull、rebase 或 merge。
- 验收标准：中文贡献入口可发现、英文 README 明确说明指南语言、Easydict 专属 PR 契约保留、Scoco 专属事实未混入、静态文档验证通过。

## 初始状态

- 仓库：Easydict
- 分支：`dev`
- `initial_head`：`35e9f6cc2ecfde4ad74eaeb0cb452d42bce4285d`
- 初始暂存区：空
- 初始工作树：干净
- 初始冲突：无
- 自动提交资格：`eligible`，验证和精确暂存通过后执行一次本地提交。

## 来源与适配

- `ae0ecdf46` 建立贡献者入口与 README 引导；仅采纳该方向。
- `7d74c756a` 移除 Bundler 和常规 `pod install` 前置；采用其“构建入口保持简洁”的语义。
- `ae7fa25f4` 将指南收束为参与方式、源码入口、PR 要求和详细文档；作为最终结构依据。
- Easydict 使用 `README.md` 和 `README_ZH.md`，不引入 Scoco 的 `README_EN.md`、`changelog.md`、macOS 14.6、`Scoco.xcworkspace` 或 `Scoco` scheme。

## 实施步骤

- [x] 根据来源最终结构将 `CONTRIBUTING.md` 整理为中文指南，并链接现有中文 Developer Build Guide。
- [x] 将两个 README 的贡献段落收束到根目录贡献指南入口。
- [x] 创建并更新同任务 history，运行 Markdown 和 Git 静态验证。
- [x] 将本计划归档到 `completed/`，精确暂存并自动创建一个本地 Angular-style 提交。
- [x] 取消不完整的双语镜像；英文 README 明确链接中文贡献指南，中文 README 链接同一文件。

## 风险与决策

- 用户 GUIDE 中已有贡献细则；本次只链接而不重写，避免扩大为公共文档重构。
- 根指南只保留稳定入口和 PR 契约；签名、依赖维护与 CocoaPods 故障排查继续由 Developer Build Guide 维护。
- `AGENTS.md` 保持 Coding Agent 的唯一入口，本中文指南只提供链接而不复制其执行规则。
- 来源最终指南与其英文 README 使用“英文 README 指向中文指南”的结构；Easydict 采用同一结构，避免维护不完整的英文镜像。

## 验证

- `git diff --check`：通过。
- 新增 Markdown 的相对链接：通过；`CONTRIBUTING.md` 和所有详细文档目标均存在。
- 公开贡献入口的范围扫描：通过；保留 Angular-style、分支命名、关联 Issue、UI 截图和 `AGENTS.md`，未混入 Scoco 专属事实。
- 语言结构复查：`CONTRIBUTING.md` 只含中文正文和中文详细文档入口；英文 README 明确说明其链接目标为中文贡献指南。
- 变更路径：通过；仅包含任务契约中的 README、贡献指南、plan 和 history 路径。
- README 既有的第 5、14 行尾随空白未修改；新增内容无尾随空白。
- 不运行：`xcodebuild` 或产品测试，因为本次仅修改 Markdown 文档。
