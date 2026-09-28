# Release Notes Sync Dev and Local Integration

<!-- 文件名：YYYY-MM-DD-<slug>.md；命名规则见 docs/histories/README.md 的“命名与 slug”。 -->

- 状态：completed
- 创建日期：2026-09-20
- 负责人：Unknown
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `/root`
- **Model:** Unknown
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

## 背景

`sync-notes` 当前只通过 GitHub Contents API 更新远程 `main/appcast.xml`，不会把
appcast 修订记录到本地 Git 或远程 `dev`。需要让内部工具一次安全地同步 GitHub Release、
远程 `main`、远程 `dev` 以及本地分支，并移除只更新单个 appcast 分支的参数。

## 目标与范围

- 目标结果：`sync-notes <version> --execute` 使用 Git 提交和 lease 保护同步 `main`/`dev`，
  更新本地 `dev`/`main`，并保持 Release 正文一致。
- 允许修改路径：发布脚本、发布 Skill 文档、公开发布指南、相关测试、计划及 history。
- 同任务 history：`docs/histories/2026-09/2026-09-20-release-notes-sync-dev-local.md`
- 用户限制：不 push 任务分支；不改变 `resume`、`draft` 或正常 `publish` 语义；移除
  `--appcast-branch`，内部固定使用 `main` 和 `dev`。
- 非目标：不重建 App、不重新签名、不上传附件、不修改 Tag、版本号、构建号或渠道。
- 验收标准：preview 展示两个远程分支和本地状态；execute 只改变目标 description，
  原子更新远程 `main`/`dev`，安全推进本地分支，并支持幂等恢复。

## 工作计划

1. 将 appcast 同步从 Contents API 单分支写入改为临时 worktree Git 提交和双分支集成。
2. 增加远程 branch head、lease、原子 push、本地分支 fast-forward 和最终验证状态。
3. 移除 `--appcast-branch`，更新 Skill/reference 和 focused tests。
4. 运行脚本测试、静态检查和本地 review，修复有效 finding。
5. 更新 history，归档计划并创建本地提交。

## 风险与决策

- 远程 `main` 和 `dev` 使用 branch head 与 Git push lease 双重校验，避免覆盖并发提交。
- 远程 `dev` 通过 merge 包含远程 `main` 的 appcast 提交，并保留本地已提交 `dev` 提交。
- 本地 `main` 只能 fast-forward；存在分叉或不干净的已 checkout worktree 时停止，不覆盖。
- 远程 Git 更新和 Release body 更新允许部分成功；状态文件记录阶段，重试时跳过已一致目标。

## 进度

- [x] 实现双分支 Git 同步和本地更新。
- [x] 更新文档与测试。
- [x] 完成验证、review、history 和本地提交。

## 验证

- `python3 -m unittest discover -s .agents/skills/release-easydict/tests -p 'test_*.py'`：首次运行
  在测试断言后清理临时 Git 目录时遇到目录非空；仅对测试进程禁用 Git 自动 maintenance/gc
  后重跑，71 项全部通过，未修改仓库配置。
- `test_release_notes_sync.py` 和 `test_release_redraft.py`：相关 12 项测试通过。
- `python3 -m py_compile .agents/skills/release-easydict/scripts/release-notes-sync.py`：通过。
- `bash -n .agents/skills/release-easydict/scripts/release-easydict.sh`：通过。
- `git diff --check`：通过。
- `sync-notes 2.23.0` preview：同时读取远程 `main`/`dev` 和本地分支；显示本地 `main` 落后。
- review：修复临时 worktree 清理不应覆盖主错误、本地 fast-forward 前需复查 HEAD/clean 状态、
  远程 branch head 读取竞态、origin 主机精确校验，以及迁移后公开指南行为描述未同步等问题；
  复核未发现需阻止交付的 finding。
- 未执行真实 `sync-notes --execute`，未修改远程 Release 或分支。

## 完成条件

- 远程 `main`/`dev`、本地 `dev`/`main` 和 Release body 的同步路径有并发保护和最终核验。
- `--appcast-branch` 已移除，文档和帮助输出与实现一致。
- 计划归档到 `docs/exec-plans/completed/2026-09/`，history 已记录，本地提交完成。
