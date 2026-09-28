# PR Review 报告结构优化

- 状态：completed
- 意图：implementation；交付：auto-local-commit；安全状态：normal。
- 授权：实施用户确认的结论优先、来源去重与按复杂度展开方案。
- 初始 HEAD：`2a7c8b891f262c6469410280351784aeff7d5840`；staged/unstaged/untracked 均为空。
- 允许且 Agent-owned 路径：`AGENTS.md`、两个 review skill、本计划及同任务 history。
- 禁止修改产品、模型、checkout/线程脚本、真实 PR 或 push。
- history：`docs/histories/2026-09/2026-09-06-pr-review-report.md`。

## 步骤与验收

1. 替换固定栏目模板，同步正文引用和核心去重契约。
2. 独立离线试用五类报告：无问题、仅新问题、旧问题未修复、复审全修复、混合部分 resolve 失败。
3. 检查来源去重、完整线程覆盖、真实状态、语言与 Markdown；运行 skill 校验及现有线程测试。
4. 修正问题，补齐 history，归档计划并本地提交。

## 风险

- 精简不能删掉代码证据、实质回复、失败状态或准确快照。
- 代码已修复不等于线程已 resolve，计数区分问题与线程。
- 不新增技能或独立模板文件，样例试用在子任务输出中完成。

## 验证

- 两个 skill 校验及 `git diff --check` 通过，脚本/测试/模型配置无变更。
- Terra 独立生成五类报告；主 Agent 发现首轮索引排序、线程链接和原始状态字段问题，
  补充成稿检查后混合报告复验通过，其余样例的位置链接问题已明确修正方式。
- 现有线程测试 18/18 通过；未操作真实 PR 或运行 Xcode。
