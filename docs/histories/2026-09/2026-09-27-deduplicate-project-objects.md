## 2026-09-27 | 任务：删除重复的工程对象声明

**Links:** [PR 审查评论](https://github.com/tisfeng/Easydict/pull/1332#discussion_r4114397256)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

### 用户请求

继续修复 PR 审查中的 C2：工程文件重复声明 10 个对象。

### 变更

- 删除新增位置的 5 个 `PBXBuildFile` 和 5 个 `PBXFileReference` 重复声明。
- 保留 AppPathManager 相关文件原有对象定义、group、Sources 引用和所有 Copilot 对象。

### 设计意图

各组重复声明逐字相同，仅删除较早出现的多余副本，不重新生成工程文件或改写对象 ID。
本次为单文件低风险清理，不另建执行计划。

### 验证

- 全部工程对象声明的 ID 唯一性检查：通过，重复组由 10 组降至 0 组。
- 删除前后使用 `plutil -convert json` 解析，工程对象内容完全相同。
- `plutil -lint Easydict.xcodeproj/project.pbxproj`：通过。
- `git diff --check`：通过；完整 diff 复核仅删除指定的 10 行声明。
- 独立 DerivedData 的 `xcodebuild build`：Easydict workspace/scheme、Debug、
  `EASYDICT_RELEASE_PACKAGING=YES`，构建通过。
- 未修改运行时逻辑或测试，未新增或运行应用宿主测试。

### 受影响文件

- `Easydict.xcodeproj/project.pbxproj`
- `docs/histories/2026-09/2026-09-27-deduplicate-project-objects.md`

### 后续事项

- None
