# Agent 覆盖规则

这个目录存放当前仓库的 agent overlay 规则。它们用于补充上游 skill 的本地行为，避免把本地约束写进可能被 `skills add --force` 覆盖的 skill 镜像目录。

## 使用方式

- 先按 `AGENTS.md` 判断是否需要调用某个 skill。
- 读取目标 skill 的 `SKILL.md`，理解上游默认工作流和输出要求。
- 如果 `AGENTS.md` 指向本目录中的 overlay 文件，在执行该 skill 前继续读取 overlay。
- 在系统、开发者及用户有效指令之内，overlay 只覆盖其明确声明的本地职责；其他部分
  遵循原 skill。冲突按来源和适用范围判断，不按“更严格”推断优先级或新增审批要求。

## 文件约定

- 每个 overlay 放在对应目标 skill 的父目录下：
  `.agents/overrides/<target>/`。
- 文件名使用简洁的主题名，例如 `layout.md`。
- 文件内容应只描述当前仓库的局部约束，不复制整个上游 skill。
- 上游 skill 更新后，优先检查 overlay 是否仍然需要保留或调整。

## 当前规则

- `fireworks-tech-graph/layout.md`：技术图的布局、连接线、标签、导出和渲染检查规则。
