# Issue Translator Action v2.9.2 更新

- 日期：2026-09-17
- 状态：completed
- 上游 tag：`tisfeng/issues-translate-action@v2.9.2`
- 上游提交：`92f09e4db5411aea294862418b746c52ccb3a653`

## 用户请求

将 Easydict 的 Issue 翻译工作流引用升级到新发布的 `v2.9.2`。

## 变更

- 将 `.github/workflows/issue-translator.yml` 的 Action 引用从 `v2.9.1` 更新为 `v2.9.2`。
- 保留 `issue_comment`、`issues`、`pull_request_review_comment` 触发器和全部翻译 inputs，不触发真实 workflow。

## 验证

- 已确认上游 annotated tag 的 peeled SHA 与发布提交一致，Release 为非 draft、非 prerelease。
- YAML 解析和 `git diff --check` 通过。
