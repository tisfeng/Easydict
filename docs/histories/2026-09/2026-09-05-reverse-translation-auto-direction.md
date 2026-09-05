# 保留 Auto 回译的实际语言方向

- 日期：2026-09-05
- 状态：completed
- 关联 PR：[#1276](https://github.com/tisfeng/Easydict/pull/1276)

## 请求与范围

修复 Auto 源语言在反向翻译时丢失实际检测语言的问题。例如日语自动检测后翻译为中文，
再次交换应回到日语，而不是按中英偏好重新选择英语。

- 初始分支：`feat/swap-translated-text`。
- 初始 HEAD：`b43578c55beeba3283542610259c3110e0f2ff1f`，与实时 PR head 一致。
- 初始暂存、未暂存和未跟踪文件均为空。
- 授权：implementation，验证通过后自动本地提交，不 push。
- 允许路径：查询窗口 controller、对应回归测试及必要的测试工程引用、本记录。

## 变更

- 在采用完成译文前捕获有效源语言和目标语言，并将其交给现有语言交换路径。
- 有效语言未确定或相同时不替换输入；加载、错误、无结果及未完成流式输出保留原行为。
- 保留现有 OCR 转普通文本查询逻辑。
- 不扩展默认 `Auto → Auto` 的 no-op 行为，也不修改全局自动语言选择策略。
- 增加 `ReverseTranslationTests`，通过实际 controller/cell 验证 9 个场景，
  测试期间保存并恢复语言偏好，不启动翻译请求。

## 验证

- `git diff --check`、测试文件 `swiftformat --lint`、工程 `plutil -lint`：通过。
- 定向 Xcode 测试通过：5 个测试方法、9 个场景，0 失败。
  命令：`xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict
  -destination 'platform=macOS' -only-testing:EasydictTests/ReverseTranslationTests
  ENABLE_PREVIEWS=YES CODE_SIGNING_ALLOWED=NO`。
- 构建使用 `ENABLE_PREVIEWS=YES` 跳过全仓格式化步骤；测试文件单独执行 lint。
- 未执行完整测试套件或人工界面验证；未推送或修改 GitHub PR。
