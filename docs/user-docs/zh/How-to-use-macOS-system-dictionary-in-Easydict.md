# 在 Easydict 中使用 Apple Dictionary

Easydict 可以查询 macOS“词典”App 中已经启用的系统词典和 `.dictionary` 词典，让不支持
系统三指查询的应用也能使用这些词典。

## 启用系统词典

1. 打开 macOS“词典”App。
2. 打开“词典 → 设置”，勾选需要使用的词典并调整顺序。
3. 打开 Easydict“设置 → 服务”，添加或启用 Apple Dictionary。
4. 查询一个词语，确认 Apple Dictionary 结果正常显示。

词典内容和可用语言由 macOS 及“词典”App 决定，不同系统版本或地区可能有所不同。

## 添加 `.dictionary` 词典

如果你有合法获取的 Apple `.dictionary` 词典：

1. 在“词典”App 中选择“文件 → 打开词典文件夹”。
2. 将 `.dictionary` 文件放入打开的目录。
3. 重新打开“词典”App，在设置中启用该词典。
4. 重启 Easydict，让它重新读取词典列表。

请勿使用来源不明或没有授权的词典文件。Easydict 不提供第三方词典下载。

## 使用 MDX/MDD 词典

MDX/MDD 不属于 Apple `.dictionary` 格式。Easydict 已提供原生 MDict 服务，可以直接导入，
不需要转换。参阅[在 Easydict 中使用 MDict](./How-to-use-MDict-in-Easydict.md)。

## 常见问题

- **Easydict 中没有新词典**：先确认它已在“词典”App 设置中启用，再重启 Easydict。
- **查询结果为空**：确认目标词典包含该词条，并尝试把它移到“词典”App 列表前面。
- **只想使用部分词典**：在“词典”App 设置中停用不需要的词典。
