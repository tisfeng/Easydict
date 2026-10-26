# 恢复原有布局并限定结果文本方向

- 状态：completed
- 创建日期：2026-10-27
- 负责人：Codex
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/pull/1374

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

## 背景

用户实测指出全界面镜像改变了既有操作布局，明确要求恢复原布局，仅适配 EZWordResultView 结果文本方向。
当前 HEAD 为 4b2f7722912f3f2744dace8bfbb98ecf4e4652f6，现有 modifier 和测试文件各有格式改动，索引为空。

## 目标与范围

- 目标结果：恢复全窗口 RTL 之前的布局，只有结果正文使用自然段落方向，代码段保持 LTR。
- 允许修改路径：RTL 影响的窗口/控件及工程引用、结果文本专用控件、Markdown 的惰性元数据和同任务记录。
- 同任务 history：`docs/histories/2026-10/2026-10-27-result-text-direction.md`
- 用户限制：不增加或改变设置布局；保留当前实例；只运行现有测试；不 push。
- 非目标：修改翻译资源、provider、输入语言或词典 HTML，新增/扩写测试。
- 验收标准：受影响 UI 源码回到 5708742dd 的布局；结果内容不变、方向独立于界面语言；现有相关测试和 review 通过。

## 工作计划

1. 保存已有改动归属，逐文件撤回全窗口镜像及相关方向适配。
2. 在 EZWordResultView 内接入专用文本控件，按段落自然排版并保留 Markdown 样式和代码方向。
3. 运行现有本地化及 Markdown 测试，检查回退范围并 review。
4. history、归档和本地提交，不 push。

## 风险与决策

- 用指定 Git 对象内容恢复仅由 RTL 引入的代码文件，不 reset、rebase 或覆盖用户未提交改动。
- 两处已有格式改动原样保留、不暂存；已有 modifier 不再被窗口调用，其源码及引用暂时保留，避免删除用户正在修改的文件。
- 不修改共享文本控件的默认排版；仅专用结果子类应用方向处理。Markdown 代码块增加惰性标记，其他使用者不消费该标记。
- 只调整正文段落属性，原操作按钮、约束和 WebView 文档方向保持参考版本行为。

## 进度

- [x] 核对范围与初始状态。
- [x] 布局恢复及正文适配。
- [x] 验证、review 和交付（本地提交由本记录同批交付）。

## 验证

- Debug `xcodebuild test` 成功，现有 LocalizationTests 与 MarkdownRendererTests 共 28 项通过，未新增/扩写测试。
- UI 文件逐一比较 5708742dd，除 EZWordResultView 的专用结果控件接入和 EasydictApp 的两处方向注入移除外，均与参考版本一致。参考版本自带的设置和菜单方向注入也移除，满足当前范围。
- `plutil -lint` 与本任务 `git diff --check` 通过；全工作树 diff-check 仅报告原有测试文件末尾空行，原样保留。
- 使用 review 技能检查冻结的 23 个代码/工程路径；未发现需要修复的 finding。结果方向与界面语言解耦、字体/外观/Markdown 切换均经过同一更新入口，代码元数据只供专用结果控件消费；此实现范围足够，无须改设置布局。
- 原有两处格式改动保持原样，均排除提交；SwiftFormat 移除原测试文件末尾空行后已精确恢复。
- 当前用户实例 PID 与路径未变；不做 GUI、Release 或旧系统验证。现有测试不直接覆盖新子类的方向显示，不能据此声称实机 RTL 验证完成。

## 完成条件

- 范围内实现、验证和 review 完成，记录 GUI 未实测限制，创建本地提交并保留两处原有改动。

## 用户实测后的补充修复

- 用户提供截图：Urdu 正文的最后一行仍然靠左，未达到要求；此前 GUI 未验证，不能把现有测试通过视为正文方向验收完成。
- 本轮基线：3b3837cd8a6592c997060abe163be5aa4e0dc78a；仅 modifier 文件有原有未提交格式修改，保持原样排除提交。
- 修改范围：TranslationResultLabel 显式解析每个段落首个强方向字符，并同时设置基础方向与左/右对齐；围栏代码固定 LTR，其他 UI 不变。
- 验证：运行既有两套测试、构建和 review；保留运行实例，不新增测试或执行 GUI 替换，不 push。
- [x] 完成显式方向与对齐修复、验证、review 和本地提交（本记录同批交付）。
- Debug 构建与两个既有 suite 共 28 项通过；未新增测试。GUI 仍未验证，当前用户实例 PID/产物路径保持不变。
- review：检查最终子类差异及纯文本/Markdown 更新入口、尺寸测量和调用者；未发现有效 finding。显式内容方向消除 locale 对齐歧义，未触及其他 UI，实现范围足够。
- Apple SDK NSText.h 说明 natural alignment 可能按 UI 语言或 base writing direction 解析；因此不能把 `.natural` 当作内容靠右的保证。采用文档：[NSTextAlignment.natural](https://developer.apple.com/documentation/appkit/nstextalignment/natural)。
