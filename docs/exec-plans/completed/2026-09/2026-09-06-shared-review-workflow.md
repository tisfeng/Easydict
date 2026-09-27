# 通用 Review 与并行任务收尾

- 状态：completed
- 创建日期：2026-09-06

## 任务摘要

- 意图模式：implementation；交付授权：auto-local-commit；安全状态：normal。
- 用户批准拆分通用 review、增加 reviewer、与 Terra tester 并行收尾及 PR 自动 resolve。
- 允许路径：`.agents/skills/review/`、`.agents/skills/review-pr/`、`.codex/agents/reviewer.toml`、
  `AGENTS.md`、`docs/agents/` 中相关规则及本任务计划/history。
- history：`docs/histories/2026-09/2026-09-06-shared-review-workflow.md`。
- 禁止 push、真实 GitHub 写入验证、修改产品代码或无关文件。

## 写入前状态

- 初始 HEAD：`88c4b329066490a606611e05ffcccd9994355e33`。
- staged、unstaged、untracked、冲突均为空；上述允许路径为 Agent-owned paths。
- 写入检查通过，自动本地提交 eligible，交付前复核。

## 工作计划

1. 提取只读 review 核心、增加 reviewer 配置及并行收尾规则。
2. 保留 PR checkout，增加线程快照、守卫式 resolve 与报告契约。
3. Terra 编写离线行为测试；独立 reviewer 审查，主 Agent 修复并复验。
4. 验证、归档计划、记录 history、精确暂存并本地提交。

## 风险与验收

- outdated 标记不等于问题失效；语义证据由 Agent 判断，helper 仅检查身份与状态。
- GitHub mutation 无 expected-head CAS；前后刷新降低竞态但不承诺原子性。
- 本地代码和未推送修复不能证明远程线程已解决。
- 最终 reviewer/tester 结果应覆盖同一最终实现；禁止同 workspace 并发构建。
- 测试不访问真实 GitHub，原 checkout 回归测试保持通过。

## 进度

- [x] 实现和文档
- [x] 独立审查、测试与修复
- [x] 归档；本地交付按 Git 门禁执行

## 验证结果

- Terra：18 个线程离线测试、6 个 checkout 回归测试全部通过。
- 独立 reviewer：发现并复核修复分页末尾 head 漂移问题；最终无新增 finding。
- review/review-pr skill 校验、reviewer TOML 解析、`git diff --check` 通过。
- 最终 helper SHA256：`6f32fc2d2fbcc08b8e6a4eb6780c4f5d1fd2fb7fc5e7d8b5bf5f510da6ece0b8`。
- 无真实 GitHub mutation，无应用源码变更，无 Xcode 构建。
