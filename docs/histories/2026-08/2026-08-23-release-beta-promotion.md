## 2026-08-23 | 任务：发布新 beta 时提升上一版本

**Links:** scripts/release/

### 用户请求

发布新的 beta 版本时，保留当前版本的 beta/prerelease 状态，同时将上一 beta 的 Sparkle
条目和 GitHub Release 自动提升为 stable。

### 变更

- 在 `publish` 阶段识别并持久化上一 beta，兼容已经生成的 Draft 和候选 appcast。
- 只允许上一 beta 删除 `sparkle:channel`，继续拒绝其他旧 feed 条目变化。
- 新 beta 公开且 feed 推送后，幂等移除上一 GitHub Release 的 prerelease 标记。
- 最终远程验证同时检查当前 beta、上一 stable、Git 引用、发布资产和公开 feed。
- 新增 appcast 轮换行为测试并更新中文发布文档。

### 设计意图

将 promotion 推迟到 `publish`，使现有 2.22.0 Draft 无需重新构建。上一 beta 在公开状态变化前
写入发布状态，因此失败后的 resume 不会重新选择版本；严格校验只放行目标 channel 删除，保留
原有旧条目保护边界。

### 验证

- `python3 scripts/release/tests/test_release_appcast.py`：通过，3 个测试成功。
- 真实 2.22.0 候选副本验证：2.22.0 保持 beta，2.21.0 移除 beta。
- `python3 -m py_compile scripts/release/release-appcast.py scripts/release/tests/test_release_appcast.py`：通过。
- `bash -n scripts/release/*.sh`：通过。
- `jq -e . scripts/release/asc-workflow.json`：通过。
- `asc workflow validate --file scripts/release/asc-workflow.json --pretty`：通过。
- `./scripts/release/release-easydict.sh publish 2.22.0 --dry-run`：通过。
- `git diff --check`：通过。

### 受影响文件

- `scripts/release/asc-workflow.json`
- `scripts/release/release-appcast.py`
- `scripts/release/release-appcast.sh`
- `scripts/release/release-common.sh`
- `scripts/release/release-github.sh`
- `scripts/release/release-preflight.sh`
- `scripts/release/release-verify.sh`
- `scripts/release/tests/test_release_appcast.py`
- `scripts/release/README.md`
- `docs/exec-plans/completed/2026-08-23-release-beta-promotion.md`

### 后续事项

- `shellcheck` 未安装，因此本次未执行该检查。
- 真实 GitHub Release 状态只做了只读审计；本次没有执行 `publish`。
