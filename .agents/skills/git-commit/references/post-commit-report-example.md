# 完整提交回执示例

需要参考完整提交回复时阅读。将示例中的哈希、分支、状态、统计和提交信息替换为本次实际
结果；`SKILL.md` 的 Post-Commit Report 规则和 Git 的实际输出优先。

````markdown
本地 Git 提交完成。

提交结果

- 动作：已创建提交
- Commit：`0123456789abcdef0123456789abcdef01234567`
- 分支：`docs/unify-commit-receipts`
- 提交后校验：通过
- 工作树：干净
- Push：未执行

变动统计

| 类别 | 文件数 | 新增行 | 删除行 | 净变动 |
| --- | ---: | ---: | ---: | ---: |
| 总计 | 5 | 68 | 15 | +53 |
| 代码 | 1 | 8 | 2 | +6 |
| 文档 | 4 | 60 | 13 | +47 |

实际提交信息

```text
docs(git): 统一本地 Git 交付回执

现有提交流程收集了完整结果，但最终回执格式分散，可能被压缩成提交标题。

统一用户可见回执并使用 Markdown 表格展示统计，保留提交信息校验和 JSON 统计数据来源。

这让本地提交提供一致、可核验的结果，并继续保持默认不推送的边界。

----------------------------------------------------------------------

docs(git): unify local Git delivery receipts

The existing commit workflow collected complete results, but its final receipt could be reduced to a commit subject.

Unify the user-visible receipt and render statistics as a Markdown table while preserving message validation and the JSON statistics source.

This gives local commits consistent, verifiable results while preserving the default no-push boundary.
```
````
