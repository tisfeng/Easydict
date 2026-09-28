# 编码规范

本文统一规定跨语言代码质量、Swift 实践、库与 API 以及用户可见文本本地化。构建与测试见
[`build-and-test.md`](build-and-test.md)。

## 跨语言代码质量

以下规则适用于手写的 Swift、Objective-C、Python、Shell、JavaScript/TypeScript 和其他源码。

### 组织与命名

- 按功能和明确职责组织代码；解析、UI、I/O、编排和验证混杂时，在当前任务范围内提取同级文件或模块。
- 每个源码文件聚焦一个职责；文件或类型超过项目 lint 阈值时评估拆分。现有大文件不自动纳入
  当前任务范围。
- 较长但职责单一的文件使用 section marker 组织生命周期、状态、命令处理、I/O、解析和恢复逻辑。
- 编译的 Swift、Objective-C 和测试文件使用 `UpperCamelCase`；其他文件遵循对应工具和所在目录
  的既有约定。
- 名称应表达意图；除简单循环索引外避免无语义的单字母变量和缩写，避免不必要的全局可变状态。
- 代码库已经采用 async/await 时优先沿用。

### 注释

- 为公开 API，以及职责、约束、副作用或实现原因不明显的模块、类型和函数添加必要文档；不注释
  明显 accessor 或薄 wrapper。
- 注释说明代码本身无法表达的意图、约束或副作用，并随行为更新；格式遵循项目工具配置和相邻代码风格。
- 保留现有文件头；新文件遵循相邻文件模板，不使用 Agent 名称作为作者。

## 语言与迁移

- 新功能优先使用 Swift/SwiftUI；现有 AppKit 或 Objective-C 集成需要时沿用对应边界。
- 现有 Objective-C 允许必要的 bug 修复，不要求为局部修复先迁移。迁移只在任务范围内进行。
- Swift 迁移进度见 [`swift-migration.md`](../exec-plans/active/swift-migration.md)。

## Swift 组织与实践

- 每个 Swift 文件聚焦一个主要 class 或 struct；紧密耦合的 protocol、简单模型、私有 helper
  或直接支持主类型的 extension 可以同文件维护。
- 将同一 protocol 的函数放在一起，并使用 `// MARK: - <ProtocolName>` 标记；较长类型使用
  `// MARK:` 区分生命周期、状态、协议和私有 helper。
- Swift 文档注释使用简洁英文。

## 库与 API

- SF Symbols 使用 SFSafeSymbols 的类型安全 API，不硬编码名称。
- SwiftUI 使用 `foregroundStyle`，不使用已弃用的 `foregroundColor`。
- SwiftUI background 优先使用 trailing-closure 或专用 shape-style 重载。
- 网络请求使用 Alamofire 的 async/await API。
- 用户偏好使用 Defaults，不引入直接的 UserDefaults 使用。

## 本地化

- 所有用户可见 UI 文本必须本地化，不在 SwiftUI、AppKit、脚本或打包 web 资源中硬编码。
- `Localizable.xcstrings` 是应用主 String Catalog。新增 key 或改变含义时检查现有 locale，
  并更新所有受影响的 locale。
- 在 UI 和字符串 API 中优先直接使用静态 String Catalog key。
- 不动态构建本地化 key，也不拼接本地化片段；本地化完整句子并传入运行时参数。
- key 使用小写、点号分隔，并按 `<scope>.<category>.<subcategory>.<element>` 使用 snake_case 片段。
- 公共贡献说明位于 `docs/user-docs/en/How-to-translate-Easydict.md` 及其中文对应文档。
