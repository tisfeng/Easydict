# Easydict 技能发布流程总览

<!-- 文件名：YYYY-MM-DD-<slug>.md；命名规则见 docs/histories/README.md 的“命名与 slug”。 -->
<!-- 本模板只用于多步骤、跨模块或高风险的执行任务。 -->

- 状态：completed
- 创建日期：2026-09-20
- 负责人：tisfeng
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `Unknown`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

## 背景

技能管理规则、发布脚本说明、`release-easydict` Skill 和 Apple 凭据检查分散在多个文件中。
现有文档可以指导熟悉维护者，但缺少一份从首次设置到 Draft、Publish、恢复和发布后同步的
执行者总览。

## 目标与范围

- 目标结果：新增一份中文总览，解释 Apple 账号、证书、Keychain、GitHub 和 Sparkle 凭据的
  设置与消费位置，并列出发布 Skill 的主要命令和阶段边界。
- 允许修改路径：`docs/agents/`、`scripts/release/README.md`、`docs/agents/skills.md`、
  本计划、同任务 history。
- 同任务 history：`docs/histories/2026-09/2026-09-20-document-release-easydict-skill.md`
- 用户限制：不执行真实发布，不修改密钥、远程 Release、Tag、分支或产品代码。
- 非目标：不改变发布脚本、Skill 行为、凭据格式或旧版 legacy 发布实现。
- 验收标准：文档中的命令、默认值、状态路径和授权边界可从当前脚本/Skill 追溯；Markdown
  链接和格式检查通过。

## 工作计划

1. 核对当前发布脚本、`asc-workflow.json`、`release-easydict` Skill 和 Apple 凭据消费点。
2. 新增发布 Skill 总览，并在现有 Skill/发布 README 中加入入口。
3. 检查相对链接、Markdown 格式和 `git diff --check`。
4. 记录 history，归档计划并创建本地提交。

## 风险与决策

- 只记录仓库实际读取的配置和命令；未在本机安装或验证的 `asc` 命令以 CLI 官方帮助为
  依据，并明确不把私密值写入仓库。
- 新版工作流使用 `asc` 的统一 App Store Connect 认证；`release-easydict-legacy.sh` 的
  `notarytool` profile 只作为兼容性说明，不作为当前主流程要求。
- `docs/agents/skills.md` 继续承担 Skill 来源与同步规则；发布操作细节由新增总览和现有
  `scripts/release/README.md` 分工承载。

## 进度

- [x] 新增总览文档。
- [x] 补充入口链接。
- [x] 完成静态检查并记录 history。
- [x] 归档计划并创建本地提交。

## 验证

- `bash -n scripts/release/*.sh`：通过。
- `python3 -m py_compile scripts/release/release_notes.py scripts/release/release-notes-sync.py scripts/release/release-appcast.py`：通过。
- 变更文档的相对 Markdown 链接检查：通过。
- `git diff --check`：通过。
- 未运行 Xcode 构建、Archive、公证或真实发布；本任务只修改治理 Markdown。

## 完成条件

- [x] 总览覆盖凭据设置、主要命令、生命周期、恢复、Issue 跟进和状态目录。
- [x] 现有发布 README 与 Skill 文档可从入口互相跳转。
- [x] 检查通过，history 已记录，计划已归档到 `docs/exec-plans/completed/2026-09/`。
