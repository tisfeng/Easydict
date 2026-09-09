# 精简 OpenAI 测试与验证原则

## 修改

- 将验证原则整理为添加测试、不添加测试和如何验证三组核心规则。
- 按用户明确指定，删除 BaseOpenAIServiceStreamHookTests、OpenAIReasoningEffortTests、OpenAIStreamResultTests、OpenAIStreamTransportTests 及其 16 条工程引用。
- OpenAI 测试仅保留 OpenAIStreamTaskControlTests，内容不变；生产代码和其他模块测试不变。
- 当前基线已清理 swift-xcode.md 失效链接，本次无需重复修改。

## 验证

- `git diff --check`、工程文件 `plutil -lint`、文档本地链接及保留测试原样检查通过。
- `xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict -only-testing:EasydictTests/OpenAIStreamTaskControlTests EASYDICT_RELEASE_PACKAGING=YES` 通过：1 个 suite、3 个测试。
- 首次运行受沙箱限制；提权运行期间为避免全仓库格式化主动停止，随后使用现有开关跳过 Format/Lint 后完成编译与定向测试。未运行全量测试。
- [执行计划](../../exec-plans/completed/2026-09-10-openai-test-cleanup.md)。
