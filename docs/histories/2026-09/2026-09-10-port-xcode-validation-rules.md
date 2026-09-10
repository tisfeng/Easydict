# 移植 Xcode 验证选择规则

- 日期：2026-09-10
- 状态：completed
- 来源：Scoco `2d57b691d8512781af3c4571aaf113d926a3caa4`
- 关联计划：[移植 Xcode 验证选择规则](../../exec-plans/completed/2026-09-10-port-xcode-validation-rules.md)

## 变更

- 将 Xcode 验证从 100 行硬阈值改为按编译、行为、工程配置和重复测试所需证据选择最小充分命令。
- 明确成功测试可覆盖兼容配置的编译证据，`build` 和 `build-for-testing` 不构成行为测试通过证据。
- 默认复用兼容 DerivedData，仅在权限、缓存损坏或 runner 状态已有证据时使用临时目录 fallback。
- 将命令矩阵适配为 Easydict workspace、scheme 和真实测试标识，删除 Agent 层额外格式或 lint 要求，
  保留工程现有工具及配置。

## 验证

- Bash 示例语法、workspace、scheme、测试源码和工程 Sources 引用静态检查通过。
- 旧阈值、命令占位符、宽泛 fallback、额外格式检查及 Scoco 路径残留扫描通过。
- Markdown 相对链接、目标锚点和 `git diff --check` 通过；独立 reviewer 对规则候选无 finding。
- 未运行 Xcode 构建或测试：本次仅修改治理 Markdown，静态检查不证明实际构建、测试筛选或
  DerivedData fallback 已执行成功。

## 受影响文件

- `docs/agents/build-and-test.md`
- `docs/exec-plans/completed/2026-09-10-port-xcode-validation-rules.md`
