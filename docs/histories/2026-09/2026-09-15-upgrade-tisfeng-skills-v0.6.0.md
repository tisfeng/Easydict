# 升级 `tisfeng/skills` 至 v0.6.0

- 日期：2026-09-15
- 状态：completed
- 关联 Issue/PR：https://github.com/tisfeng/skills/releases/tag/v0.6.0
- 执行计划：[升级 `tisfeng/skills` 至 v0.6.0](../../exec-plans/completed/2026-09/2026-09-15-upgrade-tisfeng-skills-v0.6.0.md)

## 用户请求

更新本地项目依赖的上游 Skills。

## 主要变更

- 用 `skills@1.5.25` 将六个受管目录和 lock ref 从 `v0.5.0` 升级到 `v0.6.0`。
- 同步 `git-commit` 的本地化正文标记和全局 `References:` 尾段契约；其余五个目录内容不变。
- 更新来源证据为 tag object `1e8cbe576a1558c731a520ef8d008a43be73c46b` 与 peeled commit
  `b4a4791265ca376f3deb4700791cce6e5a470be7`。

## 验证

- 六个目录逐文件匹配固定 tag，独立重算的 SHA-256 全部匹配 lock。
- `git-commit` 19 项测试、Python 语法、JSON 与 patch whitespace 检查通过。
- 本地 review 无 finding；项目专属、第三方和运行时资产未修改。

## 后续事项

无。
