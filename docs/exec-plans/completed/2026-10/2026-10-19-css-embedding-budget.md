# 隔离词典 CSS 嵌入预算与缓存

- 状态：completed
- 创建日期：2026-10-19
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.1 (27A9275)`

## 背景

将 Scoco 本地提交 `fde8e3db77be9e4e6a4ae5ddcf25d3dc59cb5fc7` 的 CSS 预算与缓存修复适配到 Easydict。初始基线为 `b9514c9f3b292d1068396d24512f56b8fc5560c7`，独立任务工作树初始干净。当前 CSS 子资源和最终 CSS 重复计费，最终 CSS 被拒绝时子资源预算及缓存仍会保留。

## 目标与范围

- 目标结果：只按最终 CSS data URL 向外层计费，失败不改变外层缓存或预算。
- 允许修改路径：AppleDictionary.swift、本计划及同任务 history。
- 同任务 history：`docs/histories/2026-10/2026-10-19-css-embedding-budget.md`
- 用户限制：验证与 review 通过后本地提交，不 push。
- 非目标：移植无结果修复、重构资源加载器、新增或扩写测试、改变发布或运行时应用。
- 验收标准：保留现有资源安全和递归边界，通过相关现有测试与 review，创建本地提交。

## 工作计划

1. 按 ResourceEmbeddingState 的值语义临时解析 CSS 子资源，仅在最终输出通过预算检查后合并缓存。
2. 运行现有 AppleDictionaryTests 与适用的静态检查。
3. 使用 review 技能审查完整任务差异和资源处理调用链，修复有效 finding 后重新验证。
4. 更新 history、归档计划，使用 git-commit 技能本地提交。

## 风险与决策

- 保留文件大小、字体上限、路径与符号链接边界、循环与深度限制、重复引用计费和片段拼接。
- 临时状态继承当前预算和递归链；成功时仅合并 dataURLs，不合并临时预算或 loadingURLs。
- 按构建规则仅运行现有测试，新增 CSS 专属测试需另行授权；如现有测试未覆盖相关分支，在验证结果中明确说明。
- 使用 checkout 专属 Agent DerivedData；测试前核实未运行同 bundle ID 的 IDE 调试宿主。

## 进度

- [x] 完成适配。
- [x] 验证与 review 通过。
- [x] 更新 history、归档计划并完成本地提交准备；实际提交由 Git 回执确认。

## 验证

- arm64 Debug 下 `xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath <checkout-agent-derived-data> -disableAutomaticPackageResolution -only-testing:EasydictTests/AppleDictionaryTests` 通过；xcresult 确认 5 项测试、6 次执行，0 失败、0 跳过、0 runtime warning。相同配置的测试覆盖构建集成，不重复 build。
- SwiftFormat 0.63.0 lint、Swift frontend parse、`git diff --check` 通过。
- Review：基于初始 HEAD 审查完整生产差异、调用链和现有测试；核对嵌套 CSS、成功缓存合并、失败无外层状态变更、重复引用、路径/字体限制及递归链隔离，无有效 finding。沿用 ResourceEmbeddingState 值语义足够，无需重构资源加载器。
- 测试与审查后的生产文件 SHA-256 均为 `a02d0c4a817648d29e1280b37c454d63d62242e2eb666786fd00f1dde48d0bad`。
- 未新增测试代码；现有 suite 不含 CSS 嵌套及预算失败的专属断言，相关分支仅作代码审查。未进行真实词典 UI 验收。

## 完成条件

- 仅范围内文件发生变更，相关验证通过，review 无遗留有效 finding。
- history 记录来源与验证边界，计划归档，提交后消息校验通过；不 push、不自动合并开发分支。
