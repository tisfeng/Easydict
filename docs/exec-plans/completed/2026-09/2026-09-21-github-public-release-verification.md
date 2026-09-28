# 强化 GitHub 公开 Release 验收

- 状态：completed
- 创建日期：2026-09-21
- 负责人：Unknown
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-5
- **Environment:** macOS 27.0 / Xcode 27.0 (27A266a)

## 背景

Scoco 提交 `081caf8c4965ae5112bacf6f68a1be3d61aa23f2` 将 R2 发布从单一 HEAD 成功检查提升为公开资源契约验收。Easydict 使用 GitHub Release 和 `raw.githubusercontent.com`，当前只检查 GitHub API 资产大小、公开下载 URL 可响应，以及公开 appcast 能否通过本地语义校验，仍未证明匿名公开下载端点的实际长度、Range 行为、checksum 内容和目标 appcast 条目与冻结候选一致。

## 目标与范围

- 目标结果：在 appcast 推送前验证公开 GitHub Release 资产，在 appcast 推送后完整核验公开 appcast。
- 允许修改路径：`.agents/skills/release-easydict/scripts/`、`.agents/skills/release-easydict/tests/`、`.agents/skills/release-easydict/SKILL.md`、`docs/releases/easydict.md`、本计划和对应 history。
- 同任务 history：`docs/histories/2026-09/2026-09-21-github-public-release-verification.md`
- 用户限制：保留现有 GitHub 下载 URL、Sparkle 配置、发布顺序的语义和本地恢复边界；不修改应用客户端、签名密钥或远程资源。
- 非目标：不接入 Cloudflare/R2、Cache Purge 或新的下载 URL 查询参数；不改变 Git 引用 lease 和 Issue 跟进流程。
- 验收标准：公开 ZIP、DMG 和 checksum 资产的匿名端点返回正确状态、长度和类型；ZIP/DMG Range 返回正确的 `206`、单字节长度和完整 `Content-Range`；checksum 内容与本地一致；公开 appcast 的目标条目与冻结候选完整一致；任一公开资产失败都不得推进 appcast 引用。

## 工作计划

1. 新增可单元测试的公开 HTTP/appcast/资产契约校验 helper。
2. 接入 `release-verify.sh`，在发布工作流中把公开资产验收放到 appcast 引用推进之前。
3. 扩展公开 appcast 和 checksum 校验，补充状态、长度、类型和字段漂移失败路径。
4. 更新 Release Skill、公开发布文档、测试并运行静态检查。
5. 使用 review 技能审查任务 diff，修复有效 finding，归档计划并写入 history。

## 风险与决策

- GitHub Release 下载 URL 会先返回 302，再重定向到时效性资产 URL；校验必须跟随重定向并只解析最终 HTTP 响应头。
- GitHub API 的资产 `contentType` 与公开下载最终响应类型可能不同；API 用于上传元数据和 digest，公开端点分别按实际稳定响应契约校验。
- 公开验证只证明当前网络出口命中的 GitHub/CDN 边缘节点，不宣称全球节点同时一致。
- 公开资产校验放在 appcast 推送前；如果公开 Release 已发布但资产不合格，保留旧 appcast 和可恢复状态，不执行后续 Git 清理或 Issue 动作。

## 进度

- [x] 新增公开契约 helper。
- [x] 接入发布 workflow。
- [x] 扩展测试和文档。
- [x] 验证、review、history 和计划归档。

## 验证

- `python3 .agents/skills/release-easydict/tests/test_release_public.py`：8 tests passed。
- 临时 Python 3.14 环境安装固定 `Markdown==3.8.1` 后运行完整 Release Skill 测试：
  80 tests passed。
- `bash -n .agents/skills/release-easydict/scripts/*.sh`：通过。
- `python3 -m py_compile .agents/skills/release-easydict/scripts/*.py`：通过。
- `python3 -m json.tool .agents/skills/release-easydict/scripts/asc-workflow.json`：通过。
- `quick_validate.py .agents/skills/release-easydict`：通过，Skill 结构有效。
- 相对 Markdown 链接检查和 `git diff --check`：通过。
- 只读实测 Easydict 2.23.0：GitHub API 为三个目标资产返回 `uploaded` 状态、大小、
  Content-Type 和 SHA-256 digest；匿名下载最终响应为 `application/octet-stream`，ZIP/DMG
  支持单字节 Range；公开 appcast 为 `text/plain; charset=utf-8`。
- `review`：基于初始 `HEAD` `dc7d6694c09dca3b79c4fc514805ad639957b3d2` 审查任务
  变更，无未处理 findings。审查中修正 checksum API Content-Type、内容下载重试和完整 item
  比较边界后完成复验。
- 未运行 Xcode build/test、Archive、公证或真实发布；本次只修改发布 Skill、脚本、配置和文档，
  并仅对现有公开 Release 做只读网络核验。

## 完成条件

- 公开资产和公开 appcast 的成功及失败路径测试通过。
- Release Skill 静态校验、Python 测试、Shell 语法和 `git diff --check` 通过。
- review 无未处理的有效 finding。
- history 已记录实际变更，计划归档至 `docs/exec-plans/completed/2026-09/`。
