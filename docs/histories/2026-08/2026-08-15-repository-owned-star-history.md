## 2026-08-15 | 任务：将 Star History 改为仓库自有产物

**Links:** `docs/exec-plans/completed/2026-08-15-repository-owned-star-history.md`

### 用户请求

保留历史 `stargazers_count` 曲线和 Date/Timeline 使用方式，同时移除对新且
不稳定的第三方 Star History 域名依赖，并避免管理个人 GitHub PAT。

### 变更

- 初次生成时用 GitHub Actions 内置 `GITHUB_TOKEN` 读取带 `starred_at` 的 stargazers
  历史；后续每周只读取仓库 API 返回的 `stargazers_count`。
- 将历史聚合为只含 UTC 日期和累计数量的 JSON；后续快照取历史末点与当前 star 数的较大
  值，因此取消 star 不会让既有曲线下降或被重算。
- 在仓库内生成浅色/深色 SVG；README 中英文改用本地 SVG。
- SVG 采用手写字体回退、`xkcdify` 抖动滤镜、手绘坐标轴和无网格布局，贴近旧版
  Star History 样式。
- 标题前内嵌当前仓库所有者头像，移除右下角重复的仓库名；头像随 SVG 一起发布，
  不依赖外部头像 URL。
- 增加不依赖运行时 token 的静态 Date/Timeline viewer，并通过 GitHub Pages 部署。
- 增加 API 有限重试、聚合/渲染测试和执行计划记录。
- 将更新频率改为每周一次，并改用专用更新分支创建 PR；CI 通过后由 GitHub Actions
  自动合并，不需要个人 PAT 或人工批准每周更新。
- Date 模式按真实日期间隔绘制，Timeline 模式按数据点顺序等距绘制；允许连续周没有
  新增 star，历史点数量持平但不会下降。

### 验证

- 初次回填完整读取 143 页、14,220 条 stargazers；后续更新路径不再分页读取完整列表，
  而是使用当前 `stargazers_count` 追加每周快照。
- Python 单元测试、编译、JSON、SVG XML、`git diff --check` 和 Agent 文档结构
  检查通过；重新生成的 SVG 已完成本地视觉检查。
- workflow YAML 解析通过。

### 后续事项

- 需要在仓库分支保护中关闭 `Require approvals` 和 `Require review from Code Owners`，
  保留 PR、CI、分支最新和对话解决要求；并在仓库设置中允许 auto-merge。
