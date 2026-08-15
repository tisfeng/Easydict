# 仓库自有 Star History

**状态：** 已完成
**创建日期：** 2026-08-15
**更新日期：** 2026-08-16
**负责人：** tisfeng
**链接：** `PR #1267`、`https://github.com/star-history/star-history/issues/542`

## 目标

移除 README 对 `star-history.dera.page` 的运行时依赖，改为由仓库自行维护历史
Star 曲线，同时保留 Date 图表、浅色和深色 SVG，以及交互式静态查看器；整个流程
不需要管理个人 GitHub token。

## 范围

- 获取 stargazer 历史时间戳，聚合每日累计数量，并在图表中内嵌仓库所有者头像。
- 生成确定性的浅色/深色手绘风格 SVG，以及自包含的 Date/Timeline 查看器。
- 使用仓库内置 token 每周和手动执行 GitHub Actions 更新。
- 更新中英文 README 引用，并完成针对性的验证。
- 不修改 Easydict 产品代码，不依赖第三方图表服务，也不保存 stargazer 身份信息。

## 实现

- `scripts/star-history/update_history.py` 使用 stargazer 专用媒体类型读取全部页面，
  对临时 API 错误进行重试，并校验最终累计数量是否等于 `stargazers_count`。
- `scripts/star-history/history.py` 保存图表数据，以及可选的自包含仓库头像。
- `scripts/star-history/render_chart.py` 生成 README 使用的 SVG，并将相同数据嵌入
  支持 Date/Timeline 哈希参数和浅色/深色系统主题的静态查看器。SVG 渲染器沿用
  原 Star History 的手绘风格，使用坐标轴和曲线抖动滤镜及手写字体回退；标题前显示
  仓库头像，并移除右下角重复的仓库名。
- `.github/workflows/update-star-history.yml` 每周或手动运行，将变更提交到专用更新
  分支，创建或更新 PR，并在 CI 通过后自动合并；同时通过 GitHub Pages 部署查看器。
- `docs/assets/star-history/` 保存初次回填的 14,220 个 star 数据。

## 验证

- 本地完整回填读取 143 页、14,220 条 stargazer 数据，最终数量与 GitHub 的
  `stargazers_count=14,220` 完全一致。
- `python3 scripts/star-history/test_history.py`：4 项测试通过。
- Python 编译、JSON 校验、SVG XML 解析、`git diff --check` 和
  `bash scripts/check-agent-docs.sh`：通过。
- 本地没有安装 `actionlint`；工作流 YAML 解析通过。
- 已将重新生成的浅色 SVG 栅格化并完成视觉检查，手绘图表、标题头像和已移除的右下角
  重复标签均符合预期。
- 工作流改为每周日运行，并完成本地 YAML 解析和差异检查。

## 后续工作

- 仓库 Pages 来源已设置为 GitHub Actions；远程分支保护仍需允许自动更新 PR 在 CI
  通过后合并。
