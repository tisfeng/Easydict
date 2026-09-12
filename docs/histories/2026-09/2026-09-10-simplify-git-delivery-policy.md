# Git 交付策略精简

- 日期：2026-09-10
- 状态：completed
- 关联计划：[`2026-09-10-simplify-git-delivery-policy.md`](../../exec-plans/completed/2026-09-10-simplify-git-delivery-policy.md)

## 用户请求

整理重复的 Git 交付规则，并保留项目与 `git-commit` Skill 的正确职责边界。

## 变更

- 将 `git-workflow.md` 收敛为项目交付策略：授权、门禁、委派、严格回退和 Easydict PR 参数仍由
  项目维护；暂存、提交、准备/执行与回执算法链接至受管 Skill/TOML。
- 将完整 `expected_commit_paths` 规则限定为 `auto-local-commit`；显式 `commit` 的已有 staged 内容、
  显式路径和显式工作树范围改由 `git-commit` Skill 的暂存决策确定。

## 设计意图

项目文档只规定授权、门禁、委派、回退和 PR 参数；执行细节由受管 Skill 与 git-delivery TOML
统一维护。

## 验证

- `git diff --check` 通过。
- 已检查现行相对链接和 `git-commit` 的中文锚点，且确认未保留暂存策略枚举或 `git add .` 等执行算法。
- 已对自动交付、禁止提交、已有索引、显式路径、显式工作树与已有提交 integration 进行策略场景核对。
- 独立只读 reviewer 以 `404e81d1f08ddb8739edf7b6d7dbe3dbbda44a49` 为基线复核，未发现问题；本次只有
  治理 Markdown，未运行 `xcodebuild`。

## 受影响文件

- `docs/agents/git-workflow.md`
- `docs/exec-plans/completed/2026-09-10-simplify-git-delivery-policy.md`

## 后续事项

- 无。
