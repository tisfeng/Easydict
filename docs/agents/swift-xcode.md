# Swift 与 Xcode 规则

## 源码组织

- 每个 Swift 文件聚焦于一个主要 class 或 struct。
- 紧密耦合的 protocol、简单数据模型、私有 helper 或直接支持主类型的 extension 可以
  放在同一个文件中。
- 将同一 protocol 的函数放在一起，并使用 `// MARK: - <ProtocolName>` 标记协议块。
- 在较长类型中使用 `// MARK:` 区分生命周期、状态、协议和私有 helper 组。
- 编译的 Swift、Objective-C 和测试文件名使用 `UpperCamelCase`。

## Swift 实践

- 除非确实需要类型级语义，否则避免使用 `static` 函数和变量；utility type 是例外。
- 优先使用 `for ... where`，而不是循环后再进行行内过滤。
- 在每个 class、struct、enum、protocol 和 actor 前添加类型级文档注释。核心类型注释
  保持为 2–4 个简洁句子、约 220–320 个英文字符；简单私有 helper 的注释控制在
  180 个字符以内。
- 为不明显的函数和推理添加英文文档注释。

## Xcode 工程元数据

新增或移动由 Xcode 管理的源码文件或运行时资源时，更新所属的
`Easydict.xcodeproj/project.pbxproj`，使文件出现在 Xcode navigator 中。仓库治理
文档、计划、历史、skill、参考资料以及 `docs/` 下的公共 Markdown 不需要工程引用。
除非文档会作为运行时资源发布，否则不要将其加入 build phase。

## 库与 API

- 使用 SFSafeSymbols，不要硬编码 SF Symbol 字符串。
- 优先使用 `Image(systemSymbol:)` 和 `Label(systemSymbol:)` 类型安全 API。
- 在 SwiftUI 中使用 `foregroundStyle`，不要使用已弃用的 `foregroundColor`。
- SwiftUI background 优先使用 trailing-closure 或专用 shape-style 重载，不要使用已弃用
  的重载。
- 网络请求使用 Alamofire 的 async/await API。
- 用户偏好使用 Defaults，不要引入直接的 UserDefaults 使用。

## Swift 测试结构

- 每个测试源码文件最多声明一个 `@Suite` 类型。
