# MDictReader

`MDictReader` 目录承载 MDX/MDD 二进制格式读取层。它把文件 header、key block、
record block、压缩块和加密 key index 等细节隔离在 reader 内部，向上只暴露按 key 查询文本
或二进制资源的能力。

![MDictReader 架构](./mdict-reader-architecture.svg)

## 目录结构

```
MDictReader/
├── MDictReader.swift                  # reader 状态、初始化、lookup API 和共享模型
├── MDictHeaderParser.swift            # header XML 和编码属性解析
├── MDictKeyBlocks.swift               # key block metadata、边界 key 和 key entry 解析
├── MDictKeyIndex.swift                # key 到 entry index 的内存索引
├── MDictRecords.swift                 # record block metadata、范围、缓存和内容读取
├── MDictBinary.swift                  # big-endian 读取、范围校验、zlib 解压和 key info 解密
├── MDictRIPEMD128.swift               # Encrypted=2 key index 解密用 RIPEMD-128
├── mdict-reader-overview.md           # 本目录说明
└── mdict-reader-architecture.svg
```

## 职责边界

- `MDictReader` 是 MDX/MDD 文件读取入口，初始化时解析 header、key block 和 record block
  metadata，并建立 key index。
- `MDictHeaderParser` 只负责从 header XML 中提取版本、标题、编码、格式、大小写敏感和加密
  标记。
- `MDictKeyBlocks` 负责解析 key block info 和 key entries，必要时解密 Encrypted=2 的 key
  block info。
- `MDictRecords` 负责根据 record offset 定位 record block，按需解压并缓存 record block。
- `MDictBinary` 和 `MDictRIPEMD128` 是底层工具，不处理词典导入、资源链接重写、UI 或 HTML
  渲染。

## 主要流程

初始化时，`MDictReader` 读取文件数据并解析 header。随后 reader 解析 key blocks 得到
`MDictKeyEntry` 列表，读取 record block metadata 生成 `RecordBlockRange`，最后按大小写规则
建立 key index。

查询文本时，`lookup` 或 `lookupAll` 先通过 key index 找到 entry，再根据相邻 entry 计算
record span。reader 会定位包含该 offset 的 record block，按需解压并读取 record bytes，最后
按 header encoding 解码为字符串。查询 MDD 资源时，`lookupData` 走同一套 key 和 record 读取
流程，但直接返回原始 `Data`。

## 调试入口

- header 或编码异常时，从 `MDictHeaderParser.parseHeader` 和 `readAttribute` 开始排查。
- 查词无结果时，检查 `MDictKeyIndex.buildKeyIndex`、大小写敏感配置和 key entry 解析。
- record 内容错位时，检查 `MDictRecords.recordSpan`、`RecordBlockRange` 和 block 边界。
- 解压失败或文件越界时，优先看 `MDictBinary.decompressBlock`、`ensureAvailable` 和大小限制。
- Encrypted=2 文件异常时，检查 `decryptKeyBlockInfo` 与 `MDictRIPEMD128` 的 key 派生逻辑。
