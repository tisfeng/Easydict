# Release Notes Sync

<!-- 文件名：YYYY-MM-DD-<slug>.md；命名规则见 docs/histories/README.md 的“命名与 slug”。 -->

- 状态：active
- 创建日期：2026-09-20
- 负责人：Unknown
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `/root`
- **Model:** Unknown
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

## 背景

当前 `resume` 只恢复冻结的 ASC Release 工作流；发布后手动修改 `changelog/<version>.md` 会被 release-notes 快照判定为 drift，无法同步 GitHub Release 正文和 Sparkle appcast description。需要一个不重建 App、不重新签名、不上传附件的独立同步动作。

## 目标与范围

- 目标结果：新增 `sync-notes <version>` 路由，预览或同步 canonical changelog 到 GitHub Release 和远程 `main/appcast.xml`。
- 允许修改路径：`.agents/skills/release-easydict/SKILL.md`、`.agents/skills/release-easydict/references/release-workflow.md`、`scripts/release/release-easydict.sh`、`scripts/release/release-notes-sync.py`、`scripts/release/release-appcast.py`、相关测试、计划及 history。
- 同任务 history：`docs/histories/2026-09/2026-09-20-release-notes-sync.md`
- 用户限制：不改变 `resume`、`draft --replace-draft` 或正常 publish 语义；本任务不执行实际 `sync-notes --execute`，不修改远程 Release/appcast。
- 非目标：不重建构建产物、不修改 Tag/附件/版本号/构建号/签名/渠道、不自动发布 Draft。
- 验收标准：预览生成确定性候选；execute 使用 Release 与 appcast 的乐观并发校验、可幂等重试；只改目标 appcast 条目的 description；远程状态最终与 canonical changelog 一致。

## 工作计划

1. 增加 appcast 目标 description 更新与严格校验能力。
2. 新增 release-notes-sync helper，支持 preview、execute、状态记录和失败恢复。
3. 接入 shell action 路由、技能文档和发布 reference。
4. 增加 focused tests，运行静态检查和 review。
5. 更新 history，归档计划并创建本地提交。

## 风险与决策

- `resume` 保持只恢复中断工作流，不重新读取变更后的 changelog。
- 默认 preview；只有 `--execute` 才更新 GitHub Release 和远程 `main/appcast.xml`。
- execute 要求目标 Release 已发布、Tag 与版本一致、工作树干净、changelog 已跟踪且无未提交差异。
- 远程 appcast 使用 Contents API 返回的 blob SHA 做 compare-and-swap；SHA 变化时停止，避免覆盖 `main` 的并发更新。
- GitHub Release 通过 `gh release edit --notes-file` 更新；重复 execute 会先验证当前状态，已一致时跳过该写入。
- 状态写入 `.tmp/release/<version>/state/notes-sync.json`，只保存非敏感摘要和目标 SHA，不保存凭据。

## 进度

- [x] 实现同步 helper、路由和 appcast 更新。
- [x] 更新技能文档、测试和状态说明。
- [x] 完成验证、review、history 和本地提交。

## 验证

- 记录 focused Python tests、Shell 语法、`git diff --check`、preview 静态结果和 review 结论。
- 不运行 `sync-notes --execute`，不修改远程 Release 或远程 `main` appcast。

本次验证：

- `python3 -m unittest discover -s scripts/release/tests -p 'test_*.py'`：33 tests passed。
- `bash -n scripts/release/release-easydict.sh`、Python compile checks、`git diff --check`：通过。
- `sync-notes` preview 使用 mock GitHub responses 验证只读；未执行真实远程同步。
- review：未发现需阻止交付的 finding；重点复核了 Release ETag、appcast blob SHA、目标
  description-only 变更、失败状态和幂等重试。

## 完成条件

- `sync-notes <version>` 默认只预览；`--execute` 的远程写入有明确授权和 CAS 保护。
- GitHub Release body、远程 appcast description 与 canonical Markdown 渲染结果可验证一致。
- 计划归档到 `docs/exec-plans/completed/2026-09/`，history 已记录，本地提交完成。
