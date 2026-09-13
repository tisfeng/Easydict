# `fireworks-tech-graph` 来源参考

- 核对日期：2026-09-13。
- 来源：`https://github.com/yizhiyanhua-ai/fireworks-tech-graph`。
- 上游 Skill 路径：`skills/fireworks-tech-graph`。
- 本地安装路径：`.agents/skills/fireworks-tech-graph/`。
- 采用 ref：`main`。
- 同步时 commit：`31fea364eda5f1852b1175f3d9e29ea31d22dcb4`。
- 安装器：`skills@1.5.25`。

## 采用范围

完整同步上游 Skill 目录，包括 `SKILL.md`、references、scripts、tests、schemas、fixtures、
templates、examples 和必要静态资源。该 Skill 不属于 `tisfeng/skills`，也不接受 Easydict
本地内容修改。

## 已核验同步形式

```bash
npx -y skills@1.5.25 add \
  https://github.com/yizhiyanhua-ai/fireworks-tech-graph/tree/main/skills/fireworks-tech-graph \
  --skill fireworks-tech-graph --agent codex --yes --copy --full-depth
```

命令只选择该来源和 Skill；同步后检查 `.agents/skills/fireworks-tech-graph/` 与
`skills-lock.json` 中对应条目。不要用跨来源的整项目更新代替此步骤，也不要手工调整
computed hash。

2026-09-13 核对时 `main` 仍指向上述 commit，但既有本地快照因 `.gitignore` 的 `Icon?` 规则
在大小写不敏感文件系统上误匹配 `assets/icons/`，缺少受管的
`assets/icons/cloud/manifest-v1.json`。单独重装该来源并为受管路径增加精确的 ignore 例外后，
本地目录与上游 tracked tree 完全一致，目录 hash 也恢复为 lock 记录值。

Easydict 直接从 `.agents/skills/` 读取该 Skill，不维护根 `skills/` 兼容别名；
`.claude/skills` 继续指向同一真实目录。

## 重新核对条件

- `main` 指向新 commit，用户明确要求同步更新。
- 上游开始发布稳定 tag，或移动/拆分 Skill 路径。
- 安装器改变复制内容、hash 或 lock 字段。
