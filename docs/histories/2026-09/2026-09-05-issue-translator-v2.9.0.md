# Issue Translator Action v2.9.0 中文优先双向翻译

- 日期：2026-09-05
- 状态：completed
- 上游 tag：`tisfeng/issues-translate-action@v2.9.0`
- 上游提交：`f3fee895e6347f01d35b4f3e169a7b5d44228b64`

## 用户请求

更新 Issue 翻译 Action 至 `v2.9.0`，并配置 `PRIMARY_LANGUAGE: zh-CN`、`SECONDARY_LANGUAGE: en`。

## 变更

- 将 `.github/workflows/issue-translator.yml` 中固定的 Action 引用从 `v2.8.3` 更新为 `v2.9.0`。
- 配置中文为首选语言、英文为反向目标语言；中文内容翻译为英文，英文内容翻译为简体中文。
- 将 bot 提示改为与任意翻译方向一致的中性文案，保留 `IS_MODIFY_TITLE: false`。

## 设计意图

`PRIMARY_LANGUAGE` 是非首选语言内容的目标语言，`SECONDARY_LANGUAGE` 是首选语言内容的目标语言。因此日文、韩文和无法识别的文本也会翻译为简体中文；标题和正文分别选择目标语言，原始标题不会被直接修改。

## 验证

- 上游 `v2.9.0^{}` 在更新前解析到 `f3fee895e6347f01d35b4f3e169a7b5d44228b64`。
- 上游 Action 的 `PRIMARY_LANGUAGE`、`SECONDARY_LANGUAGE` 输入及 `node24`、`dist/index.js` 运行时契约已核验。
- 本地 YAML 解析、`git diff --check` 和运行时引用范围审计：通过；运行时 workflow 引用唯一且为 `v2.9.0`。
- 未运行 `actionlint`：本机未安装该工具；本次仅变更 Action 引用与 `with` 输入，未改事件、表达式或权限。

## 后续事项

- 不执行推送；自然发生的 Issue、评论或 PR review comment 将验证 GitHub Runner 中的真实双向翻译行为。
