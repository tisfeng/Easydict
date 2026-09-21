# 应用本地路径管理设计

- 状态：adopted
- 初次记录：2026-09-15
- 最近更新：2026-09-17

## 背景

Easydict 的应用日志、OCR 调试图片、音频缓存、MDict 元数据、服务调用日志和托管 Codex
运行时最初由各功能分别拼接路径。这种做法带来三个问题：

- 路径规则分散，调用方容易选择不同的系统目录或重复创建目录。
- 固定使用 `Easydict` 的路径无法按实际 bundle ID 隔离 Debug 与 Release 数据。
- 调整既有路径时缺少统一迁移策略，可能丢失日志、重复下载组件或覆盖已有数据。

## 设计目标

- 以 `AppPathManager` 作为 Easydict 自主管理文件的唯一目录来源。
- 使用实际 bundle ID 隔离 Debug 与 Release，避免开发数据污染正式版本。
- 路径查询保持无副作用，目录创建由写入方显式执行。
- 路径调整必须保留既有用户数据，并且不静默覆盖同名差异文件。
- 日志目录入口只展示常规应用日志，完整调试导出包含所有受管日志。

## 目录布局

Easydict 自主管理的持久文件统一位于：

```text
~/Library/Application Support/<bundle-id>/
├── codex/
│   ├── components/          # 固定版本的托管 Codex 运行组件
│   └── state/               # 隔离的 CODEX_HOME 与运行状态
├── logs/
│   ├── app/
│   │   ├── Default/         # CocoaLumberjack 应用日志
│   │   ├── Crash/           # 应用捕获的崩溃日志
│   │   └── Image/           # OCR 调试图片
│   ├── codex-cli/           # Codex 调用日志
│   └── claude-code/         # Claude Code 调用日志
└── cache/
    ├── audio/               # 可重新获取的发音音频
    └── mdict-metadata/      # 可重新生成的 MDict 元数据
```

正式版本使用 `com.izual.Easydict`，Debug 版本使用 `com.izual.Easydict-debug`。第三方 SDK
自行管理的目录不属于 `AppPathManager` 的所有权范围。

`~/Library/Caches/<bundle-id>/` 目前只作为旧版应用日志和音频缓存的迁移来源，不再作为上述
Easydict 自主管理文件的新写入位置。系统临时目录只用于生命周期短、使用后即可删除的中转文件。

## 路径所有权与 API 边界

`AppPathManager.current` 从 `Bundle.main.bundleIdentifier` 和系统提供的用户目录构建路径。
主类型保存不可变的路径上下文，并提供显式目录创建能力；分类扩展按 Codex、日志和缓存业务域
组织当前与历史路径。

读取路径不会创建目录。写入方必须在写入前调用 `ensureDirectoryExists(at:attributes:)`，从而让
创建时机、权限和错误处理保持可见。`@objcMembers` 允许现有 Objective-C 日志和音频边界复用
同一套路径，不再各自拼接字符串。

## 通用启动迁移

`AppPathMigration.prepareForLaunch()` 在参数解析、日志初始化和应用 UI 启动之前运行，
负责以下迁移：

| 数据 | 旧位置 | 新位置 |
| --- | --- | --- |
| 应用日志 | `~/Library/Caches/<bundle-id>/MMLogs` | `logs/app` |
| 音频缓存 | `~/Library/Caches/<bundle-id>/audio` | `cache/audio` |
| MDict 元数据 | `mdict-metadata-cache` | `cache/mdict-metadata` |

迁移遵循以下规则：

- 目标不存在时优先使用文件系统移动，避免复制大目录。
- 来源和目标都存在时递归合并；内容相同的文件只保留目标副本。
- 同名但内容或类型不同的项目保留为带 `-legacy-<UUID>` 后缀的副本，不覆盖目标。
- 拒绝迁移包含符号链接的目录树，并拒绝通过符号链接祖先写入目标路径。
- 只有来源目录完全清空后才删除它；中断或失败会保留尚未迁移的数据供下次启动重试。
- `cache` 根目录标记为不参与备份，其可重新获取或生成的子目录继承该策略。

协调器在单次进程中只执行一次。失败会写入系统日志，不阻止应用启动；下一次应用启动会重新检查
仍然存在的旧路径。

## 托管 Codex 迁移边界

托管 Codex 目录包含可执行组件、登录状态和隔离配置，因此使用独立的
`CodexDirectoryMigration`，不参与通用目录合并。它在首次解析应用级 Codex component store 时运行：

- 新位置固定为当前 bundle ID 下的 `codex`。
- 依次识别 bundle 级 `codex-managed` 和旧共享 `Easydict/codex-managed`。
- 目标已存在时由目标优先，旧目录不合并、不覆盖，只记录警告。
- 迁移前后都要求目录不是符号链接，并且 group 与 other 没有访问权限。
- 迁移使用原子移动；并发进程已经完成相同移动时接受现有目标。

这条边界优先保护托管运行时的配置隔离和权限，不尝试自动合并两个可能具有不同身份或状态的
Codex home。

## 日志查看与导出

菜单栏的“日志目录”使用 `logs/app`，只打开常规应用日志、崩溃日志和 OCR 调试文件。“导出日志”
使用 `logs`，将 `app`、`codex-cli` 和 `claude-code` 一并打包，以便提供完整调试材料。

服务调用日志会记录 command、prompt、stdout 和 stderr，可能包含用户输入、翻译原文或模型响应。
用户导出并分享完整日志包前需要将其视为可能包含敏感内容的调试材料。

## 取舍

- 将可重新生成的缓存放入 Application Support 不是 macOS 的典型默认布局，但能让应用自主管理
  文件集中在 bundle 根目录下；通过 `isExcludedFromBackup` 避免把这些缓存当作用户数据备份。
- 通用迁移选择保留冲突副本，会短期增加磁盘占用，但比静默覆盖或删除更容易恢复。
- Codex 迁移不合并目录，可能需要用户手动处理极少数双目录场景，但避免混合身份和外部配置。

## 新增路径的要求

新增 Easydict 自主管理的本地文件时：

1. 先判断它是持久应用数据、可重新生成缓存、日志还是临时中转文件。
2. 在最接近职责的 `AppPathManager` 扩展中声明路径，不在调用方重复拼接根目录。
3. 保持路径访问无副作用，在实际写入点显式创建目录并处理错误。
4. 改动既有位置时定义旧路径、迁移顺序、冲突策略和可重试行为。
5. 评估文件是否应备份、是否包含敏感信息，以及是否应进入普通日志导出。
6. 同步更新本文和对应 history；涉及多步骤或高风险执行时同时维护 plan。

## 重新评估条件

- 应用采用 App Sandbox、App Group 或其他容器模型。
- Debug 与 Release 的 bundle ID 或数据共享需求变化。
- 日志导出需要包含 AI 服务调用记录或提供脱敏能力。
- 多进程同时迁移成为常见场景，现有进程内锁和原子移动不足以保证一致性。
- 本地缓存规模需要独立的容量限制或淘汰策略。
