# Issue Translator Action v2.9.1 更新

- 日期：2026-09-09
- 状态：completed
- 关联计划：[`2026-09-09-issue-translator-v2-9-1.md`](../../exec-plans/completed/2026-09-09-issue-translator-v2-9-1.md)
- 上游 tag：`tisfeng/issues-translate-action@v2.9.1`
- 上游提交：`71e9aa61b05d65b9d82faedbe926b5985255f48b`

## 用户请求

发布新的翻译 Action 版本，并更新 Easydict 的引用。

## 变更

- 将 `.github/workflows/issue-translator.yml` 的 Action 引用从 `v2.9.0` 更新为已发布的 `v2.9.1`。
- 保留 `issue_comment`、`issues`、`pull_request_review_comment` 触发器和全部翻译 inputs，不触发真实 workflow。

## 验证

- 已确认上游 annotated tag 的 peeled SHA 与发布提交一致，Release 为非 draft、非 prerelease。
- YAML 解析和 `git diff --check` 通过。
