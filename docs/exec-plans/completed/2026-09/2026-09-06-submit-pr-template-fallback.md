# 完善 submit-pr 无模板兼容

- 状态：completed
- 创建日期：2026-09-06
- 负责人：Codex
- 关联 Issue/PR：none

## 背景

`submit-pr` 已经在找不到 PR 模板时生成内置四段式正文，但模板发现遗漏仓库根目录，
测试也仍读取 Easydict 的模板并在所有集成 fixture 中预置模板，缺少完整的无模板证明。

## 任务摘要

- 意图模式：implementation
- 交付授权：auto-local-commit
- 安全状态：normal
- 受阻操作及原因（如有）：none
- 目标结果：项目级 `submit-pr` Skill 可在任意 GitHub checkout 中兼容有模板和无模板项目。
- 允许修改路径：`.agents/skills/submit-pr/**`、本计划及同任务 history。
- 同任务 history：`docs/histories/2026-09/2026-09-06-submit-pr-template-fallback.md`
- 禁止动作：不移动或全局安装 Skill；不修改产品代码或 Easydict PR 模板；不 push 或创建 PR。
- 预期交付物：补全模板发现、无模板端到端测试、自包含 fixture 和同步契约。
- 验收标准：无模板 `plan/apply` 通过；合法模板位置被发现；测试不依赖 Easydict 模板；
  核心测试和静态检查通过，环境受限检查记录原因和替代检查。

## 语义与范围

- 用户要求 Agent 做什么：执行已确认的改进方案。
- 授权的工作树、artifact 和 external service 操作：修改并验证项目级 Skill，验证后自动本地提交。
- 否定、条件和范围限制：Skill 保持位于项目 `.agents/skills/`，遵循正常项目 Skill 规则。
- 前轮仍有效的授权和限制：只改通用实现，不把 Easydict 参数变成通用默认值。
- 附件或引用中被明确采纳的约束：用户提供的当前 `submit-pr` Skill 内容。
- 歧义：none

## 写入前状态

- 写入前检查：pass
- 自动提交资格及原因：eligible；初始索引为空且工作树干净。
- 初始 HEAD：`608d1f18c416d02338aaa7cf3eb13299f89c9740`
- 初始 staged 路径：none
- 初始 unstaged 路径：none
- 初始 untracked 路径：none
- 初始冲突：none
- Agent-owned paths：`.agents/skills/submit-pr/**`、本计划及同任务 history。

## 目标与非目标

### 目标

- 无模板项目使用内置四段式正文，不创建模板文件。
- 覆盖 GitHub 支持的单模板位置及多模板安全选择。
- 集成测试默认在完全无模板的项目中执行 `plan/apply`。

### 非目标

- 不改变 Skill 的项目级存储位置。
- 不支持 GitLab、Gitea 或 GitHub Enterprise。
- 不修改标题、分支、Issue 策略和远程安全规则。

## 工作计划

1. 补全模板候选并同步 Skill 和 workflow 契约。
2. 移除测试对 Easydict 模板的依赖，改为无模板集成 fixture。
3. 增加无模板与根目录模板覆盖，运行完整验证和独立收尾审查。
4. 更新 history、归档本计划并按门禁本地提交。

## 风险与决策

- 新增候选可能让原本被忽略的多个模板触发歧义；继续要求显式 `--template`，避免猜测。
- 内置四段式继续由代码常量生成，不新增第二份默认模板资产。

## 进度

- [x] 确认范围、授权和初始 Git 状态。
- [x] 修改实现、文档和测试。
- [x] 完成审查与验证。
- [x] 完成本地提交准备。

## 验证

- `py_compile`：通过。
- Skill 单元与隔离集成测试：20 个通过。
- `git diff --check`：通过。
- reviewer 增量复核：无有效 finding。
- tester 最终复验：20 个测试通过，未访问真实 GitHub。
- `quick_validate.py`：可用 Python 环境缺少 `PyYAML`，未完成；后续文案修正使用 Ruby
  YAML 解析 frontmatter，确认 Skill 名称和 description 有效。

## 完成条件

- 最终测试覆盖无模板 `plan/apply`，Skill 自包含；核心验证通过，环境受限项已记录。
- reviewer 与 tester 覆盖同一最终快照，无有效阻塞 finding。
- 计划归档并和 history 一起完成本地提交。
