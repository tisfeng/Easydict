# Urdu 界面本地化

- 状态：completed
- 创建日期：2026-10-23
- 负责人：Codex
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/pull/1374

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode Unknown (Unknown)`

## 背景

上游 dev 已有 Urdu 翻译语言及部分服务映射，但没有 Urdu 界面资源。当前 checkout 干净，
首次写入前 HEAD 与最新上游 dev 都为 `8d80bfa219dde99c9c1f2760b59b2df72ad4adef`。

## 目标与范围

- 目标结果：以 `ur` 提供完整应用目录和权限描述，允许在界面选择 Urdu。
- 允许修改路径：两个 App String Catalog、LanguageState、EasydictApp、EZTextView、对应测试、
  Xcode 工程和本任务记录。
- 同任务 history：`docs/histories/2026-10/2026-10-23-urdu-localization.md`
- 用户限制：保留无关工作；不付费调用 API；只推送 fork 任务分支，不合并或发布。
- 非目标：新增服务、OCR 引擎、字体、依赖或承诺 Urdu OCR/TTS 能力。
- 验收标准：覆盖适用源字符串，保留占位符和现有语言；验证 locale 注册与文本自然方向；
  完成审查、提交并在可用权限和验证范围内交付上游 PR。

## 工作计划

1. 核对贡献规则、上游 dev、历史本地化贡献和 Urdu 服务支持。
2. 维护一致术语，翻译两个 catalog 并注册 `ur`，修正具体方向问题。
3. 检查完整性、格式、占位符、链接和现有语言不变性；添加聚焦行为回归测试。
4. 运行可用验证并按 review 技能审查最终 diff。
5. 记录真实验证限制，提交、推送 fork 并交付可审查结果。
6. 2026-10-24 续办：复查现有 PR、CI 和完整评论，移除与最新 dev 冲突的退役
   `github_models` 资源，重跑可用验证，使用现有 identity 提交并普通推送同一分支。
7. 按用户新授权将现有 PR 标记 Ready for review，更新正文并保留构建、运行时、截图与独立
   Urdu 审校限制；复验远程身份、head 和可用 CI，不合并、不发布。

## 风险与决策

- 本机只有 Command Line Tools，没有完整 Xcode；构建、宿主测试和修改后应用的 GUI 验证可能受阻。
- 界面语言和翻译源/目标语言独立，保留所有服务能力与语言检测逻辑。
- 不插入隐藏方向字符、不反转字符串，使用平台自然段落方向和语义布局。
- 2026-10-24：初始工作树和索引为空，HEAD 为 `e33aaaaf14fbd4ae961fbe6ebfb35638ac9fccac`。
  本轮仅允许修改主 catalog 和同任务 plan/history；不新增测试或集成其他 dev 变更。
  用户明确要求 Ready for review，覆盖首次交付时使用 Draft 的要求；不以 Ready 状态代表验证完成。
- 工作术语：Settings＝ترتیبات；Translation＝ترجمہ；Translate＝ترجمہ کریں；
  Source language＝ماخذ زبان；Target language＝ہدف زبان；History＝سابقہ سرگرمیاں；
  Favorites＝پسندیدہ؛ Cancel＝منسوخ کریں；Close＝بند کریں；Save＝محفوظ کریں；
  Download＝ڈاؤن لوڈ کریں；Remove＝ہٹائیں；Delete＝حذف کریں。

## 进度

- [x] 核对规则、base、fork 和既有 Urdu 支持。
- [x] 翻译和运行时注册。
- [x] 完成可用验证和审查；Xcode 与应用 GUI 验证受环境阻塞。
- [x] 已提交、推送 fork 并创建 Draft PR #1374；完成 history 和归档。
- [x] 2026-10-24：复查 PR、完整 threads/replies 与 CI；无开放线程，仅有欢迎 bot review，
  已报告的 5 项 checks 成功。
- [x] 移除退役资源，完成当前快照验证、审查和提交，普通推送
  `3d1d9f991101463bc19c3c1e0746596e0896df1c`。
- [x] 更新现有 PR 正文并标记 Ready；读回确认 OPEN、非 Draft、准确 base/head 与正文，
  GitHub 已报告可合并。完成本记录后再普通推送文档提交，并在最终回复前复验最新 head 和 CI。

## 验证

### 2026-10-24 续办验证

- 完整 threads/replies 为空；唯一 review 是欢迎 bot，无需修复或 resolve 的评论。
- 初始 PR head 的 5 项 checks 均成功；资源修复提交触发了新一轮检查，不把旧检查归属于最终 head。
- GitHub PR 元数据中的 base SHA 仍显示旧分叉点，但 fetch 和直接 branch API 确认当前 dev 为
  `3843ffdd46ac63aada494dcb4f63adf06aec04c3`，真实 merge-base 仍为 `8d80bfa2`。
- 删除上游已移除的 `github_models` 后，主 catalog 覆盖为 565/565，保留 50 个技术/品牌值；
  metadata 仍为 4/4。JSON 去重、占位符、变量、链接、标记、换行和隐藏方向控制符审计通过。
  从两个 catalog 删除 `ur` 后与 fetch 的当前 dev 完全相同。
- `jq -e .`、`plutil -lint`、Swift 语法解析、工程对象范围检查及 `git diff --check` 通过。
  实际 LanguageState/I18nHelper 源码的既有隔离程序重新编译并运行通过；未新增或扩写测试。
- `git merge-file` 的默认 diff 算法把相邻 Gemini Urdu 插入误报为冲突；显式 histogram 算法
  成功，结果等于当前 catalog。提交后的 `git merge-tree --write-tree` 对完整 dev/head 返回成功，
  GitHub 亦报告 `mergeable: true`，不是仅凭 JSON 相同声称冲突消除。
- workspace build 与 LocalizationTests 的调用均在入口被缺少完整 Xcode 阻塞；不视为构建或
  测试成功。没有重跑早先 AppKit/CoreText 探针，应用 GUI、复制、截图与独立 Urdu 审校仍未完成。
- review 技能复查全部资源值、语言注册、SwiftUI 布局、自然段落对齐及既有测试与工程引用；
  本轮删除与当前 dev 一致，无确认的未修复 finding。沿用现有架构已足够，无需扩展产品逻辑。
- 用户授权的普通 push、Ready 操作及正文更新成功；读回身份、非 Draft 状态和完整正文一致。
  资源修复提交的初次 CI 查询为 scope 成功、其余运行或排队中，后续状态以最终远程查询为准。

### 首次交付验证

- `sw_vers -productVersion`：27.0.1。
- `xcodebuild -version`：失败，当前开发目录只有 Command Line Tools。
- GitHub 搜索：未发现 Urdu 界面 PR；已有 Urdu 翻译语言，无需增加服务映射。
- 两个 catalog：566/566 与 4/4，排除明确标记不可翻译的 `%lld`。51 个主目录值和 2 个
  bundle 名称保留品牌、技术标签或纯占位符，其他适用条目使用 Urdu；没有复数或 substitution 结构。
- JSON 去重解析、占位符身份/类型/次数、变量、URL、Markdown、代码片段、换行和隐藏方向字符检查通过。
  删除新增 `ur` 后，两个目录与基线 JSON 完全相同。
- `jq -e .`、`plutil -lint`、`git diff --check`、修改后 Swift 的语法解析通过；工程对象差异检查
  确认仅新增 locale 和测试引用，没有改变 build settings。
- 使用实际 LanguageState/I18nHelper 源码及隔离的通知 fixture 编译并运行的小程序通过：
  `ur` 持久化标识、`ur-PK`/`ur-IN` 匹配及全部 7 种界面语言的方向/匹配。不是应用构建或宿主测试。
- 独立 AppKit/CoreText 探针：10 个 Urdu/混合/英语/阿拉伯语/希伯来语样本文本字形非零，
  选择范围和原始文本保持一致，系统字体回退包含 SFArabic。独立 NSTextView 的 selection export
  返回 false，不能作为应用复制通过证据；应用复制、光标和视觉排版仍待实测。
- workspace 列表、build、LocalizationTests 均因没有完整 Xcode 而未执行；无修改后应用截图。
- review 技能自查：基于冻结基线及文件摘要，完成翻译语义第二遍、资源不变性和入口调用链检查。
  调整 6 处术语/句式；没有确认的未修复 finding。不是独立母语者审校。
- PR helper 的 `gh` parent 元数据格式不兼容；使用临时 REST 元数据适配器，保留原 helper
  的拓扑、SHA、push 和 PR 校验。未修改受管 skills，preflight 通过。

## 完成条件

- 完成范围内实现、静态验证和审查，明确标注所有环境阻塞。
- 完成 history、归档计划、创建聚焦提交；记录 PR 或准确交付阻塞。

- 首次远程交付：Draft PR #1374，base `tisfeng/Easydict:dev`，head
  `AlleyNawaz/Easydict:feat/urdu-localization`；helper 写后身份、正文、SHA 和 Draft 校验通过，
  GitHub 报告可合并。首次查询 CodeQL scope/greeting 成功，Swift 分析与 GitGuardian 仍在运行。
  尚无实质 review finding；后续 CI 状态以 PR 页面为准，不把 pending 写成通过。
