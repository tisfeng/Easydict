# Astra Agent 规则适配

- 状态：completed
- 创建日期：2026-09-06
- 负责人：tisfeng
- 关联 Issue/PR：无

## 背景与目标

按已批准方案消除请求判定、保护状态、Git 交付和 skill 之间的冲突，合并测试规则，
新增使用 gpt-5.6-terra 的测试子代理。保留 planner、history 和自动本地提交制度。

## 任务摘要与授权

- 意图模式：implementation；交付授权：auto-local-commit；安全状态：normal。
- 用户在两轮修订方案后明确要求执行；tester 使用 gpt-5.6-terra + high。
- 允许修改路径：AGENTS.md、docs/agents/、docs/exec-plans/README.md、
  docs/exec-plans/templates.md、docs/histories/README.md、docs/references/、
  .codex/agents/tester.toml、.agents/overrides/README.md、
  .agents/skills/git-commit/SKILL.md、.agents/skills/review-pr/SKILL.md、
  .agents/skills/release-easydict/SKILL.md、本计划及其 completed 归档、同任务 history。
- 同任务 history：docs/histories/2026-09/2026-09-06-astra-agent-rules.md。
- 不修改产品、上游镜像、历史记录或远程状态；不改变现有提交和 PR 固定格式。

## 写入前状态

- 初始 HEAD：f18c0289d9225ce38f7991a2dda22274a40c115e。
- 初始 staged、unstaged、untracked、冲突：均为空。
- 写入前检查：pass；自动提交资格：eligible。
- Agent-owned paths：上述允许路径中本任务实际产生差异的文件。

## 工作计划

1. 统一请求语义、跨轮约束及操作级保护状态。
2. 合并测试文档，新增 tester 配置，同步委派与入口。
3. 修订直接相关 skill、文档生命周期和回复规则，记录官方依据。
4. 检查 TOML、有效引用与场景判断，尝试 Terra 受限验证。
5. 更新 history、归档计划，精确暂存并校验本地提交。

## 风险与决策

授权与安全状态分开表达；验证失败可以修复但不能跳过。保留大变更构建阈值，
避免把纯治理文档检查扩展为应用测试。custom agent 是否可热加载须按实际调用报告。

## 验证与完成条件

- 校验变更 TOML、Markdown 相对链接、有效旧引用和 git diff --check。
- 场景覆盖先规划、跨轮禁止提交、已有 staged、验证失败、history、引用材料与委派。
- 区分静态检查、场景走读、显式 Terra 调用和 custom agent 注册结果。
- 规则无已知冲突后记录实际验证结果并完成一次本地提交。

## 进度

- [x] 规则与配置更新：合并测试文档，新增 tester，收束授权、保护与交付规则。
- [x] 检查与独立验证：三个 skill 结构检查通过；Terra 编写并运行 3 项标准库检查，
  配置、变更文档本地链接及有效旧入口检查全部通过；独立场景走读未发现冲突。
- [x] history 和计划归档。

## 实际验证边界

当前运行时未暴露 tester 角色，使用 gpt-5.6-terra + high 显式参数和 tester 指令
完成受限验证。临时脚本不加入仓库；这验证了本次显式调用，不证明角色自动发现或
模型在所有真实任务中的行为。未运行 Xcode 或远程工作流。归档后再检查链接与 diff，
然后按 git-commit skill 完成本地交付。
