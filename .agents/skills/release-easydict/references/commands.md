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

新 Draft 必须从已经提交的 `changelog/<version>.md` 创建。不得复用旧 Draft 正文或
`issue-followup/` 状态。

## Draft 内容

发布前先编辑和验证唯一正文源：

```bash
python3 scripts/release/release_notes.py validate \
  --file changelog/<version>.md \
  --version <version>
```

Draft 创建成功后只整理标题。先预览：

```bash
python3 .agents/skills/release-easydict/scripts/release_content.py apply \
  --repo tisfeng/Easydict \
  --version <version> \
  --notes changelog/<version>.md \
  --title '<version> <emoji> <type>: <concise English summary>'
```

检查 JSON 计划后，在相同命令末尾追加 `--execute`。helper 只编辑标题；只有目标 Release
仍为相同 Draft 且正文与 changelog 一致时才允许写入。

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
