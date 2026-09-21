# 移除废弃的有道词典 V2 解析路径

- 状态：completed
- 创建日期：2026-09-22
- 负责人：tisfeng
- 关联 Issue/PR：none（由 PR #1300 审查讨论引出）

## 执行上下文

- **Agent Name:** `root`
- **Model:** `Unknown`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

## 背景

有道词典存在两套响应结构：旧 `/jsonapi`（代码注释称 V2）与新
`/jsonapi_s?doctype=json&jsonversion=4`（V4）。V4 接入提交
`fc05e8810 Adapt new youdao api jsonapi_s (#777)` 同时把旧路径标记为
`@available(*, deprecated)`，但代码与样例一直保留。

当前状态：`queryYoudaoDict` 只调用 `queryDictionaryV4`；`queryDictionaryV2`、
`update(dict:)`、`YoudaoDictResponse` 全仓库没有调用点；`DictJSONExample/v2` 的 4 个样例
没有任何代码读取，却挂在 `Easydict` target 的 Resources build phase 中（约 500KB）。
PR #1300 审查中确认两份解析器的差异来自响应结构（`ec.word` 为数组 vs 对象），
删除旧路径不改变运行时行为。

## 目标与范围

- 目标结果：删除废弃的有道词典 V2 解析链（请求函数、解析器、响应模型、样例资源）及其
  Xcode 工程引用，运行时行为不变。
- 允许修改路径：`Easydict/Swift/Service/Youdao/**`、`Easydict.xcodeproj/project.pbxproj`、
  `docs/exec-plans/**`、`docs/histories/**`。
- 同任务 history：`docs/histories/2026-09/2026-09-22-remove-deprecated-youdao-v2.md`
- 用户限制：直接在本地 `dev` 上修改并提交，不新建分支、不 push；`DictJSONExample/v4`
  不修改；不做范围外的死代码重构。
- 非目标：不改 V4 解析逻辑，不动有道的 OCR/Translate/TTS 路径，不处理
  `QueryError.init?(coder:)` 的 deprecated 标记。
- 验收标准：工程文件合法且无悬空引用；构建通过；仓库内无 `YoudaoDictResponse`（非 V4）、
  `queryDictionaryV2`、`update(dict:)`、`DictJSONExample/v2` 残留；bundle 不再打包 v2 样例。

## 工作计划

1. 删除 `EZQueryResult+Dict.swift`、`YoudaoDictResponse.swift`、`DictJSONExample/v2` 样例。
2. 从 `YoudaoService+Dict.swift` 删除 V2 请求函数段。
3. 按 UUID 同步 `project.pbxproj` 中的文件、分组与 build phase 引用。
4. 运行静态校验与 `xcodebuild build`。
5. 使用 `review` 技能审查本次生产代码变更。
6. 写 history、归档 plan，创建本地提交。

## 风险与决策

- 风险：`project.pbxproj` 手工编辑且样例位于 Resources build phase，漏删会留下悬空引用；
  用 UUID 精确删除并以 `plutil -lint` 与 `xcodebuild -list` 双重校验。
- 风险：删除内容只能从 git 历史恢复（`git show <commit>^:<path>`）。
- 决策：不新建分支，直接在 `dev` 上提交（该仓库 dev 以直接提交为主，用户明确要求）。
- 决策：仅删除 V2；`DictJSONExample/v4` 与 V4 解析路径保留（用户明确"不要改"）。
- 决策：`YoudaoDictResponse.swift` 与 `EZQueryResult+Dict.swift` 整文件删除，因为各自只有
  一个废弃顶层声明或方法。

## 进度

- [x] 只读排查与方案确认
- [x] 删除代码与样例
- [x] 更新 Xcode 工程引用
- [x] 构建验证
- [x] review 审查
- [x] history 与归档
- [ ] 本地提交（执行中）

## 验证

- `plutil -lint Easydict.xcodeproj/project.pbxproj`：OK。
- `xcodebuild -list -workspace Easydict.xcworkspace`：workspace/scheme 正常解析。
- `rg -n "YoudaoDictResponse\b|queryDictionaryV2|update\(dict:|DictJSONExample/v2" Easydict EasydictTests`：
  无残留命中。
- 被删文件的 UUID（6 个 PBXBuildFile、6 个 PBXFileReference、2 个分组条目、v2 分组块、
  4 个 Resources 条目、2 个 Sources 条目）在工程文件中无残留；V4 解析器、`YoudaoDictResponseV4`
  与 4 个 v4 样例引用仍在。
- `EASYDICT_RELEASE_PACKAGING=YES xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict`：
  `** BUILD SUCCEEDED **`。首次不加开关的完整构建在 Lint 阶段（SwiftLint 全量扫描）超过
  35 分钟未结束，按仓库既有做法跳过 Format/Lint 阶段完成编译验证。
- 产物检查：构建出的 `Easydict-debug.app` 内不再包含 v2 样例（0 个），v4 样例保留（4 个）。
- `review` 技能审查：本轮变更范围内未发现可证实缺陷。
- 未运行：完整测试套件（本次为纯删除，按 `docs/agents/build-and-test.md` 选择编译验证）。

## 完成条件

- 删除范围完整且无残留引用，`plutil -lint` 与 `xcodebuild build` 通过，`review` 未发现
  需修复的问题，history 已记录，plan 已归档到 `completed/2026-09/`，本地提交完成且未 push。
