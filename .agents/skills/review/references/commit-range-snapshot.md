# Commit/range 只读快照

仅在审查 commit 或 range 时读取。`<review-skill-dir>` 是实际加载的本 Skill 目录。

## 收集

按输入选择一条命令：

```bash
python3 "<review-skill-dir>/scripts/collect_review_snapshot.py" --repo <repo-root> --commit <ref>
python3 "<review-skill-dir>/scripts/collect_review_snapshot.py" --repo <repo-root> --range '<A>..<B>'
python3 "<review-skill-dir>/scripts/collect_review_snapshot.py" --repo <repo-root> --range '<A>...<B>'
```

merge commit 必须明确 `--parent <1-based-number>`；root commit 对比空树。
`--path <repo-relative-path>` 可重复，用于字面路径过滤，不支持 glob/pathspec
魔法或路径穿越。PR 编排器可将已冻结的真实 base 与 remote head 作为
`--range '<base-sha>...<remote-head-sha>'` 交给 helper；这不授权 GitHub 查询、
checkout 或线程操作。latest-base 本地集成结果另取快照。

helper 只读本地 Git 对象，不写索引、ref 或对象，不自动 fetch。验证
`schema_version: 1`，冻结 `snapshot` 中的完整端点和 `fingerprint`，并审查
`changes` 与 `patch`。`A..B` 表示端点树差异，`A...B` 使用唯一 merge-base。
缺失对象、merge parent 歧义或多重 merge-base 时停止，不默默选基线。

helper 不可用时，用同等范围的 Git 命令收集，仍需明确 parent、冻结端点、
完整读取 diff 并在结束前复验；不把摘要或失败输出当作完整证据。

## 分页

`patch` 默认至多返回 24000 个字符，包含完整 patch 的 SHA-256、总字节数、总字符数、
`offset/end` 和 `next_offset`。有后续页时，使用返回的完整 SHA 固定原输入参数，
传入 `--patch-offset <next_offset>` 续读；可用 `--patch-chars <count>` 调整页大小。
分页期间不传 `--expected-fingerprint`，否则未变内容会被省略。

只有所有页的 fingerprint 和 patch 哈希一致，且区间连续覆盖 `[0, total_chars)`，
才算读完。`patch.complete` 只表示本次返回整份 patch。JSON 使用
UTF-8/surrogateescape 无损表示原始字节；二进制 patch、删除、rename 和 mode 变化
仍作为证据，语义或视觉验证不足时明确说明。

## 复验与验证归属

最后以原输入引用和相同 parent、路径参数再次调用：

```text
--expected-fingerprint <initial-fingerprint>
```

`state: unchanged` 可复用原审查；`changed` 返回新快照与 patch，需检查增量。
固定 SHA 不随 HEAD 移动；原输入是分支时，复验其最新解析结果。`checkout` 仅描述
当前 HEAD 和脏状态，不属于提交 fingerprint。补读历史源码使用
`git show <frozen-sha>:<path>`。

运行当前 checkout 的测试前，必须证明相关源码、测试及配置匹配所审查提交；
否则不得把结果归属给该历史提交。检查已提交内容的空白错误时使用
`git diff --check <base-sha> <target-sha>`，其中 base 是快照实际比较的 parent、端点或
merge-base；裸 `git diff --check` 不能证明历史 patch 通过检查。
