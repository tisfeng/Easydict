# 精简 OpenAI 测试与验证原则

- 授权：执行已确认方案；仅修改验证原则、删除四个指定 OpenAI 测试及工程引用。
- 初始 HEAD：`c02ed9302d861308a9d23bccb3ddb6fa08c19aaf`；staged、unstaged、untracked 与冲突均为空。
- 归属范围：`docs/agents/build-and-test.md`、`Easydict.xcodeproj/project.pbxproj`、四个删除的测试文件，以及本计划和同任务 history。
- 保留：`OpenAIStreamTaskControlTests.swift`、全部生产代码及其他模块测试。
- 步骤：更新规则、删除测试与引用、运行静态检查及取消协调定向测试、记录结果并本地交付。
- 风险：删除四组测试后不再提供其覆盖；此范围由用户明确指定。
- 完成条件：仅保留指定测试，工程引用一致，文档链接有效，定向测试通过；阻塞如实记录。

- 结果：规则与删除完成，静态检查通过，取消协调 3 个定向测试通过。
