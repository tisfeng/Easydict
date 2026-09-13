# 跟进单词本 PR #1246

用户要求跟进 [PR #1246](https://github.com/tisfeng/Easydict/pull/1246)。
以远端 head `db8745ba` 为起点，合入 `tisfeng/dev` 的 `e812288f`；
初始主工作树干净，其他 worktree 没有变更。

## 变更

- 解决基础查询控制器的合并冲突，保留上游反向翻译需要的
  `firstTranslatedText`，不恢复旧收藏入口。
- 首次创建宿主窗口也进入现有激活路径，使单词本可激活并取得键盘焦点。
- 语言选择以当前查询模型判断是否重查，回调保留另一侧语言；交换语言时
  同步更新模型，避免依赖异步偏好通知。
- 星标的共享 Manager 在 MainActor 属性初始化中读取；两个 actor 的默认
  时钟改为显式 Sendable 闭包，处理维护者截图中的三项并发警告。
- 同步单词本、视图层和查询控制器概览，补充 Cell 概览与架构图及 Xcode 引用。

## 验证

- 独立 reviewer 审查六个产品文件及相关调用链，未发现新增缺陷或阻塞项。
- `git diff --check`、工程 plist 和 String Catalog 解析通过。
- 四张受影响 SVG 已渲染并目视检查。
- `xcodebuild test`（arm64、ad-hoc 签名）通过：六个 Wordbook 套件及 ReverseTranslationTests 共 73 项测试、7 个套件。维护者截图中的三项并发警告未再出现；构建仅报告未依赖 AppIntents 的元数据提取提示。
- SwiftFormat lint：本次四个 Swift 文件无格式问题；构建自带格式检查报告 398 个文件均无格式变动。
- 窗口聚焦与回放后手动切换语言的图形交互尚未验证。

## 交付边界

本次只进行本地修改，尚未推送或向 GitHub 发布评论。两条远端 review thread
不能仅凭本地修复标记为解决。远端实际 head 仍为 `db8745ba`。

执行计划：[`PR 跟进计划`](../../exec-plans/completed/2026-09-07-wordbook-pr-followup.md)。

可复跑的回归命令（需在仓库根目录执行）：

```bash
xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict \
  -destination "platform=macOS,arch=arm64" \
  -only-testing:EasydictTests/ReverseTranslationTests \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO
```
