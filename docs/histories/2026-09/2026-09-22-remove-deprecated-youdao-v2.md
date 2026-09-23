## 2026-09-22 | 任务：移除废弃的有道词典 V2 解析路径

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-22-remove-deprecated-youdao-v2.md)

### 执行上下文

- **Agent Name:** `root`
- **Model:** `Unknown`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

删除仓库中已废弃的有道词典代码（旧 `/jsonapi` 的 V2 解析链）及配套样例资源，直接在本地
`dev` 上提交，不新建分支、不 push。

### 变更

- 删除 `Easydict/Swift/Service/Youdao/EZQueryResult+Dict.swift`：文件内唯一方法
  `update(dict:)` 已标记 deprecated。
- 删除 `Easydict/Swift/Service/Youdao/Model/YoudaoDictResponse.swift`：文件内唯一顶层声明
  `YoudaoDictResponse` 已标记 deprecated。
- 从 `Easydict/Swift/Service/Youdao/YoudaoService+Dict.swift` 删除已废弃的 `queryDictionaryV2`
  请求函数。
- 删除 `Easydict/Swift/Service/Youdao/Model/DictJSONExample/v2/` 下 4 个样例 JSON。
- 同步 `Easydict.xcodeproj/project.pbxproj`：移除上述文件的 PBXBuildFile、PBXFileReference、
  分组条目及 Sources/Resources build phase 引用，共删除 32 行。
- 新增执行计划与本文档。

### 设计意图

有道词典只需保留 V4（`/jsonapi_s?...jsonversion=4`）一条解析链。V2 路径自 V4 接入提交
`fc05e8810` 起即被标记 deprecated 且全仓库无调用点，保留它只会让两套相似解析器持续造成
误读——PR #1300 的审查正是为此花了额外时间确认两者差异。删除时同时清掉配套样例与工程
引用，使响应模型、样例和构建图保持一致；`DictJSONExample/v4` 与所有 V4 代码按用户要求
原样保留。

### 验证

- `plutil -lint Easydict.xcodeproj/project.pbxproj`：OK。
- `xcodebuild -list -workspace Easydict.xcworkspace`：workspace 与 scheme 正常解析。
- `rg -n "YoudaoDictResponse\b|queryDictionaryV2|update\(dict:|DictJSONExample/v2" Easydict EasydictTests`：无残留。
- 按 UUID 复查工程文件：被删文件的 build file、file reference、分组与 build phase 条目均无
  残留；V4 解析器、`YoudaoDictResponseV4` 与 4 个 v4 样例引用仍在。
- `EASYDICT_RELEASE_PACKAGING=YES xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict`：
  `** BUILD SUCCEEDED **`（日志显示 `SwiftFormat skipped` / `SwiftLint skipped`）。
- 首次未加开关的完整构建在 Lint 阶段（SwiftLint 全量扫描）持续 35 分钟以上仍未结束；按
  仓库既有做法（见 [2026-09-10-openai-test-cleanup](2026-09-10-openai-test-cleanup.md)）使用
  项目自带开关跳过 Format/Lint 后完成编译，编译错误检查不受影响。
- 产物检查：`DerivedData/.../Easydict-debug.app/Contents/Resources` 内 v2 样例为 0 个，
  v4 样例仍在（4 个）。

### 受影响文件

- `Easydict/Swift/Service/Youdao/YoudaoService+Dict.swift`
- `Easydict/Swift/Service/Youdao/EZQueryResult+Dict.swift`（删除）
- `Easydict/Swift/Service/Youdao/Model/YoudaoDictResponse.swift`（删除）
- `Easydict/Swift/Service/Youdao/Model/DictJSONExample/v2/{good,美,人的一生,look up}.json`（删除）
- `Easydict.xcodeproj/project.pbxproj`
- `docs/exec-plans/completed/2026-09/2026-09-22-remove-deprecated-youdao-v2.md`
- `docs/histories/2026-09/2026-09-22-remove-deprecated-youdao-v2.md`

### 后续事项

- `DictJSONExample/v4` 同样没有代码读取却仍被打进 app Resources（约 500KB），是否移出
  Resources 另行决定；本次按用户要求未改动。
- `YoudaoService.textToAudio` 仍用 `.urlQueryAllowed` 拼接 TTS URL，对 `&`、`=`、`+` 不转义，
  属于既有问题（PR #1300 只修正了词典发音路径），可另行跟进。
