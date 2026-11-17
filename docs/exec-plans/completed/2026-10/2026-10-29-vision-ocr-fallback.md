# 修复 Vision OCR 间歇性失败

- 状态：completed
- 创建日期：2026-10-29
- 负责人：Codex
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/issues/1376

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-5`
- **Environment:** `macOS 27.2 / Xcode 27.1 (27A9275)`

## 背景

macOS 27 上 Vision accurate OCR 在 ANE 模型冷启动、后台运行或缓存异常时可能长时间阻塞、抛错或
返回空结果。本机日志显示启动预热最长耗时 179 秒，预热期间的多个真实 OCR 请求并发进入 Vision，
其中多次在约 27 秒后返回空文本。当前实现固定使用 accurate，不提供 fast 降级；静默 OCR 还会在
错误时复制空字符串并显示成功提示。

## 目标与范围

- 目标结果：为 Apple OCR 增加有界 accurate 尝试和 fast 降级，避免预热竞争，并正确呈现静默 OCR 错误。
- 允许修改路径：`Easydict/Swift/Service/Apple/AppleOCREngine/`、
  `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.m`、
  `Easydict/App/*.entitlements`、本计划及同任务 history。
- 同任务 history：`docs/histories/2026-10/2026-10-29-vision-ocr-fallback.md`
- 用户限制：新建 worktree；修复并验证。未授权新增或扩写测试。
- 非目标：更换 OCR 服务、重构文字合并、修改截图交互、发布或 push。
- 验收标准：accurate 在超时、错误或空结果时回退 fast；冷预热不与真实 accurate 请求竞争；失败不再显示成功；现有相关验证与构建在可用环境中通过。

## 工作计划

1. 提取可配置识别级别，为 modern/legacy Vision 路径增加 fast 降级。
2. 为 modern accurate 请求增加超时和进程级可用状态，协调启动预热。
3. 修复静默 OCR 先报告成功后检查错误的问题，并声明 macOS 27 后台推理 entitlement。
4. 运行格式、差异检查、现有测试和可用构建验证。
5. 使用 review 技能审查，修复有效 finding，更新 history、归档计划并创建本地提交。

## 风险与决策

- fast 识别精度低于 accurate，仅在 accurate 不可用或预热尚未成功时使用。
- Vision 底层工作可能忽略任务取消；超时只保证调用方及时返回，因此超时后将进程标记为 degraded，
  防止继续启动新的 accurate 请求。
- 后台 inference entitlement 依赖签名工具链；若本机无完整 Xcode，只能完成静态校验并明确记录限制。

## 进度

- [x] 实现 accurate/fast 超时、fast 降级，并在 macOS 26+ 停用竞争 ANE 的启动预热。
- [x] 修复静默 OCR 错误路径并更新 entitlement。
- [x] 完成可用验证与 Review；记录生产等价签名测试的本机限制。
- [x] 更新 history 并归档计划；用户明确授权在已知验证限制下提交并创建 PR。

## 验证

- `git diff --check`：通过。
- Xcode 27.1 `swiftc -frontend -parse AppleOCREngine.swift AppleOCREngine+WarmUp.swift`：通过。
- `plutil -lint Easydict/App/Easydict*.entitlements`：通过。
- 使用新增 entitlement 对临时 Mach-O 进行 ad-hoc `codesign` 并回读：通过，签名保留目标 key。
- `swift run --package-path BuildTools -c release swiftformat --lint ...`：通过，0/2 文件需要格式化。
- `xcodebuild build -quiet -workspace Easydict.xcworkspace -scheme Easydict ...
  CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO`：通过；仅提示本机未安装 `swiftlint`，项目脚本
  将其作为非阻塞 warning。
- `xcodebuild test ... -only-testing:EasydictTests/OCRImageTests`：完整编译并运行；unsigned 测试宿主的
  modern accurate 请求在 10 秒 deadline 后按设计切换 fast，证明不会无限等待，但 fast 无法满足现有
  70 个多语言 golden 结果。该运行未携带新增的受限 inference entitlement，不能代表发布签名行为。
- 对测试产物 ad-hoc 签入 inference entitlement 后回读成功，但 macOS 拒绝启动该测试宿主；
  `security find-identity -v -p codesigning` 返回 `0 valid identities found`，无法在本机完成生产等价测试。
- Review：首次发现 fast fallback 缺少 deadline，已增加相同 10 秒上限；Xcode 测试随后发现 warm-up
  pending 时直接 fast 会降低质量，已改为 macOS 26+ 跳过 warm-up、真实请求优先 bounded accurate；
  最终 review 又恢复旧系统 legacy warm-up 的原行为。复审未发现其他有效 finding。

## 完成条件

- 修改满足验收标准，必要静态检查与可用测试通过。
- Review 无未解决的有效 finding。
- history 已更新，计划归档到 `docs/exec-plans/completed/2026-10/`。
- 创建并校验本地提交。
