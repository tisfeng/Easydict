## 2026-09-06 | 任务：完善 submit-pr 无模板兼容

**Links:** `../../exec-plans/completed/2026-09-06-submit-pr-template-fallback.md`

### 用户请求

保持 `submit-pr` 位于项目 `.agents/skills/`，完善它在任意 GitHub 项目中对有模板和
完全无模板场景的适配。

### 变更

- 模板发现按 GitHub 规则扫描仓库根目录、`docs/` 和 `.github/`，文件名与模板目录名
  大小写不敏感，并支持 `.md` 与 `.txt`。
- 完全没有模板时继续生成内置四段式正文，不创建模板文件；多个独立模板继续要求显式
  `--template`，同一 inode 的候选先去重。
- 测试移除对 Easydict `.github/pull_request_template.md` 的读取，集成 fixture 默认不含
  模板，并覆盖无模板 `plan/apply`、混合大小写、`.txt`、目录模板和 hard link。
- Skill 与 workflow 契约明确无模板行为。
- 后续措辞复核删除 Skill 存储位置和“通用”自我声明等元话语，收紧入口职责、PR 规范、
  模式和 Issue 策略文案，不改变实际工作流。

### 设计意图

保留项目级 Skill 的正常发现方式以及现有 PR 质量和安全契约，只消除模板发现与测试
fixture 对 Easydict 的隐性依赖。

### 验证

- `PYTHONPYCACHEPREFIX=/private/tmp/submit-pr-template-fallback-pycache python3 -m py_compile
  .agents/skills/submit-pr/scripts/submit_pr.py`：通过。
- `PYTHONPYCACHEPREFIX=/private/tmp/submit-pr-template-fallback-pycache python3
  .agents/skills/submit-pr/tests/test_submit_pr.py -v`：20 个测试通过。
- `git diff --check`：通过。
- 独立 reviewer 增量复核：无有效 finding。
- 独立 tester 最终复验：20 个测试通过，未访问真实 GitHub。
- `quick_validate.py .agents/skills/submit-pr`：未完成；可用 Python 环境均缺少 `PyYAML`，
  helper 报 `ModuleNotFoundError: No module named 'yaml'`；已人工检查 Skill 名称、结构和引用。
- 后续文案修正使用 Ruby YAML 实际解析 frontmatter，确认 description 没有因折叠换行
  插入异常空格；`git diff --check` 通过。

### 受影响文件

- `.agents/skills/submit-pr/`
- `docs/exec-plans/completed/2026-09-06-submit-pr-template-fallback.md`
- `docs/histories/2026-09/2026-09-06-submit-pr-template-fallback.md`

### 后续事项

- None
