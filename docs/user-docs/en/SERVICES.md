# Easydict Services

Easydict can query dictionaries, general translation providers, AI models, and local or
command-line services at the same time. Availability ultimately depends on your macOS version,
network, account access, and the upstream service.

## Access types

The Services settings use these access types:

- **No key**: Easydict does not ask for an API key. A network connection, system component, or
  local program may still be required.
- **Built in**: Uses access provided by the project, without a user-supplied key. It may become
  temporarily unavailable when an upstream service changes.
- **User key**: Requires your own API key, App ID, or secret in the service settings.
- **CLI**: Requires the corresponding command-line tool to be installed and signed in.

> [!NOTE]
> New installations enable Youdao, DeepL, and Built-in AI by default. Open Settings → Services to
> add, remove, enable, disable, or reorder services. `CustomOpenAI` supports multiple instances.

## Dictionaries

| Service | Access | Notes |
| --- | --- | --- |
| Apple Dictionary (`AppleDictionary`) | No key | Queries dictionaries enabled in the macOS Dictionary app. |
| MDict (`MDict`) | No key | Queries user-imported MDX/MDD dictionaries directly. |
| Youdao (`Youdao`) | No key | Online dictionary lookup and the default TTS service. |

## AI models and local/CLI services

| Service | Access | Notes |
| --- | --- | --- |
| OpenAI (`OpenAI`) | User key | Uses the official OpenAI service through OpenAI-compatible settings. |
| DeepSeek (`DeepSeek`) | User key | Uses the DeepSeek API. |
| Groq (`Groq`) | User key | Uses the Groq API. |
| Zhipu AI (`Zhipu`) | User key | Uses the Zhipu open platform API. |
| MiniMax (`MiniMax`) | User key | Uses the MiniMax API. |
| GitHub Models (`GitHub`) | User key | Uses GitHub Models. |
| Built-in AI (`BuiltInAI`) | Built in | AI queries without a separately configured API key. |
| Claude Code (`ClaudeCode`) | CLI | Calls an installed and authenticated Claude Code CLI. |
| Codex CLI (`CodexCLI`) | CLI | Calls an installed and authenticated Codex CLI. |
| Gemini (`Gemini`) | User key | Uses the Gemini API. |
| Claude (`Claude`) | User key | Uses the Anthropic Claude API. |
| Ollama (`Ollama`) | No key | Calls Ollama on this Mac or at a custom server URL. |
| Custom OpenAI (`CustomOpenAI`) | User key | Configures an OpenAI-compatible endpoint; supports multiple instances. |

## AI tools

| Service | Access | Notes |
| --- | --- | --- |
| Polishing (`Polishing`) | Built in | Polishes the input text with AI. |
| Summary (`Summary`) | Built in | Summarizes the input text with AI. |

## General translation

| Service | Access | Notes |
| --- | --- | --- |
| DeepL (`DeepL`) | No key | Uses Easydict's built-in DeepL query method. |
| Google Translate (`Google`) | No key | Uses Google Translate. |
| Apple Translate (`Apple`) | No key | Can use system offline translation on macOS 15+ and otherwise fall back to a Shortcut. |
| Baidu Translate (`Baidu`) | User key | Requires Baidu Translate platform credentials. |
| Bing Translate (`Bing`) | No key | Uses Bing Translate. |
| Volcano Translate (`Volcano`) | User key | Requires Volcano translation credentials. |
| NiuTrans (`NiuTrans`) | Built in | Uses access provided by the project. |
| Caiyun (`Caiyun`) | Built in | Uses access provided by the project. |
| Tencent Translate (`Tencent`) | User key | Requires Tencent translation credentials. |
| Alibaba Translate (`Alibaba`) | User key | Requires Alibaba translation credentials. |
| Doubao Translate (`Doubao`) | User key | Requires Doubao translation credentials. |

## Configuration tips

1. Keep only a few frequently used services enabled to avoid unnecessary requests for each query.
2. For private or offline workflows, consider Apple Dictionary, MDict, Apple offline translation,
   or Ollama.
3. Check the target language, model, and prompt settings for AI services. Language coverage differs
   between services.
4. If a query fails, first confirm that the service is enabled, then check credentials, CLI login,
   local server URL, and network connectivity.
5. Refer to the provider's current documentation for pricing, free quotas, model names, and regional
   availability.

## Related documentation

- [Complete usage guide](./GUIDE.md)
- [Use Apple Dictionary in Easydict](./How-to-use-macOS-system-dictionary-in-Easydict.md)
- [Use MDict in Easydict](./How-to-use-MDict-in-Easydict.md)
- [Use Apple Translate in Easydict](./How-to-use-macOS-system-translation-in-Easydict.md)
