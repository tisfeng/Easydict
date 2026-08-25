# Helper 命令映射

以下命令从仓库根目录执行。将 `<version>` 替换为目标版本；默认仓库固定为
`tisfeng/Easydict`。

## Git 引用边界

- `draft` 只推送 `release/sync-<version>` 和版本 Tag；不得把 Draft 提交直接推送到
  `origin/dev` 或 `origin/main`。
- `publish` 在 GitHub Release 公开前完成 merge 预检；安装 appcast 后安全更新本地
  `dev`，再原子更新远程 `dev`、`main` 和临时发布分支。
- 远程验证通过后删除临时发布分支。版本 Tag 始终停留在版本元数据提交，`main`
  停留在 appcast 提交，`dev` 停留在包含最新开发提交和 appcast 提交的集成结果。
- Publish 失败时使用 asc run ID 恢复，不手工 rebase 或强推这些引用。

## 重新创建同版本 Draft

只有用户明确要求废弃并重建当前最新 Draft 时，才使用：

```bash
./scripts/release/release-easydict.sh draft <version> --replace-draft
```

该命令自动递增并冻结构建号，不接受 `--build-number`。失败后不要再次运行新的
`--replace-draft`，应使用结果中的运行 ID：

```bash
./scripts/release/release-easydict.sh resume <run-id>
```

新 Draft 验证成功后，再执行下方内容捕获和英文整理命令；不得复用旧 Draft 的
`release-content-*` 或 `issue-followup/` 状态。

## Draft 内容

```bash
.agents/skills/release-easydict/scripts/release_content.py capture \
  --repo tisfeng/Easydict \
  --version <version> \
  --output .tmp/release/<version>/state/release-content-source.json
```

根据捕获文件生成完整的 curated JSON，不得遗漏或增加 PR：

```json
{
  "schema_version": 1,
  "source_sha256": "copy from release-content-source.json",
  "release_title": "2.22.0 ✨ feat: add a global translation toggle",
  "highlight_pr": 1203,
  "entries": [
    {
      "pr_number": 1203,
      "title": "feat(shortcut): add a global translation toggle shortcut"
    }
  ]
}
```

然后渲染并预览应用计划：

```bash
.agents/skills/release-easydict/scripts/release_content.py render \
  --source .tmp/release/<version>/state/release-content-source.json \
  --curated .tmp/release/<version>/state/release-content-curated.json \
  --output .tmp/release/<version>/state/release-notes-en.md

.agents/skills/release-easydict/scripts/release_content.py apply \
  --repo tisfeng/Easydict \
  --version <version> \
  --source .tmp/release/<version>/state/release-content-source.json \
  --curated .tmp/release/<version>/state/release-content-curated.json \
  --notes .tmp/release/<version>/state/release-notes-en.md
```

先检查不带 `--execute` 的 JSON 计划，再使用相同命令追加 `--execute`。只有目标
Release 仍为相同 Draft 且正文没有在 capture 后变化，helper 才允许写入。

## 发布后 Issue 跟进

GitHub Release 发布和远程验证成功后，在同一个 skill 内继续执行：

```text
$release-easydict issue-followup apply <version>
```

不要求用户先运行 `plan`。`apply` 会重新捕获当前 Release 和 Issue 状态、生成并冻结
最新计划，再执行评论与关闭动作。失败后使用：

```text
$release-easydict issue-followup resume <version>
```

如果只需要预览关联和分类，不执行远程写入：

```text
$release-easydict issue-followup plan <version>
```

具体 helper 参数、schema-v2 状态和固定报告规则由
[issue-followup.md](issue-followup.md) 维护。
