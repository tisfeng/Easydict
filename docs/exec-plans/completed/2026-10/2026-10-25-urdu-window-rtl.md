# Urdu 全窗口界面方向

- 状态：completed
- 创建日期：2026-10-25
- 负责人：Codex
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/pull/1374

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode Unknown (Unknown)`

## 背景

PR 已更新到 `5708742dd6dc84c377d72f4bb75c4d2674ffc7dc`，包含维护者的 dev 集成与
LocalizationTests 验证记录。C1 的 GitHub Models 引用已删除；C2 的 AppKit/其他 hosted roots
方向缺口仍存在。用户明确选择实现全窗口 RTL，取代此前仅设置/菜单 RTL 的范围。
初始工作树干净，从 `076f23b6` 安全 fast-forward 到准确 PR head，没有丢弃本地提交。

## 目标与范围

- 目标结果：所有用户可见 SwiftUI window roots 和 AppKit 查询窗口使用选中的界面方向；
  已打开和新建窗口均响应 Urdu/English 切换。
- 允许修改路径：Localization、App 入口、hosted window 创建处、AppKit query/titlebar/language/
  result chrome、工程引用及本任务 plan/history。
- 同任务 history：`docs/histories/2026-10/2026-10-25-urdu-window-rtl.md`
- 用户限制：保留无关工作；普通 push 现有 fork 分支，维持 Ready；不新建 PR、不合并或发布。
- 非目标：改变翻译源/目标选择、强制翻译内容方向、镜像截图/图像坐标、修改 provider 或新增测试。
- 验收标准：方向在新建和切换时传播；固定 chrome 位置镜像；文本内容、字典内容和屏幕坐标保真；
  运行可用验证及 review，更新真实 PR 描述，不将旧 head 的测试或 CI 归属于新实现。

## 工作计划

1. 冻结准确 head/base/threads，核对当前规则、入口和全部 hosted roots。
2. 使用共享 SwiftUI 本地化 modifier 与 AppKit 方向适配，更新查询窗口的语义 chrome 布局。
3. 运行既有检查和适用 build/test，按 review 技能复查实现与调用链，修复确认问题。
4. 更新 history、归档计划、提交和普通 push，更新现有 PR 描述并复验 head/status/CI/threads。

## 风险与决策

- SDK 明确基本 NSView 不自动镜像；仅设置根视图方向不足，需要遍历应用视图并使用语义约束。
- 保留结果内容自然方向；只镜像控件 chrome，不翻转文字、图像、WebView 或截图坐标。
- 本机仅 Command Line Tools；维护者旧 head 的 5 个 hosted tests 通过记录不能替代新实现验证。
- 未获新增/扩写测试授权，运行既有测试并记录环境阻塞，不增加测试 helper 或生产测试 hook。

## 进度

- [x] 冻结远程证据并安全同步准确 PR head，初始 5 项 checks 成功，开放线程 2。
- [x] 实现所有界面入口和 AppKit chrome 的方向更新。
- [x] 完成可用验证、review 和 history，归档实现计划；本记录随代码提交，随后普通 push、更新
  PR 描述并复验最终远程状态，远程回执与最新 CI 在交付回复记录。

## 验证

- `xcodebuild -version`：仅 Command Line Tools，完整 Xcode 不可用。
- 新共享 SwiftUI modifier、AppKit adapter、原有 LanguageState/I18nHelper、通知与 popup 扩展使用
  实际应用头文件，针对 `arm64-apple-macosx13.0` 的 Swift 5 typecheck 和 module/header emit 成功；
  核对生成的 `EZI18nHelper` 方法名与 Objective-C 调用一致。没有伪造应用类型或引入测试 fixture。
- 修改后 13 个 Swift 文件语法解析成功，`plutil -lint` 与 `git diff --check` 通过。
- 工程对象审计：仅新增两个生产文件的 file/build/group/Sources 引用，原有 build settings 不变。
  两个 catalog 与起始 head byte-identical，仍有 564/4 个 Urdu 条目；没有修改既有测试。
- SDK 文档确认 NSView 默认使用系统方向，需逐视图设置；平台布局观察确认 leading 常量在 RTL
  下自动镜像。实现未反转视图、字符串或 WebView 内容。
- `xcodebuild build` 与 LocalizationTests 调用在入口因缺少 Xcode 失败；不能将维护者起始 head
  的五项 hosted tests 通过记录归属于本实现。没有修改后应用运行或截图。
- review 技能复查完整本轮 diff、新文件、动态 row/result 重建、标题栏按钮顺序、popup 菜单、
  坐标隔离及工程引用。已修复实现过程中 native popup 的 actor 隔离问题与语言按钮的约束重建
  风险；最终可用编译检查通过，无确认的未修复实现 finding。完整 GUI 仍待 Xcode 环境验证。

## 完成条件

- 完成方向传播、切换与 chrome 布局实现，保留内容/坐标边界并完成可用验证和 review。
- 记录环境限制并交付现有 Ready PR 的准确最终状态。

## 后续 popup 修正

- 对 `7ea15d8d` 的新 review finding 已确认并修复：RTL popup 更新尺寸后，从触发按钮的
  `bounds.maxX` 减去菜单宽度，避免将菜单左上角直接放在按钮右侧。
- 共享 helper 覆盖语言、模型、通用选项和快捷操作菜单；LTR 原点和垂直间距不变。
- 实际源码 Swift 5 / macOS 13 typecheck 与 whitespace 检查通过；按 review 技能复查补丁及
  五处调用，没有确认的未修复 finding。build/test 仍因没有完整 Xcode 失败，GUI 对齐未验证。
- 本轮为单个 helper 的局部修正，复用同任务 plan/history，不新增执行计划或测试。

## 后续 Apple Translation 编译修正

- CodeQL run #3177 在 `1e88f2ef` 的应用构建阶段报出 AppleTranslation lazy controller 的
  opaque return type 推导错误；本机扩大 focused 编译范围后重现。
- 显式保存为 `NSViewController`，保留实际 hosting controller 及其 RTL modifier。修正后同一组
  真实源码 typecheck 和扩大后的 module/header emit 均通过；review 覆盖三处 controller 读取。
- workspace build/test 仍因本机缺少完整 Xcode 失败，后续 CI 必须对应新提交。复用同任务记录，
  不修改 workflow、不新增测试；runtime、截图和独立 Urdu 审校限制继续适用。
