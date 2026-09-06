## 2026-09-06 | 任务：适配 Astra Agent 规则与 Terra 测试委派

**Links:** [执行计划](../../exec-plans/completed/2026-09-06-astra-agent-rules.md)、
[官方建议采用记录](../../references/astra-agent-guidance.md)

### 用户请求

参考 GPT-6 Astra 官方建议检查并适配 AGENTS.md 和文档规则。用户批准完整方案，
要求合并测试文档，并新增使用 gpt-5.6-terra 编写测试和运行验证的子代理。

### 变更

- 明确用户有效指令优先级、跨轮限制和完整语义判定，区分分析与工作流准备副作用。
- 将保护状态限定到具体操作，保留 staged 交付、范围内修复与 history 补齐路径。
- 合并测试文档，新增 Terra/high tester 配置，统一测试价值、构建条件和委派边界。
- 修订提交、review 和发布 skill 的直接冲突，同步入口、overlay、语言和计划模板。

### 设计意图

保留自动本地提交、history、planner 以及固定交付格式，消除会令 Astra 过早暂停的
歧义。tester 只处理分配的测试范围，主 Agent 负责生产修复、共享构建与最终交付。

### 验证

- 三个修改后的 skill 通过 quick_validate.py；最后修改的 git-commit 也复验通过。
- git diff --check 通过，未发现空白错误。
- Terra 子代理在临时目录编写并运行标准库脚本，3 项检查全部通过：两个 Agent TOML
  的配置契约、变更 Markdown 的本地链接目标、有效入口已移除旧测试文档引用。
- 独立场景走读覆盖规划、跨轮禁止提交、staged、失败修复、history 限制、只读 review、
  发布本地计划和 tester 构建协调，未发现规则冲突；主 Agent 已复核脚本与证据。

### 受影响文件

- AGENTS.md、docs/agents/ 和 .codex/agents/tester.toml。
- .agents/overrides/README.md 以及 git-commit、review-pr、release-easydict 的 SKILL.md。
- docs/exec-plans/README.md、docs/exec-plans/templates.md、docs/histories/README.md。
- docs/references/README.md、docs/references/astra-agent-guidance.md、本计划及记录。

### 后续事项

- 当前运行时未暴露 tester custom agent，使用 gpt-5.6-terra + high 显式回退调用成功。
  未验证角色自动发现或一般模型行为，未运行 Xcode 或远程工作流。
