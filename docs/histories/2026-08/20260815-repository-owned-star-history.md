## 2026-08-15 | Task: 将 Star History 改为仓库自有产物

**Links:** `docs/exec-plans/completed/20260815-repository-owned-star-history.md`

### User request

保留历史 `stargazers_count` 曲线和 Date/Timeline 使用方式，同时移除对新且
不稳定的第三方 Star History 域名依赖，并避免管理个人 GitHub PAT。

### Changes

- 用 GitHub Actions 内置 `GITHUB_TOKEN` 读取带 `starred_at` 的 stargazers 历史。
- 将历史聚合为只含 UTC 日期和累计数量的 JSON，并校验末点等于当前仓库星标数。
- 在仓库内生成浅色/深色 SVG；README 中英文改用本地 SVG。
- SVG 采用手写字体回退、`xkcdify` 抖动滤镜、手绘坐标轴和无网格布局，贴近旧版
  Star History 样式。
- 标题前内嵌当前仓库所有者头像，移除右下角重复的仓库名；头像随 SVG 一起发布，
  不依赖外部头像 URL。
- 增加不依赖运行时 token 的静态 Date/Timeline viewer，并通过 GitHub Pages 部署。
- 增加 API 有限重试、聚合/渲染测试和执行计划记录。

### Validation

- 完整读取 143 页、14,220 条 stargazers，末点与 GitHub `stargazers_count=14,220`
  一致。
- Python 单元测试、编译、JSON、SVG XML、`git diff --check` 和 Agent 文档结构
  检查通过；重新生成的 SVG 已完成本地视觉检查。

### Follow-ups

- 合并并推送后，将仓库 Pages 来源设置为 GitHub Actions；此步骤未在本地修改
  远程仓库设置。
