## 2026-09-19 | 任务：优化发布构建性能

**Links:** `docs/exec-plans/completed/2026-09/2026-09-19-release-performance.md`

### 执行上下文

- **Agent Name:** Unknown
- **Model:** Unknown
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

在不改变发布功能和正式远程动作边界的前提下，使用长期专用 build worktree 和可复用 Release 编译缓存，降低 Draft 的构建耗时并增加耗时可观测性。

### 变更

- 增加发布 step 的 `timings.json` 记录和终端耗时摘要。
- 增加长期 `.tmp/release/cache/worktree`、fingerprint DerivedData、并发锁和 build 状态元数据。
- 普通 Archive 改为增量优先；失败自动清理当前缓存并回退一次 clean Archive；增加 `--force-clean` 显式选项。
- 保留签名、公证、stapling、appcast、lease、远程验证及 Draft/Publish 分支边界。
- 增加缓存安全和 timing 测试，更新发布 README 与生命周期 reference。

### 设计意图

源码版本和 appcast 仍在版本专用 release worktree 中冻结；长期 build worktree 只用于 Xcode Archive，不参与远程推送。DerivedData fingerprint 只在工具链、依赖解析、Release 配置或发布脚本变化时失效，从而允许相邻版本复用编译中间产物，同时保留失败回退和完整发布验证。

### 验证

- `asc workflow validate --file scripts/release/asc-workflow.json --pretty`：通过。
- `bash -n scripts/release/*.sh`：通过。
- `python3 -m unittest discover -s scripts/release/tests -p 'test_*.py'`：31 个通过。
- `python3 -m unittest discover -s .agents/skills/release-easydict/tests -p 'test_*.py'`：30 个通过。
- `python3 -m py_compile scripts/release/*.py .agents/skills/release-easydict/scripts/*.py`：通过。
- `git diff --check`：通过。
- 真实 Xcode Archive、公证和远程发布：未运行，需由下一次 Draft 实测性能收益。

### 受影响文件

- `.agents/skills/release-easydict/references/release-workflow.md`
- `scripts/release/README.md`
- `scripts/release/asc-workflow.json`
- `scripts/release/release-build.sh`
- `scripts/release/release-common.sh`
- `scripts/release/release-easydict.sh`
- `scripts/release/tests/test_release_performance.py`

### 后续事项

- 下一次 Draft 需要比较 `state/timings.json` 与 2.23.0 基线，确认增量缓存命中率和 Archive 实际耗时。
- GitHub 资产并行上传、公证 submission 复用和 Publish 重复 fetch 优化尚未在本任务实施。
