# Codex 组件

`prepare-runtime.py` 由 Xcode 构建阶段执行，只复制固定下载清单与两份模型目录，
不联网获取二进制。首次使用时，设置页由用户发起官方完整包下载：macOS 13/14 使用
0.134.0，macOS 15+ 使用 0.153.4，按实际芯片选择一份包。

安装器核对压缩包大小、SHA-256、归档路径与类型、每个文件的 SHA-256，以及清单中的
官方签名要求，再将临时目录提升到应用专用组件目录。取消与失败清理临时目录；损坏
缓存可重新下载替换。每次运行前重新校验。保留官方原始字节与签名，不修改全局 CLI。
正式 Developer ID 签名、公证和 macOS 13/14、Intel 实机仍需独立验收。

## 翻译能力配置

`<版本>/translation-models.json` 是 Easydict 的静态翻译能力配置，不是未经修改的官方目录。
旧版来源为官方 `rust-v0.134.0`、commit `a75c443fdb64db48c3cf4bdb247c7ee52c0144c9` 的
`codex-rs/models-manager/models.json`；原文件 SHA-256 为
`b21200fd39c430f750cf10030c13bb19a91fdbc07792abdbda09e0ce6479161a`。

新版对应官方 `rust-v0.153.4` 目录，额外固定 `tool_mode=direct` 与 `multi_agent_version=null`。
模型集合按当前 ChatGPT 接入方式与组件兼容性筛选：旧版只保留 gpt-5.5；新版保留
Astra、Sol、Terra、Luna 与 gpt-5.5。组件历史目录中的存在不等于账户当前可调用。
默认模型按 release 固定为旧版 gpt-5.5、新版 gpt-5.6-luna，并在对应目录中验证。
保留模型的其余元数据与指令，改变以下三项：

- `input_modalities=["text"]`：在 handler 读取图片之前拒绝 `view_image`。
- `apply_patch_tool_type=null`：不注册补丁工具。
- `experimental_supported_tools=[]`：不增加实验工具。

运行时使用官方 `model_catalog_json` 静态加载器，不刷新远程模型目录；Easydict
先精确匹配 slug，拒绝 CLI 的未知模型与前缀 fallback。本机 CLI 不使用此目录。
不得仅靠 filesystem profile 或 `exec --json` 结果过滤隔离工具：真实反例已证明该版本
进程内图片读取不受前者限制，且被拒工具调用也可能没有 JSONL item。
旧版仍存在不访问外部资源的 plan/request-input handler；新版通过对应的 tools 配置关闭。
认证共用稳定 CODEX_HOME 与官方 Keychain，SQLite 和日志按组件版本分开。

## 无账户隔离探针

`verify-isolation.py` 启动本机回环 Responses fixture，强制返回工具调用。它只使用
自建 PNG 和临时文件，不调用真实模型或读取个人凭据。输入 JSON 由当前
`CodexManagedRuntime.translationArguments` 输出，含 `executable`、`arguments`、`cwd`。
运行：

```sh
python3 scripts/codex-runtime/verify-isolation.py <arguments.json>
```

探针覆盖绝对图片路径、符号链接、补丁、命令调用和重复运行的 skill 字面量，检查后续
请求没有测试图片、相对于普通输入的 skill 上下文注入和写入副作用。受控 fixture 的 provider 覆盖只用于
此验证脚本，不是产品运行时入口。探针通过不替代真实 ChatGPT 认证或发布验收。
