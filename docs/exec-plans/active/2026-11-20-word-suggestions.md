# 输入框单词推荐列表

- 状态：active
- 创建日期：2026-11-20
- 负责人：Anson
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Claude Code`
- **Model:** `claude-opus-5-5`
- **Environment:** `macOS 26.6.2 / Xcode 27.2 (27B52)`

## 背景

在查询面板手动输入单词时，用户往往对单词不熟、拼不准，或想查同一词根其他词性的词。目前输入框
没有任何补全或纠错，只能拼对后回车查询。

## 目标与范围

- 目标结果：手动输入单个英文单词时，输入框下方弹出推荐列表，从最相似的单词开始，一行一个，
  显示单词、词性和主要中文释义；容忍一定程度的拼写错误；输入拼写正确的单词时追加同根的其他词性词汇。
- 允许修改路径：`Easydict/Swift/Feature/WordSuggestion/`、`Easydict/objc/ViewController/View/QueryView/EZQueryView.m`、
  `Easydict/Swift/Feature/Configuration/` 中的偏好键、`GeneralTab.swift` 设置项、`Easydict/App/Localizable.xcstrings`、
  `Easydict.xcodeproj/project.pbxproj`、相关测试与文档。
- 同任务 history：`docs/histories/2026-11/2026-11-20-word-suggestions.md`
- 用户限制：在线数据为主；不做中文反查，不接 LLM 语义找词；界面按已确认的示意图（去掉“你是不是要找”标题行）。
- 非目标：内置离线词库、Ollama 描述找词与辨析、列表防闪烁。
- 验收标准：拼错单词（如 fonetic、rekon）能给出正确候选；前缀输入能补全；每行带词性和中文释义；
  ↑↓ 选择、回车查询所选词、Esc 关闭列表；断网时仍显示候选单词，原查询流程不受影响。

## 工作计划

1. 候选词：`NSSpellChecker` 的纠错（guesses）与补全（completions），按编辑距离与前缀匹配排序。
2. 释义：有道联想接口 `dict.youdao.com/suggest` 补充词性与中文释义，并合并其前缀候选。
3. 同根词（二期）：输入为拼写正确的单词时，读取有道 `jsonapi_s` 的 `rel_word`，过滤屈折变化后追加。
4. 界面：输入框下方的子窗口列表，键盘与鼠标交互；在 `EZQueryView` 中接入。
5. 构建、单元测试（排序与解析）、本机实测。

## 风险与决策

- 有道联想与 `jsonapi_s` 为非公开接口，可能变更或限流；失败时只显示本地候选，不影响查询。
- 用户输入会发送到有道；只在手动输入单个英文单词时请求，并加防抖与缓存。
- 使用系统拼写检查而非自建词表，离线可用且纠错质量已实测（fonetic→phonetic、sycology→psychology）。
- 偏好键 `enableWordSuggestion` 默认开启，`wordSuggestionSource` 默认有道；设置页「通用」可关闭或改为仅本地。
- 有道 `jsonapi_s` 未签名请求会对许多词返回随机词条，须使用网页签名请求并校验返回的 `input`。

## 进度

- [x] 候选词与排序
- [x] 有道释义与同根词
- [x] 推荐列表界面与交互（按用户反馈改为固定间距单行、提示跟随界面语言）
- [x] 第二批：匹配加粗、Tab 填入、短语、中文反查、系统词典兜底、设置页开关与数据来源
- [ ] 界面验证清单与截图
- [ ] 单元测试（待用户授权）

## 验证

- 见同任务 history 的“验证”一节；界面交互清单尚未逐项确认。

## 完成条件

验收标准全部满足，构建与相关测试通过，history 记录完成，计划归档到 `completed/2026-11/`。
