# 恢复 Star History 官方图表

- 状态：completed
- 创建日期：2026-11-11
- 负责人：Codex
- 关联 Issue/PR：https://github.com/star-history/star-history/issues/542

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

## 背景

Star History 已切换到 GitHub 的新星标统计接口，官方嵌入图恢复。Easydict 自建流程需要生成图表、部署 Pages，并为每周的数据更新创建 PR。

## 目标与范围

- 目标结果：中英文 README 使用官方嵌入图，移除 Easydict 自建图表流程。
- 允许修改路径：`README.md`、`README_ZH.md`、`.github/workflows/update-star-history.yml`、`scripts/star-history/`、`docs/assets/star-history/`、本计划和 history。
- 同任务 history：`docs/histories/2026-11/2026-11-11-restore-star-history.md`
- 用户限制：按已确认方案执行并交付本地提交。
- 非目标：修改远端 GitHub Pages、分支保护或已发布内容。
- 验收标准：两份 README 在浅色和深色主题下显示对应的官方图表，图表链接指向 Easydict 的官方图表页，活跃文件不再引用自建流程或产物。

## 工作计划

1. 替换两份 README 的图表和目标链接。
2. 移除工作流、脚本及生成产物。
3. 验证主题和链接，审查差异并提交。

## 风险与决策

- 图表可用性由 Star History 提供。
- 保留已部署的 Pages 站点设置，旧地址的退役单独处理。

## 进度

- [x] 切换图表并清理自建流程。
- [x] 完成验证与审查。

## 验证

- GitHub Markdown API 按 GFM 渲染两份 README 的图表区块，保留可点击的 `picture` 和深浅色资源。GitHub 图片代理的两个地址均返回 Easydict SVG 曲线。
- Chrome 预览两份 README 的图表区块，四种语言和主题组合均加载了对应 SVG。点击图表后，官方页面显示 Easydict 曲线。
- `git diff --check` 通过。核对旧路径的剩余引用只出现在历史文档，其他工作流未使用被删产物。
- 本地审查核对图表入口、主题资源和工作流删除范围，无有效 finding。

## 完成条件

- 图表、链接和工作流清理通过验证，记录结果并归档本计划。
