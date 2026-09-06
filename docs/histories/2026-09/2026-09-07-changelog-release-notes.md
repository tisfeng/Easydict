## 2026-09-07 | 任务：以版本 Changelog 统一 Release Notes

**Links:** [`2026-09-07-changelog-release-notes.md`](../../exec-plans/completed/2026-09-07-changelog-release-notes.md)

### 用户请求

新增按版本保存的 `changelog/` Markdown，并接入现有发布流程，使 GitHub Release 正文与
changelog 一致，Sparkle `appcast.xml` 从同一 Markdown 生成应用内更新日志；本次只迁移
并测试 2.22.0，不发布新版本。

### 变更

- 新增 `changelog/README.md` 和从线上 Release 迁移的 `changelog/2.22.0.md`。
- 新增统一的 release notes helper，严格校验 UTF-8/LF/版本文件名，固定
  Python-Markdown 3.6 渲染器，并保存 Markdown 与 HTML SHA-256。
- GitHub Draft 强制使用冻结的版本 Markdown，Draft、publish 和远程验证都会重新检查
  正文一致性，不再回退到 `--generate-notes`。
- Sparkle appcast 只读取冻结 changelog，安全处理裸 URL，并验证 `<description>` 与确定性
  HTML 完全一致；删除联网抓取 Release 正文和不完整 Markdown fallback。
- 发布 preflight、resume、Skill、操作文档和 Issue 跟进审计入口同步到单一正文源模型。
- 新增缺失/格式、快照漂移、远端正文漂移、复杂 Markdown、appcast 漂移和 Draft
  `--notes-file` 行为测试。

### 设计意图

仓库内 `changelog/<version>.md` 是唯一可手动编辑的正文。GitHub 保存原始 Markdown，
Sparkle 保存它经固定渲染器产生的 HTML；发布状态只保存哈希和渲染器身份，不保存另一份
可编辑 notes。版本 Tag 仍指向版本构建快照，不因正文展示格式产生额外移动。

### 验证

- `python3 -m unittest discover -s scripts/release/tests -p 'test_*.py'`：通过，26 个测试。
- `python3 -m unittest discover -s .agents/skills/release-easydict/tests -p 'test_*.py'`：
  通过，23 个测试。
- 2.22.0 线上 Release 只读比对：通过，正文哈希
  `0f5dcd6d3cd492a2a484aec80687176638dc9a6d65bb636032d913182f958799`。
- 仓库 `appcast.xml` 的 2.22.0 description 与 changelog 渲染结果完全一致；使用公开条目
  的 build 65、ZIP 长度、URL、channel 和签名约束完成严格校验。
- `bash -n`：所有变更 Shell 脚本通过。
- `jq -e . scripts/release/asc-workflow.json` 和 `asc workflow validate`：通过。
- `python3 -m py_compile`：变更 Python 脚本与测试通过。
- `skill-creator` quick validation：通过。
- `git diff --check`：通过。
- 独立 reviewer：最终无 P1/P2 finding；三轮复核确认冻结门禁、Git index/工作树漂移和
  Markdown/raw HTML 链接边界均已闭环。
- 独立 tester：在最终快照重复执行 26 个发布测试、23 个 Skill 测试和 2.22.0 appcast
  严格一致性验证，全部通过。
- `xcodebuild`：未运行；本次只修改发布脚本、测试和文档，不涉及 Xcode 编译源码。

### 受影响文件

- `changelog/`
- `scripts/release/`
- `.agents/skills/release-easydict/`
- `docs/exec-plans/`
- `docs/histories/2026-09/`

### 远程状态

- 未创建或发布新版本。
- 未编辑 2.22.0 GitHub Release，未上传资产，未创建或移动 Tag，未 push。

### 后续事项

- 已发布版本若要修订正文，应先修改并提交对应 changelog，再在一次明确授权的维护任务中
  同步 GitHub Release 和 appcast；当前发布流程会把单边修改识别为漂移并停止。
