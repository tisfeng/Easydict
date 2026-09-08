# 开发规则

本文统一规定跨语言代码质量、Swift/Xcode 实践和用户可见文本本地化。构建与测试见
[`build-and-test.md`](build-and-test.md)。

## 跨语言代码质量

以下规则适用于手写的 Swift、Objective-C、Python、Shell、JavaScript/TypeScript 和其他源码。

### 组织与命名

- 按功能和明确职责组织不断增长的区域；解析、UI、I/O、编排和验证混杂时提取同级文件或模块。
- 每个源码文件聚焦一个职责。手写文件通常控制在 500 行以内；没有具体拆分计划时不得超过
  1000 行。生成文件、第三方代码、纯数据、模板、大型 fixture 和有意 vendor 的运行时文件除外。
- 较长文件使用 section marker 组织生命周期、状态、命令处理、I/O、解析和恢复逻辑。
- 遵循语言常规命名约定；不参与导入的文档、导出产物、应用管理的运行时路径和独立脚本使用
  kebab-case，编译的 Swift、Objective-C 和测试文件使用 `UpperCamelCase`。
- 名称保持简洁，除简单循环索引外避免单字母变量。避免没有语义价值的一次性变量、全局可变
  状态和无领域意义的类型级 helper。
- 代码库已经采用 async/await 时优先沿用。

### 注释

- 为非简单脚本或模块添加文件级注释，说明入口、职责和重要副作用。
- 为复杂函数、状态机、解析器、I/O 边界和恢复逻辑添加文档，不注释明显 accessor 或薄 wrapper。
- 注释简洁并随行为更新；可行时每行不超过 80 个字符，使用对应语言的常规文档风格。
- 源码文件头使用当前 Git 用户名，不使用 Agent 名称。

## Swift 与 Xcode

### Swift 组织与实践

- 每个 Swift 文件聚焦一个主要 class 或 struct；紧密耦合的 protocol、简单模型、私有 helper
  或直接支持主类型的 extension 可以同文件维护。
- 将同一 protocol 的函数放在一起，并使用 `// MARK: - <ProtocolName>` 标记；较长类型使用
  `// MARK:` 区分生命周期、状态、协议和私有 helper。
- 除非确实需要类型级语义，否则避免 `static` 函数和变量；utility type 除外。
- 优先使用 `for ... where`，而不是循环后的行内过滤。
- 每个 class、struct、enum、protocol 和 actor 前添加类型级文档。核心类型保持 2–4 个简洁
  句子、约 220–320 个英文字符；简单私有 helper 控制在 180 个字符以内。
- 为不明显的函数和推理添加英文文档注释。
- 每个测试源码文件最多声明一个 `@Suite` 类型。

### 工程元数据

新增或移动由 Xcode 管理的源码文件或运行时资源时，更新
`Easydict.xcodeproj/project.pbxproj`，使文件出现在 Xcode navigator 中。仓库治理 Markdown、
计划、history、skill、参考资料和 `docs/` 下的公共 Markdown 不需要工程引用；除非文档作为
运行时资源发布，否则不加入 build phase。

### 库与 API

- 使用 SFSafeSymbols，不硬编码 SF Symbol 字符串；优先使用 `Image(systemSymbol:)` 和
  `Label(systemSymbol:)`。
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
- key 使用小写、点号分隔，并按 `<scope>.<category>.<subcategory>.<element>` 使用 snake_case
  片段。
- 公共贡献说明位于 `docs/user-docs/en/How-to-translate-Easydict.md` 及其中文对应文档。
