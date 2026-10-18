## 2026-09-26 | 任务：修正 Books 摘录剥离的提示语匹配

**Links:** Scoco `f19395627`（fix(query): 修正 Books 摘录剥离的提示语匹配）

### 执行上下文

- **Agent Name:** `Mavis`
- **Model:** `deepseek-flash`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

### 用户请求

将 Scoco 对 `removeBooksExcerptInfo` 的改进反向移植回 Easydict，要求直接在 `dev` 分支修改，
并同步中文注释。

### 变更

- `extractBooksExcerptContent()` 的中文正则不再写死完整提示语，改为只要求 `摘` 与
  `版[权權]保[护護]。`，一条覆盖简体／繁体与新旧四种文案组合。
- 两条正则补 `\s*$`，去掉对调用方预先 trim 的隐含依赖；中段 `.+` 收为 `.+?` 与懒惰捕获一致。
- 同步 Scoco 版本的中文注释，说明提示语文案已变化与简繁共享的字形。
- 保留 `removeBooksExcerptInfo()` 中的 `enableRemoveBooksExcerptInfo` 配置判断（Scoco 已移除该开关，
  这是两个仓库的有意差异，未一并移植）。

### 设计意图

Books 的结尾提示语已由「此材料受版权保护。」变为「此内容可能受版权保护。」，而匹配正则仍写死旧文案，
导致摘录无法剥离；繁体中文的「摘錄來自／版權保護」与尾部空白同样不匹配。上游此前无对应修复，
本次为 Scoco 侧发现并反向移植。

保留懒惰捕获 `(.+?)`：Books 本身只输出单个 `“…”` 块，懒惰捕获配合结尾锚定即可取到完整正文；改为
贪婪捕获会在同一段文本含多个引号块时放大捕获范围与查询日志，因此按最小改动原则维持原样。

### 验证

- 从本仓库源文件抽取正则后复跑 16 个用例，全部通过：用户上报样本命中且捕获 248 字符（与正文逐字
  相等）、繁体与旧版文案及英文格式均命中、5 个误伤用例全部返回 `nil`、尾随空白容忍、长文本
  （50023 字符）耗时约 0.03 秒。
- `swiftformat --lint Easydict/Swift/Utility/Extensions/String/String+HandleInputText.swift`：
  0/1 文件需要格式化。
- `git diff --check`：通过。
- `xcodebuild test`（`EasydictTests/UtilityFunctionsTests`）与
  `xcodebuild build -destination 'generic/platform=macOS'`：结果见下方执行记录。
- 手动检查：确认 `extractBooksExcerptContent` 函数体与本仓库修复前后均与 Scoco 对应版本逐字节一致，
  两仓库该函数现为同构。

### 受影响文件

- `Easydict/Swift/Utility/Extensions/String/String+HandleInputText.swift`

### 后续事项

- 未执行真机验证：未在真实 Books.app 中取词确认端到端生效。
- 本仓库无覆盖该函数的测试，本次以临时脚本验证；未新增测试代码（未获授权）。
- 与 Scoco 的有意差异：Scoco 已移除 `enableRemoveBooksExcerptInfo` 开关（其 `3b9f16517`），本仓库保留，
  两仓库在 `removeBooksExcerptInfo` 的开关判断上不同。
