# Copilot 动态模型与推理设置

- 状态：completed
- 创建日期：2026-09-27
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

## 背景

Copilot 设置仅提供模型文本框和固定推理等级，模型不支持某个等级时请求失败。
错误解析又将普通配置事件当作错误，掩盖真正的失败原因。

## 目标与范围

- 目标结果：从本机 CLI 查询模型及推理能力，提供可搜索模型选择、动态推理等级及加载/重试状态。
- 允许修改路径：Copilot 服务、Copilot 设置视图、String Catalog、Xcode 工程及本任务文档。
- 同任务 history：`docs/histories/2026-09/2026-09-27-copilot-model-catalog.md`
- 用户限制：功能未发布，不保留旧实现或引入旧配置迁移；不新增测试。
- 非目标：更换翻译传输、修改其他服务、push；保留已有三项图标配置 staged diff。
- 验收标准：删除模型提示及静态名单，动态目录含实际支持的推理等级，提交前校验参数，显示真正错误。

## 工作计划

1. 核实本机 CLI 模型 RPC 与隔离环境下的调用。
2. 实现目录查询、默认模型解析和请求参数校验。
3. 更新设置页与全部现有语言，修复错误事件解析。
4. 完成静态检查、构建、适用既有测试与真实 CLI 验证。
5. 使用 review 技能审查，记录结果并归档计划；按 Git 状态保护规则处理提交。

## 风险与决策

- 目录来自账号能力；查询失败保留选择和内存中最近成功的列表，不引入静态模型回退。
- 沿用独立工作目录及临时 CLI home，只读取模型相关偏好和账号元数据。
- 推理等级只使用 CLI 返回值；未知能力及 Auto 模型不传推理覆盖。
- 默认推理不额外查询目录；显式推理覆盖在翻译前重新查询，避免账号或 CLI 更新后沿用旧能力，代价是一次元数据查询。
- 当前使用 SDK 协议 3 的 `connect` 与 `models.list`；独立服务进程仅查询元数据，不创建会话。
- 首次写入前 HEAD 为 `f58e2cdc301b9f7c63c7f0fca75dea6e9e5b0d10`，暂存区已有三个 service-icon/Contents.json；本任务不修改其索引。

## 进度

- [x] 核对规则、现状与失败日志。
- [x] 实现与本地化。
- [x] 验证与审查。
- [x] history 与实现交付；初始索引非空，提交须明确限定范围后执行。

## 验证

- Debug `xcodebuild build` 使用 checkout 专属 Agent DerivedData 与 `EASYDICT_RELEASE_PACKAGING=YES`，最终成功。
- SwiftFormat、项目固定版本 SwiftLint、`git diff --check`、String Catalog JSON 和工程 plist 检查通过。
- 临时诊断入口直接编译生产 CatalogClient/Model/EventParser/Error 源码，连接 CLI 1.0.88 读取到 16 个模型；核实 Auto、Haiku 无推理调整，Sonnet 与 GPT 返回各自等级。
- 首轮生产代码诊断发现 Auto 的能力字段会省略，修正可选字段后重跑成功；查询取消返回 CancellationError。
- 两份原始失败日志分别正确解析出 minimal/none 不支持的错误，普通 session.info 不再遮盖 session.error。
- review 覆盖本任务源码、工程与本地化，复核快照及后续设置页生命周期小幅调整，无剩余 finding。未审查原有图标暂存改动。
- 当前没有 Copilot 专项既有测试；Xcode Run 正在运行同 bundle ID 的调试宿主，未运行 app-hosted test，也未验证新设置页的实际点击流程。未新增测试或更改用户调试进程。
- 初始三个图标配置 staged blob ID 保持不变；未 push。

## 完成条件

- 实现通过风险匹配的验证与审查，记录未覆盖项，保留用户原始暂存状态。
