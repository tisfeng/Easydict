## 2026-09-25 | 任务：修复 CodeQL SwiftPM manifest 沙箱导致的 CI 失败

**Links:** [失败的 CI run 36018866459](https://github.com/tisfeng/Easydict/actions/runs/36018866459)、[同因公开案例 cbusillo/context-panel#699](https://github.com/cbusillo/context-panel/issues/699)

### 执行上下文

- **Agent Name:** `Mavis`
- **Model:** `deepseek-flash`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

调查 `.github/workflows/codeql.yml` 的 `Analyze (swift)` 在 run 36018866459 上失败的原因（本地
Xcode 编译运行正常），确认原因后按方案一修复。

### 变更

- `.github/workflows/codeql.yml`：`Build application` 步骤的 `xcodebuild` 增加
  `-IDEPackageSupportDisableManifestSandbox=1`，并加注释记录失败现象、触发条件与对应 history。
- 新增本文档。

### 设计意图

`Analyze (swift)` 失败发生在 `xcodebuild` 解析 SPM 依赖图阶段，而非编译阶段：

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

选择关闭 manifest 沙箱而非 pin CodeQL 版本或预热依赖缓存：

- pin 版本已被两组证据否定（本地 run 35817016752 用 2.27.0 失败；上游案例实测 pin 到 2.26.4 仍
  失败）；macOS 公测镜像标签也无法指定版本。
- `-IDEPackageSupportDisableManifestSandbox=1` 只移除 SwiftPM 评估 `Package.swift` 时的嵌套沙箱，
  与社区在同类问题上使用的 `swift build --disable-sandbox` 等价，CodeQL 的编译期 tracing 不受影响。
  该开关字符串已在 Xcode 27 的 `SwiftPM.framework/Versions/A/SwiftPM` 中确认存在。
- 该 traced build 全程使用 `EASYDICT_RELEASE_PACKAGING=YES`，会跳过 SwiftFormat/SwiftLint 脚本
  阶段（`Easydict.xcodeproj/project.pbxproj`），因此 manifest 沙箱是此构建中唯一相关的沙箱。
- 保留了 CI 覆盖面：只移除这层冗余的嵌套沙箱，不改变被分析的 target、配置或编译标志。

### 验证

- YAML 解析：`python3 -c "import yaml; yaml.safe_load(...)"` 与 `ruby -ryaml` 均解析成功，
  `Build application` 的 `run` 块包含新增开关且其余标志不变。
- `git diff --check`：通过。
- 本地机制复现：`/usr/bin/arch -x86_64 /usr/bin/sandbox-exec -p '(version 1)(allow default)' /bin/echo X`
  在本机（macOS 27.0 26A428，与失败镜像同一 OS 构建）输出
  `Bad CPU type in executable`，与 CI 报错信息逐字一致；`lipo -info /usr/bin/sandbox-exec` 显示该
  二进制只有 `arm64e` 与 `arm64e.x1` 切片。本机 Xcode 27.0 (27A266a) 与失败镜像相同，说明差异
  来自 CodeQL tracer 的介入而非 OS/Xcode 版本。
- 开关确实被消费：`xcodebuild` 对未知的 `-Flag=value` 参数不报错（`-bogusflag=1` exit 0），
  因此仅凭"未报错"不能证明开关生效。改用同族且有可观测输出的
  `-IDEPackageSupportVerboseManifestLoading=1`（同一 `SwiftPM.framework` 二进制中的
  `SwiftPM/SPMWorkspace.swift` 一族）验证：以隔离 `HOME` 复用真实 SourcePackages 运行
  `xcodebuild -resolvePackageDependencies`，无开关输出 73 行且 0 行 manifest 相关内容，
  加开关输出 265 行、129 行 manifest 编译命令 → 该族开关确实被 xcodebuild 传给 SwiftPM。
- 参数形式：`-IDEPackageSupportDisableManifestSandbox=1` 与上述已验证形式一致；`xcodebuild` 二进制
  本身不含该字符串，由 `SwiftPM.framework` 实现读取，与 `IDEDisablePackageManifestCaching`、
  `IDEPackageSupportVerboseManifestLoading` 同族。
- 本地实验限制：在无 CodeQL tracer 注入的普通构建中，SwiftPM 评估 manifest 时**不会** spawn
  `sandbox-exec`（对照实验中两种配置的 `sandbox-exec` 出现次数均为 0，`exit=0`），因此本地无法
  复现失败路径，也无法在本地直接观测开关对 spawn 的影响；失败路径只在 tracer 注入后才出现。
  SwiftPM 硬编码绝对路径 `/usr/bin/sandbox-exec`（`Sandbox.swift`），PATH 上的 shim 无法用于
  本地拦截。
- CI 端验证：本变更的 `Analyze (swift)` 运行本身即为端到端验证（单次 28–40 分钟），待该运行确认。

### 受影响文件

- `.github/workflows/codeql.yml`
- `docs/histories/2026-09/2026-09-25-codeql-swiftpm-manifest-sandbox.md`

### 后续事项

- 上游修复（codeql-action 支持在 macOS 27 上 trace 沙箱化的 SwiftPM 构建，或 runner 镜像恢复
  可被 tracer 重启的 `sandbox-exec`）落地后，移除该开关。建议向上游报 issue 并附 runner 镜像
  版本、CodeQL 版本与原始日志。
- GitHub 的 macOS 公测标签无法指定镜像版本，本次未固定镜像；如再次出现镜像漂移导致的不稳定，
  可评估改用稳定标签或自托管 runner。
