# 提取查询统计存储

- 状态：completed
- 创建日期：2026-11-18
- 负责人：Codex
- 关联 Issue/PR：无

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

## 背景

`LocalStorage` 的类型体有 511 行有效代码，超出 SwiftLint 的 500 行警告阈值。查询统计与窗口服务配置共用该类型。

## 目标与范围

- 目标结果：将查询统计抽到同目录的 `QueryUsageStore`。
- 允许修改路径：`Easydict/Swift/Service/Model/Storage/` 下的两个存储文件、Xcode 工程和本任务记录。
- 同任务 history：`docs/histories/2026-11/2026-11-18-extract-query-usage-store.md`
- 用户限制：保留调用接口与旧数据兼容性。
- 非目标：服务配置、Codex 迁移规则及 lint 阈值调整。
- 验收标准：Debug 构建和现有 Codex 迁移测试通过，目标 SwiftLint 警告消失。

## 工作计划

1. 提取查询统计并将新文件加入 Xcode target。
2. 运行构建、SwiftLint 和迁移测试。
3. 对照原实现审查兼容性，记录结果并提交。

## 风险与决策

- 保留 UserDefaults 键、按服务存储的字典和 Objective-C selector。Codex 启动迁移仍需读取历史查询记录。

## 进度

- [x] 复现 SwiftLint 报告的 511 行警告。
- [x] 完成提取、构建、定向迁移测试和兼容性审查。

## 验证

- SwiftLint 0.65.1 在基线重现 `type_body_length` 警告。拆分后构建中的全量 lint 检查 445 个文件，0 条违规。
- macOS arm64 Debug 构建通过。
- `CodexConfigMigrationTests` 9 项通过，0 失败、0 跳过。
- 核对移动前后的统计逻辑、存储格式、启动顺序与生成的 Objective-C 接口。

## 完成条件

- 所有验收标准通过，完成兼容性审查并记录 history。
