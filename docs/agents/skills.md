# 外部 Skill 资产

外部 Skills 的版本治理设计见
[`../design-docs/external-agent-assets-management.md`](../design-docs/external-agent-assets-management.md)。

`skills-lock.json` 中登记的目录是外部权威内容的完整项目快照。lock 记录来源、ref、入口路径和
内容哈希，但不替代仓库内可离线读取的实际文件。外部快照保留上游原文；Swift/Xcode、本地化和
发布等项目政策写入宿主规则，通用 Git、Review 和交付算法由受管 Skill 维护并从上游同步。

- 普通任务不得修改受管快照或手工调整 hash；只有用户明确要求升级时才使用安装器同步。
- 不同来源分别同步，并按 `docs/references/` 中记录的版本和命令核验，不递归复制上游工作目录。
- `fireworks-tech-graph` 保持独立来源；`release-easydict` 是不进入 lock 的项目专属 Skill。
- `.claude/skills` 指向 `.agents/skills`，不是独立副本。
- 同步后核对来源 tree、目录 hash、lock、项目专属 Skill 和符号链接，并运行风险匹配的静态检查
  与 Skill 测试。
