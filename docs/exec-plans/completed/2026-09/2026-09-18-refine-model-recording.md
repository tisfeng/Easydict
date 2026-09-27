# 优化模型记录规则

- 状态：completed
- 创建日期：2026-09-18
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-5`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

## 背景

现有模板只接受完整模型 ID，导致客户端明确提供模型别名或基础模型时仍需填写 `Unknown`。
用户要求保留完整 ID 的最高优先级，同时允许使用明确提供的模型别名和基础模型。

## 目标与范围

- 目标结果：将模型字段改为 `Model`，按完整模型 ID、模型别名、基础模型、`Unknown` 的顺序记录。
- 允许修改路径：Plan 与 History 模板、本计划及同任务 history。
- 同任务 history：`docs/histories/2026-09/2026-09-18-refine-model-recording.md`
- 用户限制：同步规则到四个关联项目，不 push。
- 非目标：不修改产品代码，不批量改写既有 completed plan/history。
- 验收标准：模板字段和取值说明准确，`Auto` 等选择模式不作为模型值，静态检查通过。

## 工作计划

1. 更新 Easydict 的 Plan 与 History 模板。
2. 将相同语义适配到 Scoco、boss-resume、EasyKOL Scout 和 skills。
3. 检查字段顺序、回退顺序、旧规则残留和 Markdown diff。
4. 更新各项目 history，归档计划并创建本地提交。

## 风险与决策

- 字段改为 `Model`，避免别名和基础模型被错误标记为模型 ID。
- 只接受运行上下文或响应元数据明确提供的值，不根据客户端或历史记录推测。
- `Auto` 是选择模式而非模型身份；只有 `Auto` 时填写 `Unknown`。

## 进度

- [x] 确认目标语义和项目范围。
- [x] 更新 Easydict 模板。
- [x] 完成关联项目同步和验证；本地提交在计划归档后创建。

## 验证

- 模板检查：Plan 与 History 均使用 `Model`，占位符覆盖完整 ID、别名、基础模型和 `Unknown`。
- 优先级检查：完整模型 ID、模型别名、基础模型、`Unknown` 的顺序明确，`Auto` 不作为模型值。
- 关联项目检查：Scoco、boss-resume、EasyKOL Scout 和 skills 的当前模板语义一致。
- 相对链接和 `git diff --check`：通过。
- `xcodebuild`：未运行；本任务只修改仓库治理 Markdown。

## 完成条件

- [x] 五个项目的当前模板使用相同模型记录语义。
- [x] 各项目风险匹配的静态检查通过。
- [x] history 已记录结果，计划可以归档并创建本地提交。
