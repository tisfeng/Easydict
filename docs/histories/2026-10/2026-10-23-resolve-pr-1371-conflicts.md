## 2026-10-23 | 任务：解决 PR #1371 的测试集成冲突

**Links:** [PR #1371](https://github.com/tisfeng/Easydict/pull/1371) · [执行计划](../../exec-plans/completed/2026-10/2026-10-23-resolve-pr-1371-conflicts.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

重新解决 PR #1371 的冲突，验证后完成本地合并，不 push。

### 变更

- 在 PR 分支合入最新 dev，解决测试 Sources 列表冲突，保留双方独立测试引用。
- 删除 ClaudeSSEParserTests.swift 与 OpenAIStreamTaskControlTests.swift 中遗留的重复温度 suite，保留专属测试文件。
- 补充任务记录并归档计划；不修改服务生产逻辑、工程 build settings 或资源配置。

### 设计意图

PR head 为 `4c67620542ec86f9375287b019d805b2598fef7f`；PR 元数据 base/merge-base 为 `a7405e4b2da5b8ce63b0686bc60ac8332b7cebeb`；实际 fetch 并集成的最新 dev 为 `c8b2c7f7293c6c05bfe40fe19c06415f1ae4ed5e`。
保留双方增量，不机械选择冲突的一侧。重复声明是测试 target 编译确认的集成阻塞，删除旧副本即可恢复独立 suite 结构。

### 验证

- 工程 `plutil -lint`、JSON 对象检查通过；三个新增测试均只有一个 file/build/test Sources 引用；双方 XCBuildConfiguration 未改变。
- `git diff --check`：通过。
- 首次测试编译确认两处 invalid redeclaration，清除旧副本后 `xcodebuild test` 成功：5 个 suite、22 个测试通过。
- 测试覆盖温度能力检查、Claude SSE、OpenAI task control、QueryModel cancellation；没有新增或扩写测试。
- 使用独立 agent DerivedData，未覆盖 bundle ID。`EASYDICT_RELEASE_PACKAGING=YES` 跳过格式化，避免无关源码修改。
- 原始构建被工作区 Package.resolved 消失阻塞；验证临时使用 `EXCLUDED_SOURCE_FILE_NAMES=Package.resolved` 排除该资源复制，没有修改工程资源配置。测试结论不覆盖发布打包。
- 测试结束恢复初始锁文件并逐字节核对，不包含锁文件改动。
- `review`：本次冲突解决及重复声明清理未发现新增可证实缺陷。PR 中独立 Claude 别名解析评论保留，不在本轮修改。
- 用户原有应用进程保留，测试宿主已退出；没有 push、发布 review 或 resolve 远程线程。

### 受影响文件

- `Easydict.xcodeproj/project.pbxproj`
- `EasydictTests/Service/ClaudeSSEParserTests.swift`
- `EasydictTests/Service/OpenAI/OpenAIStreamTaskControlTests.swift`
- 本任务 history 与归档计划。
- latest-base merge 引入的其他文件保持 dev 原内容。

### 后续事项

- 若要更新 GitHub PR，需用户另行授权 push。
- 独立 Claude 别名解析问题、工作区锁文件消失原因及发布打包验证留待各自任务处理。
