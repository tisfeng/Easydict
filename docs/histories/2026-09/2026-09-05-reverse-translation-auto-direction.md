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
- 首轮修复未扩展默认 `Auto → Auto` 的 no-op 行为，也未修改全局自动语言选择策略。
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

## 2026-09-06：双 Auto 采用译文重新查询

用户确认采用简化方案：将首服务的完成译文放入输入框，再按现有 Auto 规则查询。
不增加临时语言覆盖，不保证严格返回原语言；双 Auto 选项和默认语言偏好保持不变。
单侧 Auto 和显式语言组合继续沿用前述修复。

- 本轮初始 HEAD：`ee39e2d255b4309d552b2da6aac5301994d56712`；工作树和索引干净。
- GitHub PR head 仍为 `b43578c55beeba3283542610259c3110e0f2ff1f`，保留现有本地修复提交。
- 授权：implementation，验证通过后自动本地提交，不 push。
- 本轮允许路径：`EZBaseQueryViewController.m`、`ReverseTranslationTests.swift`、本记录。
- 双 Auto 绕过 raw 语言相等的交换门禁；只采用当前查询中已完成、无错误的首服务译文。
- 清除旧 OCR 图片后复用普通文本查询入口；加载、错误、空或过期结果不触发重查。
- 更新后的定向 Xcode 测试通过：6 个测试方法、17 个场景，0 失败。
  命令：`xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict
  -destination 'platform=macOS,arch=arm64' -only-testing:EasydictTests/ReverseTranslationTests
  ENABLE_PREVIEWS=YES CODE_SIGNING_ALLOWED=NO`。
- 测试以单实例临时子类捕获普通查询入口，验证译文、动作类型和 OCR 清理，不调用翻译服务。
- 测试文件 `swiftformat --lint`、`git diff --check` 通过；未运行完整测试套件或人工界面验证。

## 2026-09-06：拒绝纯空白回译结果

- 修复 [review comment](https://github.com/tisfeng/Easydict/pull/1276#discussion_r3941266857)
  指出的非双 Auto 分支采用纯空白译文后丢失原输入的问题。
- 本轮初始 HEAD：`c41fcd7076dfe698e6a095fdaa8f499a0e064ece`，与实时 PR head 一致；
  初始暂存、未暂存和未跟踪文件均为空。
- 授权：implementation，验证通过后自动本地提交，不 push。
- 本轮允许路径：`EZBaseQueryViewController.m`、`ReverseTranslationTests.swift`、本记录。
- 采用译文前统一检查 trim 后非空；纯空白结果保留原输入、OCR 和查询动作，
  沿用原有的仅交换语言回退行为。
- 在非双 Auto 的无效结果参数化测试中补充纯空白场景，复用现有状态断言。
- 首次定向测试通过但仍运行旧版 17 个场景；刷新测试源码时间戳后重新编译验证。
- 验证：沿用上述 arm64 定向 Xcode 命令，6 个测试方法、18 个场景通过，0 失败；
  日志确认非双 Auto 的纯空白场景实际执行。测试文件 `swiftformat --lint` 和
  `git diff --check` 通过。
- 未运行完整测试套件或人工界面验证；未推送或修改 GitHub 评论。
