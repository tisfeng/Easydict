# 截图期间保留前台焦点

- 状态：completed
- 创建日期：2026-11-06
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B52)`

## 背景

当前截图遮罩成为 key window 并激活 Easydict，导致原应用失焦。用户要求参考 Scoco 精简适配，
截图期间保留前台焦点、键盘隔离和现有结果窗口行为。

## 目标与范围

- 目标结果：非激活截图面板、截图专用主动键盘过滤、取消时不切换前台、结果窗口沿用现有交互。
- 允许修改路径：截图模块、窗口管理器的截图入口、主 String Catalog、Xcode 工程及本任务记录。
- 同任务 history：`docs/histories/2026-11/2026-11-06-screenshot-foreground-focus.md`
- 用户限制：不新增或扩写测试；验证和 review 通过后本地提交，不合入 dev、不 push。
- 非目标：Scoco 标注、取色、撤销、录屏及截图 API 迁移。
- 验收标准：框选/取消不激活应用；D/Esc 与普通输入不穿透；鼠标框选可用；现有结果窗口正常展示。

## 工作计划

1. 固定基线与来源，建立非激活面板及键盘隔离。
2. 清理截图结束后的焦点恢复，处理延迟动作与清理顺序。
3. 运行现有相关测试、构建、静态检查和可行的界面验证。
4. 使用 review 技能审查最终快照，修复后复验，更新记录并本地提交。

## 风险与决策

- 初始 HEAD：`a4d2681132b8687702f561f389dfd8cdfc119020`；索引、工作树均干净。
- 参考 Scoco `aad2738bb6c432ab30020410bc6b86607c98516f` 的事件过滤机制，来源提交为
  `ccc75800774fdf757e1157cbe581cc3b87d29558`、`42d9b72a0e2562af9062465cf1a26d71d90b33e3`。
- 普通键盘输入在截图时隔离；系统切换操作结束截图并放行，不拦截整个系统。
- 仅申请 keyDown/keyUp，不引入 Scoco 的 Shift 取色 tap；已消费键需处理配对松键及跨会话长按。
- 权限失败不回退为激活应用，提示鼠标操作；结果窗口由原有完成回调决定焦点。
- 延迟截图必须绑定会话，清理先于完成回调，避免旧动作影响连续截图。

## 进度

- [x] 读取规则、固定基线及来源。
- [x] 实现精简适配。
- [x] 完成所选范围的验证及 review。
- [x] 更新 history 并归档计划；本地提交作为最终交付步骤。

## 验证

- SwiftFormat lint、SwiftLint strict、`git diff --check`、工程 plutil 和 String Catalog JSON 检查通过。
- 键盘过滤器按 `arm64-apple-macos13.0` 独立 typecheck 通过。
- 默认 build-for-testing 因本机 provisioning profile 缺失失败；验证命令改用 `CODE_SIGNING_ALLOWED=NO`，不修改工程签名配置。
- 构建时使用 `EASYDICT_RELEASE_PACKAGING=YES` 跳过全仓格式化和 lint phase；仅对变更 Swift 文件单独运行检查。
- 本机现有开发签名/profile 可用；通过命令参数选择 Automatic / Apple Development 后，签名的 Debug/macOS arm64 build-for-testing 通过，没有请求 provisioning 更新。
- 现有 OCR QR、英文 OCR 文本处理、查询取消和本地化四个 suite：19 passed、1 failed。
- 唯一失败为 `OCRQRCodeTests/testOCRWithoutQRCode()`；单独复跑及精确基线的对照均失败，xcresult 中实际文本、预期文本与断言完全相同，属于现存 OCR 降级后的 golden 差异。
- 用户最终选择只做可行界面检查和静态验证，不使用 CGEvent 注入。界面工具访问现有调试实例持续超时，原实例未退出或替换；真实焦点、键盘拦截和权限失败场景没有记为实机通过。
- 最终任务源码的开发签名 build-for-testing 再次通过；最终八个生产/工程/资源文件与已测试、已审查快照一致。
- 按 review 技能核对非激活窗口、首次鼠标操作、输入消费/配对释放、跨会话延迟动作、中断恢复、失败降级及结果路径，未发现确认 finding。快照摘要：`ff3d0f260e93a9a2ab64e8a64d4d47f23768964be2ddea7991fbbebc13a6b199`。
- 不新增测试，现有测试不能替代真实键盘和焦点验收。

## 完成条件

- 范围内实现和风险匹配验证完成；review 无未解决有效 finding。
- 记录真实验证边界，更新 history 并将本计划归档到 `completed/2026-11/`。
- 本地提交校验通过，dev 与远端保持不变。
