# 重组 Codex 服务目录

- 状态：completed
- 创建日期：2026-11-12
- 负责人：Codex
- 关联 Issue/PR：无

## 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-6
- **Environment:** macOS 27.2 / Xcode 27.2 (27B52)

## 背景

CodexCLI 目录混放两种接入方式、共用 App Server 和一次性连接验证。

## 目标与范围

- 目标结果：按 ChatGPTSignIn、LocalCLI 和 AppServer 组织 Codex。
- 允许修改路径：Codex 生产代码、调用者、测试、Xcode 引用和记录。
- 同任务 history：`docs/histories/2026-11/2026-11-12-organize-codex-service.md`
- 用户限制：保留行为及持久化配置标识。
- 非目标：修改 UI、认证协议或组件版本。
- 验收标准：工程引用完整，现有相关测试通过。

## 工作计划

1. 迁移目录及类型名，拆开连接验证和共用请求。
2. 核对持久化契约、构建及测试，再审查最终差异。

## 风险与决策

- 保持现有请求取消、进程参数及 target membership。

## 进度

- [x] 完成重组和验证。

## 验证

- Debug 构建和 13 个套件共 160 项定向测试通过。
- LocalEnvironment 真实本机 CLI 公式 OCR 和流式翻译 2 项通过。
- 核对 24 个生产文件、14 个测试文件及其 Sources 引用，核对持久化和运行时配置。
- review 复核未发现需修复的差异。本次未单独发起内置浏览器登录或托管 OCR。

## 完成条件

完成实现、相关测试、审查和本地提交。
