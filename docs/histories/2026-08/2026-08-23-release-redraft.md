## 2026-08-23 | 任务：支持安全重建同版本 Draft

**Links:** `docs/exec-plans/completed/2026-08-23-release-redraft.md`

### 用户请求

为发布脚本和 `release-easydict` skill 增加显式重新 Draft 模式：废弃未公开的同版本旧 Draft，并基于同步后的本地 `dev` 重建，自动递增构建号且不污染用户当前 checkout。

### 变更

- 新增 `draft <version> --replace-draft`，冻结旧 GitHub Draft/Tag 身份和完整 Draft JSON，将旧本地状态暂存为可恢复备份。
- 新产物完成本地验证后，重新校验 Draft 和 Tag，使用 lease 原子替换 `dev`、`main` 和版本 Tag，再删除精确旧 Draft、创建并验证新 Draft。
- 构建号按旧 Draft、当前项目和公开 appcast 的最大值加一，并在 resume 时复用；成功后删除旧工作树、旧产物、临时分支和恢复备份。
- 更新 release skill 与中文命令文档，补充 CLI、状态保护、Git 引用、Draft 删除和清理的隔离测试。

### 设计意图

远端旧 Draft 和 Tag 一直保留到新构建完成签名、公证、打包和本地验证，避免昂贵阶段失败时丢失可用 Draft。所有远端变更绑定冻结的数据库 ID、更新时间和 Tag OID；临时本地备份只服务于失败恢复，不形成长期 stale 归档。

### 验证

- `bash -n scripts/release/*.sh`：通过。
- `asc workflow validate --file scripts/release/asc-workflow.json --pretty`：`valid: true`。
- `python3 -m unittest discover -s scripts/release/tests -p 'test_release_*.py' -v`：10 个测试通过。
- `python3 -m unittest discover -s .agents/skills/release-easydict/tests -p 'test_*.py' -v`：17 个测试通过。
- `python3 /Users/tisfeng/.codex/skills/.system/skill-creator/scripts/quick_validate.py .agents/skills/release-easydict`：skill 有效。
- 普通 Draft 与 `--replace-draft` 的 `--dry-run`：步骤顺序符合预期，未执行真实发布。
- `git diff --check`：通过。
- 手动检查：线上 2.22.0 Draft、Tag 和发布资产未被修改。

### 受影响文件

- `scripts/release/`
- `.agents/skills/release-easydict/`
- `docs/exec-plans/completed/2026-08-23-release-redraft.md`
- `docs/histories/2026-08/2026-08-23-release-redraft.md`

### 后续事项

- 实际测试时使用 `$release-easydict draft 2.22.0 --replace-draft`；若中途失败，只使用输出的运行 ID 执行 `resume`。
