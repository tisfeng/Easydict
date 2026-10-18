## 2026-09-20 | 任务：修复 release-build asc 参数续行并补充 CLI 文档

**Links:** none

### 执行上下文

- **Agent Name:** Unknown
- **Model:** Unknown
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

修复 `release-build.sh` 中 `asc xcode version view` 参数续行错误，并补充 `asc` CLI 与 App Store Connect API Key 权限说明。

### 变更

- 为 `--configuration Release` 补充 Shell 续行符，并让脚本可被测试 source。
- 新增回归测试，验证 `--output json` 与其他参数属于同一次 `asc` 调用且 JSON 管道可解析。
- 在 `docs/releases/easydict.md` 增加 `asc` 安装、自检、命令用途和输出格式说明；API Key 权限明确为 App 管理（App Manager）。

### 设计意图

保持发布入口和现有 workflow 不变，只修复参数边界并用临时 mock 覆盖回归；文档只描述 Easydict 实际使用的第三方 CLI 能力，不复制上游手册。

### 验证

- `asc version`：通过，当前为 `5.4.0`。
- `asc auth status --validate`：通过命令检查；当前 Keychain 无已配置凭据。
- `asc auth doctor`：通过，Keychain 可用且无诊断问题。
- `bash -n .agents/skills/release-easydict/scripts/*.sh`：通过。
- Python 3.12 虚拟环境安装 `requirements.txt` 后，`python -m unittest discover -s .agents/skills/release-easydict/tests -v`：72/72 通过。
- `git diff --check`：通过。
- 未执行真实 Archive、公证、GitHub 或 App Store Connect 写入。

### 受影响文件

- `.agents/skills/release-easydict/scripts/release-build.sh`
- `.agents/skills/release-easydict/tests/test_release_performance.py`
- `docs/releases/easydict.md`

### 后续事项

- 真实发布前仍需在 `asc` 中配置有效的 App Store Connect API Key profile。
