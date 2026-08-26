# Easydict Agent 文档治理移植参考

## 来源

本参考对应 Scoco `dev` 上连续的五个 Agent 文档治理提交：

- `85d67f2da`：简化 Agent 文档入口与治理。
- `8d46489f5`：记录 Agent 文档设计和外部参考。
- `7ef43b892`：拆分外部参考目录与专题内容。
- `927793cc9`：强制记录仓库差异并补充文档结构。
- `fb57ab64e`：简化 Agent 规则职责。

## 采用范围

- 采用唯一 Agent 入口、职责分层、请求边界、变更门禁、Git 交付和计划/history 生命周期。
- 采用 design docs 与 references 的分层，用于记录结构理由和来源证据。
- 采用“所有产生仓库文件差异的 implementation 都要有同任务 history”的客观门禁。

## Easydict 本地差异

- 保留 Easydict 的 PR review 完整规则、`submit-pr` 参数、`release-easydict`、
  Planning 子代理、Swift/Xcode 和 String Catalog 规则。
- 不引入 Scoco 的 release、R2/OCU、boss-resume、贡献者文档或产品专属规则。
- 本文件只记录来源与本地取舍，不替代 `AGENTS.md` 或 `docs/agents/` 中的现行规则。

## 重新评估条件

- Scoco 改变 Agent 文档入口、职责分层、Mutation Gate 或 history 门禁。
- Easydict 的 Agent 运行时、Xcode 工程或本地交付规则发生结构性变化。
- 本参考中的提交无法在来源仓库中核对，或本地采用点已经过期。
