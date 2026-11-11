## 2026-09-30 | 任务：移除 Sparkle 本地 debug 更新测试

<!-- 文件名：YYYY-MM-DD-<slug>.md；命名规则见 docs/histories/README.md 的“命名与 slug”。 -->

**Links:** None

### 执行上下文

- **Agent Name:** `ZCode`
- **Model:** `account:zai-start-plan/GLM-5.3-Flash`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

Sparkle 此前区分本地 debug（`http://localhost:8000/appcast.xml`）与正式 appcast feed，
现在不再需要在 debug 构建上做本地更新测试，要求移除该区分并给出方案后执行。

### 变更

- `Easydict/App/Info-debug.plist`：`SUFeedURL` 由 `http://localhost:8000/appcast.xml`
  改为官方地址 `https://raw.githubusercontent.com/tisfeng/Easydict/main/appcast.xml`，
  与 `Easydict/App/Info.plist` 一致。
- 新增本 history 记录。

### 设计意图

最小改动统一 Sparkle feed 配置，使 Sparkle 不再按 debug/正式区分 feed。
保留 `Info-debug.plist` 文件本身，其中剩余差异（`easydictd` URL scheme、
debug URL name）是 debug/正式双开共存机制（`EZSchemeParser`、`EZWindowManager`、
`EZConst.h` 在用），与更新测试无关。不采用删除该 plist 合并为单文件的方案，
避免 debug 版改注册 `easydict` scheme 与正式版抢链接处理。

### 验证

- `git diff --check`：通过。
- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -configuration Debug -derivedDataPath <agent-dd>`：Build Succeeded。
- `plutil -extract SUFeedURL raw <Debug 产物>/Easydict-debug.app/Contents/Info.plist`：
  输出 `https://raw.githubusercontent.com/tisfeng/Easydict/main/appcast.xml`，确认官方 feed 生效。

### 受影响文件

- `Easydict/App/Info-debug.plist`
- `docs/histories/2026-09/2026-09-30-remove-local-update-test.md`

### 后续事项

- debug 版此后指向官方 appcast：官方发布版本高于本地 `MARKETING_VERSION` 时 debug 版会收到
  更新提示，且更新包为正式 `com.izual.Easydict`，不应在 debug 版上执行安装更新。
