## 2026-11-11 | 任务：恢复 Star History 官方图表

**Links:** [执行计划](../../exec-plans/completed/2026-11/2026-11-11-restore-star-history.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

### 用户请求

将 README 切回 Star History 官方图表，移除需要维护脚本和审批更新 PR 的自建流程。

### 变更

- 中英文 README 嵌入官方深浅色 SVG，点击图表进入 Easydict 的官方 Date 图表。
- 删除自建更新工作流、Python 脚本及测试、历史数据和生成的 SVG。

### 设计意图

由 Star History 提供图表和数据更新。合入默认分支后，Easydict 不再通过定时工作流生成图表更新 PR。

### 验证

- GitHub GFM 渲染保留可点击的图表结构和主题选择，两张代理 SVG 均加载成功。
- Chrome 预览覆盖两份 README 的深浅主题。点击图表后，官方页面显示 Easydict 曲线。
- `git diff --check` 和旧引用检查通过。本地审查无有效 finding。

### 受影响文件

- `README.md`、`README_ZH.md`
- `.github/workflows/update-star-history.yml`
- `scripts/star-history/`、`docs/assets/star-history/`

### 后续事项

- 如需停用旧 GitHub Pages 站点，单独处理其远端设置及已分享的旧链接。
