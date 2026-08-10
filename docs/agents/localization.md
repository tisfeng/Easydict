# 本地化

- 所有用户可见的 UI 文本都必须本地化。不要在 SwiftUI、AppKit、脚本或打包的 web
  资源中硬编码可见字符串。
- `Localizable.xcstrings` 是应用的主 String Catalog。新增 key 或改变其含义时，
  检查目录中的 locale，并更新所有受影响的 locale。
- 在 UI 和字符串 API 中优先直接使用静态 String Catalog key。
- 不要动态构建本地化 key，也不要拼接本地化片段。应将完整句子本地化，并传入
  运行时参数。
- 使用小写、点号分隔的 key，并按 `<scope>.<category>.<subcategory>.<element>`
  形式使用 snake_case 片段。
- 面向公共本地化贡献者的说明位于
  `docs/user-docs/en/How-to-translate-Easydict.md` 及其中文对应文档。
