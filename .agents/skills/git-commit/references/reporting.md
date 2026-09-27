# 统计与提交回执

创建提交成功或汇报已有提交/范围时读取。回执以 Git 中的真实对象和本 Skill 统计脚本为准。

## 变动统计

单提交：

```bash
python3 "<git-commit-skill-dir>/scripts/commit-change-stats.py" <full-commit-hash>
```

多提交范围：

```bash
python3 "<git-commit-skill-dir>/scripts/commit-change-stats.py" \
  --range <target-commit>...<source-commit>
```

脚本只报告文本文件，并将其划分为互斥类别：

- `docs`：位于 `docs` 或 `Documentation` 目录的文件；名为 `AGENTS.md` 或 `SKILL.md`；
  名称以 `README` 或 `CHANGELOG` 开头；或扩展名为 `.md`、`.mdx`、`.rst`、`.adoc`。
- `code`：其他所有文本文件，包括源码、测试、构建/运行时配置、资源和 Skill 脚本。

二进制 numstat 条目被有意跳过，不纳入统计或用户报告。总文件数、新增、删除和净变动
必须分别等于 `code + docs`；脚本失败或数字不一致时不编造统计。

## 回执证据

创建提交后收集：

- `git rev-parse HEAD`：完整 hash。
- `git show -s --format=%B HEAD`：完整实际提交信息。
- `git branch --show-current`：当前分支。
- `git status --short`：最终工作树状态。
- 本节的变动统计。

用户可见回执必须完整保留以下字段：

````markdown
提交结果

- 动作：已创建提交
- Commit：`<full-hash>`
- 分支：`<branch>`
- 提交后校验：`<validation-status>`
- 工作树：`干净` or `保留未提交变更`
- Push：未执行

变动统计

| 类别 | 文件数 | 新增行 | 删除行 | 净变动 |
| --- | ---: | ---: | ---: | ---: |
| 总计 | <files> | <insertions> | <deletions> | <signed-net> |
| 代码 | <files> | <insertions> | <deletions> | <signed-net> |
| 文档 | <files> | <insertions> | <deletions> | <signed-net> |

实际提交信息

```text
<exact output of git show -s --format=%B HEAD>
```
````

中文任务使用上述标签；英文任务翻译标签，保留字段和顺序。正净变动使用 `+N`，
负值使用 `-N`，零值使用 `0（无变化）`。代码块中的信息必须与 Git 完全一致。

本次创建且提交后校验通过时写“通过”。复用已有提交时，动作行说明本次未创建，
校验写“未执行（本次复用已有提交）”，仍保留完整 hash、统计、实际信息、最终状态和 Push。

多提交范围列出每个完整 hash 和 subject，注明未创建新提交和未执行提交后校验，
并输出范围统计。该范围没有单一实际提交信息，不用其中一条代替整个范围。

需要观看完整示例时读取 [完整提交回执示例](post-commit-report-example.md)。
