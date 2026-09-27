## 2026-09-25 | 任务：修复 macOS 27 runner 上 CodeQL tracer 无法 spawn arm64e-only 平台二进制导致的 CI 失败

**Links:** [失败的 CI run 36018866459](https://github.com/tisfeng/Easydict/actions/runs/36018866459)、[通过的验证 run 36048711146](https://github.com/tisfeng/Easydict/actions/runs/36048711146)、[同因公开案例 cbusillo/context-panel#699](https://github.com/cbusillo/context-panel/issues/699)

### 执行上下文

- **Agent Name:** `Mavis`
- **Model:** `deepseek-flash`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

调查 `.github/workflows/codeql.yml` 的 `Analyze (swift)` 在 run 36018866459 上失败的原因（本地
Xcode 编译运行正常），确认原因后按方案一修复。

### 变更

- `.github/workflows/codeql.yml`：`Build application` 步骤的 `xcodebuild` 依次增加
  `-IDEPackageSupportDisableManifestSandbox=1`、`OTHER_SWIFT_FLAGS='$(inherited) -disable-sandbox'`
  与 `COMBINE_HIDPI_IMAGES=NO`，并加注释记录三层失败现象、判别特征与对应 history。
- 新增本文档。

### 设计意图

`Analyze (swift)` 最初失败在 `xcodebuild` 解析 SPM 依赖图阶段，而非编译阶段：

```
Could not resolve package dependencies:
  posix_spawn error: Bad CPU type in executable (86), `["/usr/bin/sandbox-exec", ...]`
```

`github/codeql-action/init` 通过 `DYLD_INSERT_LIBRARIES` 把 tracer
（`codeql/tools/osx64/libtrace.dylib`）注入 Build 步骤的每个子进程；SwiftPM 评估 `Package.swift`
时会嵌套 spawn `/usr/bin/sandbox-exec`，该 spawn 在介入 tracer 后返回 `EBADARCH(86)`，于是
25 分钟后 xcodebuild 放弃并以 exit 74 结束，CodeQL 也无产出（SARIF 上传状态 failed）。

触发变量是 runner 镜像的静默升级，不是代码、Xcode 或 CodeQL 版本。`.github/workflows/codeql.yml`
使用公测标签 `runs-on: xcode-27`，会自动跟随最新镜像：`20260912.0186`（macOS 27.0 26A5406e，
`Xcode_27_Release_Candidate.app`）通过，`20260921.0210`（macOS 27.0 26A428 GA，
`Xcode_27.app`）失败。同一个 commit 的 PR run 成功、合并后的 dev push 失败，差别只在镜像。
CodeQL 版本同样不是原因：使用 2.27.0 的 run 35817016752 落在新镜像上依然失败。

`Analyze (swift)` 是 dev 的必需检查（strict），因此该失败会阻塞合并。

该 bug 有三层，根因相同：CodeQL tracer 通过 `DYLD_INSERT_LIBRARIES` 注入 Build 步骤的每个子进程，
而它无法重新 spawn macOS 27 上 `/usr/bin` 里那些**只有 arm64e 切片**的平台二进制，于是这些 spawn
返回 `EBADARCH(86)`：

1. **依赖解析阶段**：SwiftPM 评估 `Package.swift` 时 spawn `/usr/bin/sandbox-exec`，导致
   `Could not resolve package dependencies`。
2. **编译阶段**：`swift-frontend` 加载宏插件服务器时 spawn `/usr/bin/sandbox-exec`，报
   `compiler plugin '.../swift-plugin-server' could not be loaded: Bad CPU type in executable`
   （实测触发点为 `swift-service-context` 的 `ServiceContextModule` 使用 `@TaskLocal` 宏）。
3. **资源打包阶段**：Xcode 为每个 `@2x` + `@3x` PNG 对生成 hidpi `.tiff` 时 spawn
   `/usr/bin/tiffutil`，报 `unable to spawn process '/usr/bin/tiffutil' (Bad CPU type in executable)`。

三层的暴露顺序即为修复顺序：第 2、3 层都是被前一层修复后的验证运行暴露出来的
（`Bad CPU type` 计数 26 → 4 → 4，失败位置逐步后移），每次 exit code 也从 74 变为 65。

`arm64e-only` 是这三层的判别特征，可用 `lipo -info` 直接区分：

| 二进制 | 切片 | tracer 下的结果 |
| --- | --- | --- |
| `/usr/bin/sandbox-exec` | `arm64e arm64e.x1` | 失败（层 1、2） |
| `/usr/bin/tiffutil` | `arm64e arm64e.x1` | 失败（层 3） |
| `/usr/bin/ibtool` | `x86_64 arm64e arm64e.x1` | 正常 |
| `/usr/bin/actool` | `x86_64 arm64e arm64e.x1` | 正常 |
| `/usr/bin/touch` | `x86_64 arm64e arm64e.x1` | 正常 |

第 3 层的本地对照实验（无 tracer）确认 `tiffutil` 调用确实由
`COMBINE_HIDPI_IMAGES` 控制：默认设置下本地构建调用 `/usr/bin/tiffutil` 5 次，
加 `COMBINE_HIDPI_IMAGES=NO` 后为 0 次（详见"验证"）。

选择逐层关闭这些 spawn，而非 pin CodeQL 版本或预热依赖缓存：

- pin 版本已被两组证据否定（本地 run 35817016752 用 2.27.0 失败；上游案例实测 pin 到 2.26.4 仍
  失败）；macOS 公测镜像标签也无法指定版本。
- `-IDEPackageSupportDisableManifestSandbox=1` 移除 SwiftPM 评估 `Package.swift` 时的嵌套沙箱
  （第 1 层）。该开关字符串已在 Xcode 27 的 `SwiftPM.framework/Versions/A/SwiftPM` 中确认存在，
  与 `IDEDisablePackageManifestCaching`、`IDEPackageSupportVerboseManifestLoading` 同族。
- `OTHER_SWIFT_FLAGS='$(inherited) -disable-sandbox'` 移除 `swift-frontend` 的 subprocess 沙箱
  （第 2 层）。Xcode 27 中**不存在** `-IDEPackageSupportDisablePluginExecutionSandbox`（该名字来自
  2021 年 Xcode 12 时代的社区方案，已不在当前框架内），因此只能通过 Swift 编译标志传入。
- `COMBINE_HIDPI_IMAGES=NO` 让 `@2x`/`@3x` PNG 各自作为独立资源拷贝，不再调用 `tiffutil`
  （第 3 层）。这是标准 Xcode 构建设置，仓库其他位置未设置该值。
- 这三处都只改动 CI 构建方式，不改变被分析的源码、target 或配置；CodeQL 构建产物本身是丢弃的
  分析中间物，不会成为发布产物，因此第 3 层不影响任何随应用分发的资源。发布/归档构建仍使用
  默认的 `COMBINE_HIDPI_IMAGES`，图标打包行为不变。
- 该 traced build 全程使用 `EASYDICT_RELEASE_PACKAGING=YES`，会跳过 SwiftFormat/SwiftLint 脚本
  阶段（`Easydict.xcodeproj/project.pbxproj`）。

### 验证

- YAML 解析：`python3 -c "import yaml; yaml.safe_load(...)"` 解析成功，`Build application` 的
  `run` 块包含三处新增开关且其余标志不变。
- `git diff --check`：通过。
- 本地机制复现：`/usr/bin/arch -x86_64 /usr/bin/sandbox-exec -p '(version 1)(allow default)' /bin/echo X`
  在本机（macOS 27.0 26A428，与失败镜像同一 OS 构建）输出
  `Bad CPU type in executable`，与 CI 报错信息逐字一致；`lipo -info /usr/bin/sandbox-exec` 显示该
  二进制只有 `arm64e` 与 `arm64e.x1` 切片。`/usr/bin/tiffutil` 可同样复现
  （`arch -x86_64 /usr/bin/tiffutil` → `Bad CPU type`）。本机 Xcode 27.0 (27A266a) 与失败镜像相同，
  说明差异来自 CodeQL tracer 的介入而非 OS/Xcode 版本。
- 开关确实被消费：`xcodebuild` 对未知的 `-Flag=value` 参数不报错（`-bogusflag=1` exit 0），
  因此仅凭"未报错"不能证明开关生效。改用同族且有可观测输出的
  `-IDEPackageSupportVerboseManifestLoading=1`（同一 `SwiftPM.framework` 二进制中的
  `SwiftPM/SPMWorkspace.swift` 一族）验证：以隔离 `HOME` 复用真实 SourcePackages 运行
  `xcodebuild -resolvePackageDependencies`，无开关输出 73 行且 0 行 manifest 相关内容，
  加开关输出 265 行、129 行 manifest 编译命令 → 该族开关确实被 xcodebuild 传给 SwiftPM。
- 参数形式：`-IDEPackageSupportDisableManifestSandbox=1` 与上述已验证形式一致；`xcodebuild` 二进制
  本身不含该字符串，由 `SwiftPM.framework` 实现读取。
- 第 2 层的本地对照实验（无 tracer）：强制重编 `ServiceContextModule` 并全程轮询
  `sandbox-exec` 进程。不加 `-disable-sandbox` 时观测到 1 次 `sandbox-exec`（1197 次采样），
  加上 `OTHER_SWIFT_FLAGS='$(inherited) -disable-sandbox'` 后降为 0 次（539 次采样）；两轮均确认
  该 target 被实际重编、且均无宏错误。→ 宏插件加载确实经由 `/usr/bin/sandbox-exec`，且
  `-disable-sandbox` 能抑制它。
- 编译标志确实到达 SPM 包 target：以 `-verbose` 构建后检查
  `ServiceContextModule` 的实际命令，`-disable-sandbox` 出现在该 target 的 `builtin-SwiftDriver`
  命令行中（第 19 个 token），证明 `$(inherited)` 展开并把标志传给了包 target，而非只作用于主
  target。
- 第 3 层的本地对照实验（无 tracer）：touch 全部图标 PNG 以强制重新考虑资源任务，完整构建两轮并
  统计日志中的 `/usr/bin/tiffutil` 调用。默认设置下 5 次，加 `COMBINE_HIDPI_IMAGES=NO` 后 0 次；
  两轮 `exit=0`。→ `tiffutil` 调用确实由该设置控制，且关闭后资源打包改为逐张拷贝 `@2x`/`@3x`
  PNG（构建产物中 10 个 `*-icon@*.png`，无 `.tiff`）。
- 逐层修复的 CI 证据（镜像 `20260921.0210`，CodeQL 2.27.1）：
  - run 36018866459（未修复）：`Bad CPU type` 26 次，依赖解析即失败，exit 74。
  - run 36032667444（第 1 层）：resolve 错误归零、`Bad CPU type` 降至 4 次，推进到编译阶段，
    exit 65；4 次全部来自 `swift-plugin-server` → 第 2 层。
  - run 36039193930（第 1+2 层）：宏插件错误归零、Swift 编译与链接全部成功（耗时 45 分钟，此前
    26 分钟），仅剩 4 次 `tiffutil` 失败 → 第 3 层。
  - run 36048711146（三层修复，镜像 `20260921.0210`、CodeQL 2.27.1）：**全部通过**，耗时 48 分钟；
    `Bad CPU type`、`Could not resolve package dependencies`、`could not be loaded`、
    `unable to spawn process '/usr/bin/tiffutil'` 全部为 0 次。`Build application` 与
    `Perform CodeQL analysis` 均为 success，`Analysis upload status is complete`、
    `Successfully uploaded results`，code-scanning analysis 的 rules 从失败时的 0 变为 27。
    该轮 `actool`/`ibtool` 各执行 5 次（符合预期，它们带 x86_64 切片），`tiffutil` 0 次。
- 本地实验限制：无 tracer 注入时失败路径不会出现（各轮 `exit=0`），因此本地只能证明"这些 spawn
  确实发生且可被对应设置抑制"，端到端结论以 CI 运行为准。SwiftPM 硬编码绝对路径
  `/usr/bin/sandbox-exec`（`Sandbox.swift`），PATH 上的 shim 无法用于本地拦截。
- CI 端验证：`workflow_dispatch` 触发 `Analyze (swift)` 完成端到端验证（run 36048711146 通过）。
  该运行与 `push`/`pull_request` 走相同的构建路径，差异仅在 `changes` 作业的范围判断。

### 受影响文件

- `.github/workflows/codeql.yml`
- `docs/histories/2026-09/2026-09-25-codeql-swiftpm-manifest-sandbox.md`

### 后续事项

- 上游修复（codeql-action 能正确 trace macOS 27 上仅含 arm64e 切片的平台二进制，或 runner 镜像
  提供可被 tracer 重启的 `/usr/bin/sandbox-exec` 与 `/usr/bin/tiffutil`）落地后，移除这三处开关。
  建议向上游报 issue 并附 runner 镜像版本、CodeQL 版本与原始日志。
- GitHub 的 macOS 公测标签无法指定镜像版本，本次未固定镜像；如再次出现镜像漂移导致的不稳定，
  可评估改用稳定标签或自托管 runner。
