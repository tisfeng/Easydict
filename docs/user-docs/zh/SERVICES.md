# Easydict 服务总览

Easydict 可以同时查询词典、通用翻译、AI 模型和本地/命令行服务。服务可用性最终取决于
macOS 版本、网络环境、账号权限和上游接口状态。

## 使用条件

设置页用以下标记说明服务需要怎样的凭据：

- **无需密钥**：Easydict 不要求填写 API Key；部分服务仍需网络、系统组件或本地程序。
- **项目内置**：使用项目提供的内置访问方式，无需用户填写密钥。上游限制变化时可能暂时不可用。
- **用户密钥**：需要在服务设置中填写自己的 API Key、App ID 或 Secret。
- **CLI**：需要先安装并登录相应的命令行工具。

> [!NOTE]
> 新安装默认启用有道词典、DeepL 和内置 AI。你可以在“设置 → 服务”中添加、移除、启用、
> 停用和排序服务。`CustomOpenAI` 支持添加多个实例。

## 词典

| 服务 | 使用条件 | 说明 |
| --- | --- | --- |
| Apple Dictionary (`AppleDictionary`) | 无需密钥 | 查询 macOS“词典”App 中已启用的词典。 |
| MDict (`MDict`) | 无需密钥 | 直接查询用户导入的 MDX/MDD 词典。 |
| 有道词典 (`Youdao`) | 无需密钥 | 在线词典查询，也是默认 TTS 服务。 |

## AI 模型与本地/命令行服务

| 服务 | 使用条件 | 说明 |
| --- | --- | --- |
| OpenAI (`OpenAI`) | 用户密钥 | 使用 OpenAI 兼容配置中的官方 OpenAI 服务。 |
| DeepSeek (`DeepSeek`) | 用户密钥 | 使用 DeepSeek API。 |
| Groq (`Groq`) | 用户密钥 | 使用 Groq API。 |
| 智谱 AI (`Zhipu`) | 用户密钥 | 使用智谱开放平台 API。 |
| MiniMax (`MiniMax`) | 用户密钥 | 使用 MiniMax API。 |
| GitHub Models (`GitHub`) | 用户密钥 | 使用 GitHub Models。 |
| 内置 AI (`BuiltInAI`) | 项目内置 | 无需单独配置 API Key 的 AI 查询服务。 |
| Claude Code (`ClaudeCode`) | CLI | 调用已安装并登录的 Claude Code CLI。 |
| Codex CLI (`CodexCLI`) | CLI | 调用已安装并登录的 Codex CLI。 |
| Gemini (`Gemini`) | 用户密钥 | 使用 Gemini API。 |
| Claude (`Claude`) | 用户密钥 | 使用 Anthropic Claude API。 |
| Ollama (`Ollama`) | 无需密钥 | 调用本机或自定义地址上的 Ollama 服务。 |
| 自定义 OpenAI (`CustomOpenAI`) | 用户密钥 | 配置 OpenAI 兼容接口；支持多个实例。 |

## AI 工具

| 服务 | 使用条件 | 说明 |
| --- | --- | --- |
| 润色 (`Polishing`) | 项目内置 | 对输入文本进行 AI 润色。 |
| 总结 (`Summary`) | 项目内置 | 对输入文本进行 AI 总结。 |

## 通用翻译

| 服务 | 使用条件 | 说明 |
| --- | --- | --- |
| DeepL (`DeepL`) | 无需密钥 | 使用 Easydict 内置的 DeepL 查询方式。 |
| Google 翻译 (`Google`) | 无需密钥 | 使用 Google 翻译。 |
| 苹果翻译 (`Apple`) | 无需密钥 | macOS 15+ 可使用系统离线翻译；其他情况可回退到快捷指令。 |
| 百度翻译 (`Baidu`) | 用户密钥 | 需要百度翻译开放平台凭据。 |
| Bing 翻译 (`Bing`) | 无需密钥 | 使用 Bing 翻译。 |
| 火山翻译 (`Volcano`) | 用户密钥 | 需要火山翻译服务凭据。 |
| 小牛翻译 (`NiuTrans`) | 项目内置 | 使用项目内置访问方式。 |
| 彩云小译 (`Caiyun`) | 项目内置 | 使用项目内置访问方式。 |
| 腾讯翻译 (`Tencent`) | 用户密钥 | 需要腾讯翻译服务凭据。 |
| 阿里翻译 (`Alibaba`) | 用户密钥 | 需要阿里翻译服务凭据。 |
| 豆包翻译 (`Doubao`) | 用户密钥 | 需要豆包翻译服务凭据。 |

## 配置建议

1. 先保留少量常用服务，避免一次查询产生过多网络请求。
2. 需要隐私或离线能力时，优先考虑 Apple Dictionary、MDict、Apple 离线翻译或 Ollama。
3. 使用 AI 服务时检查目标语言、模型和提示词设置；不同服务的语言覆盖并不完全一致。
4. 查询失败时先确认服务已启用，再检查凭据、CLI 登录状态、本地服务地址和网络连接。
5. API 价格、免费额度、模型名称和地区限制请以上游服务的当前说明为准。

## 相关文档

- [完整使用指南](./GUIDE.md)
- [在 Easydict 中使用 Apple Dictionary](./How-to-use-macOS-system-dictionary-in-Easydict.md)
- [在 Easydict 中使用 MDict](./How-to-use-MDict-in-Easydict.md)
- [在 Easydict 中使用 Apple 翻译](./How-to-use-macOS-system-translation-in-Easydict.md)
