# 理工科公式截图翻译

- 状态：completed
- 创建日期：2026-11-06
- 负责人：Box-Chen
- 关联 Issue/PR：[#871](https://github.com/tisfeng/Easydict/issues/871)、[#1352](https://github.com/tisfeng/Easydict/issues/1352)

## 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-6
- **Environment:** macOS 27.0 / Xcode 27.2 (27B52)

## 背景

普通截图 OCR 会把公式的上下标、分数和编号压成一行文字，翻译服务无法还原丢失的结构。

## 目标与范围

- 目标结果：可选的视觉模型截图翻译，原文与译文均排版公式，可复制 LaTeX。
- 允许修改路径：应用源码、工程依赖与相关用户文档。
- 同任务 history：`docs/histories/2026-11/2026-11-06-formula-screenshot-translation.md`
- 用户限制：普通翻译流程保持原样。本地自动保存由用户控制。
- 非目标：在原始截图上覆盖译文。
- 验收标准：常规截图保持原有 OCR 路径，公式模式直传图片；可选择模型与思考强度；保存默认关闭。

## 工作计划

1. 对齐上游 dev 的 OCR、查询窗口和结果渲染。
2. 检查 Codex 图片请求、公式排版与保存开关。
3. 运行相关回归测试并准备上游 PR。

## 风险与决策

- 仅在公式模式切换服务路由，保留普通结果的段落方向处理。
- 公式模式使用本地已登录的 Codex CLI。模型选择取自 Codex 的模型目录。

## 进度

- [x] 检索现有 Issue。
- [x] 适配代码并验证。

## 验证

- Xcode 27.2 编译并运行 Markdown、Codex CLI、Codex App Server 和 OCR/二维码相关测试。
- 首轮 Vision 高精度识别超时后切换到快速识别，导致一项 OCR 文本断言失败。上游原版 OCR/二维码套件 4 项通过，复用分支编译产物复测 100 项通过。
- 本地定制版实测公式识别和排版、复制 LaTeX、普通模式以及模型和思考强度菜单。

## 完成条件

- 通过相关构建和测试，记录实际交互验证的范围。
