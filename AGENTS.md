# AGENTS.md

Easydict 是一款 macOS 词典和翻译应用，支持查词、文本翻译、划词翻译和 OCR 截图翻译。

`AGENTS.md` 是 Agent 的唯一任务入口；详细规则只在对应专题文档维护。

## 任务模式

- 用户要求方案、分析、解释或评估时，只读取和检查现状，不修改文件、Git 或外部服务。
- 用户要求修改、修复、更新、实现或执行时，完成范围内的修改和必要验证；验证通过后自动创建
  本地提交，用户明确要求不提交或没有差异时除外。
- 用户的禁止、范围和顺序要求优先；无法确定是否允许修改时保持只读。push、创建 Pull Request、
  发布及其他外部写入仅在用户明确要求时执行。
- 回复使用用户当前请求的语言；已有文档保持原语言，公共文档遵循 `en/zh` 目录。代码标识、
  API 名称、命令、路径、品牌名称和固定输出契约保留原文。

## 任务路由

- 只读取当前任务需要的专题规则。
- 构建、测试、工程文件与资源、Xcode 验证：`docs/agents/build-and-test.md`。
- 跨语言代码质量、Swift、Objective-C、SwiftUI、API 和本地化：`docs/agents/coding-guidelines.md`。
- 文档分层、计划、history、参考资料、外部 Skills 和同步边界：`docs/agents/README.md`。
- 产品代码、跨功能行为或模块边界：`docs/design-docs/application-architecture.md`。
- 公共使用或贡献者文档：`docs/user-docs/en/` 或 `docs/user-docs/zh/`。

## 项目默认值

- GitHub Pull Request 默认合入 `dev`。
