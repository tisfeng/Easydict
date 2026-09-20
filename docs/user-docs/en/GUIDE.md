# Easydict Complete Usage Guide

Easydict is a macOS dictionary and translation app with typed input, text selection, OCR, speech,
local dictionaries, and multiple online or AI services.

## Feature overview

- Automatic input-language detection and 52 selectable translation languages; availability varies
  by service.
- Typed input, mouse selection, selection shortcuts, screenshot translation, and silent OCR.
- Apple Vision OCR with an optional Youdao OCR fallback.
- Apple, Baidu, Bing, Google, and Youdao TTS.
- 20+ dictionary, translation, AI, local-model, and CLI services; see the
  [services overview](./SERVICES.md).
- Separate service selections for the main, floating, and mini windows.
- Query history, favorites, export and cleanup, plus Markdown rendering for AI results.

## Installation

The latest version requires macOS 13.0 or later. Users on macOS 11/12 can install the older
[2.7.2 release](https://github.com/tisfeng/Easydict/releases/tag/2.7.2), which does not include
current features.

### Homebrew (recommended)

```bash
brew install --cask easydict
```

### Manual installation

Download the latest version from [GitHub Releases](https://github.com/tisfeng/Easydict/releases).

### Developer build

The current source requires macOS 13+, Xcode 16+, and CocoaPods.

1. Clone the repository and switch to the `dev` branch.
2. Run `pod install` in the repository directory.
3. Open `Easydict.xcworkspace` in Xcode, not `Easydict.xcodeproj`.
4. Select the Easydict scheme and press `Command + R` to build and run.

When frequently debugging selection or OCR, use your own Apple Development certificate. Ad-hoc
signing can cause macOS to reset permissions after each rebuild. The project script creates a local,
Git-ignored signing configuration:

```bash
chmod +x scripts/setup-team.sh
./scripts/setup-team.sh
```

If the Team ID cannot be detected, run `./scripts/setup-team.sh ABC123DE45`. Without a development
certificate, use `./scripts/setup-team.sh --adhoc`. Remove the local configuration with
`./scripts/setup-team.sh --uninstall`.

## Basic usage

| Action | Default shortcut | Result |
| --- | --- | --- |
| Input translation | `Option + A` | Opens the input window; press Return to query. |
| Mouse selection | None | Select text, then hover over or click the lookup icon. |
| Selection translation | `Option + D` | Queries the currently selected text. |
| Screenshot translation | `Option + S` | Captures an area, recognizes its text, and translates it. |
| Silent screenshot OCR | `Option + Shift + S` | Captures an area and copies recognized text to the clipboard. |
| Show mini window | `Option + F` | Opens the mini query window. |

Settings → Shortcuts also lets you assign global shortcuts for clipboard translation, screenshot
OCR, clipboard OCR, the OCR window, translate-and-replace, polish-and-replace, and other actions.
Some of these actions have no default shortcut.

## Permissions

macOS requests permissions according to the features you use:

- **Accessibility**: reads selected text in other apps and performs replacement actions.
- **Screen Recording**: captures screenshots for translation and OCR.
- **Automation**: controls browsers, Shortcuts, or other apps when required.

Grant them under System Settings → Privacy & Security. After changing the app signature, moving the
app, or rebuilding it, macOS may treat it as a new app and ask again.

## Selection and input

Easydict chooses an appropriate text-selection method for the frontmost app. If it cannot read a
selection:

1. Check Accessibility permission.
2. Use `Command + C` to verify that the text can be copied.
3. Use the input window or clipboard translation instead.
4. Use OCR for images, scanned PDFs, or text that cannot be selected.

General settings include automatic queries while typing and reverse translation. Select the source
language manually when automatic detection is inaccurate.

## OCR

Easydict uses Apple Vision OCR by default. If Youdao OCR fallback is enabled, it tries Youdao when
system recognition fails. Available recognition languages depend on your macOS version; newer
systems generally offer more languages.

- **Screenshot translation**: runs enabled query services after OCR.
- **Silent screenshot OCR**: recognizes and copies text without showing translation results.
- **Screenshot/clipboard OCR and OCR window**: use them from the menu or assign global shortcuts.

For better results, capture a smaller area, improve text/background contrast, and select the correct
recognition language in settings.

## Text to speech

Easydict supports Apple, Baidu, Bing, Google, and Youdao TTS, with Youdao selected by default. TTS
settings control the service and automatic playback. You can also disable the preference that uses
Youdao first for English words.

Online TTS depends on the network and upstream service. System voices and languages depend on voices
installed in macOS.

## Service settings

New installations enable Youdao, DeepL, and Built-in AI by default. Open Settings → Services to:

- add, remove, enable, disable, and reorder services;
- see whether a service uses no key, built-in access, a user key, or a CLI;
- enter an API key, App ID, or secret where required;
- select services separately for the main, floating, and mini windows;
- add multiple custom OpenAI-compatible services.

See the [services overview](./SERVICES.md) for the complete list, access requirements, and guidance.
Focused setup guides:

- [Apple Dictionary](./How-to-use-macOS-system-dictionary-in-Easydict.md)
- [MDict](./How-to-use-MDict-in-Easydict.md)
- [Apple Translate](./How-to-use-macOS-system-translation-in-Easydict.md)

## History and results

- Query history keeps recent items for re-querying, favoriting, exporting, or clearing.
- Favorites keep entries you want to revisit.
- Markdown returned by AI services is rendered as rich text; copied content remains available as text.
- Service cards can be retried, copied, or collapsed depending on the current window and state.

## In-app shortcuts

These shortcuts work while an Easydict window is in the foreground:

| Shortcut | Action |
| --- | --- |
| `Return` / `Shift + Return` | Query / insert a line break. |
| `Command + K` | Clear the input. |
| `Command + Shift + K` | Clear the input and results. |
| `Command + Shift + C` | Copy the query text. |
| `Command + Shift + J` | Copy the first query result. |
| `Command + I` | Focus the input field. |
| `Command + S` | Speak the query text. |
| `Command + R` | Run the query again. |
| `Command + T` | Swap source and target languages. |
| `Command + P` | Pin or unpin the window. |
| `Command + Y` | Hide the window. |
| `Command + Keypad +` / `Command + Keypad -` | Increase / decrease result text size. |
| `Command + Return` | Search the input with Google. |
| `Command + Shift + Return` | Look up the input in Eudic. |
| `Command + Shift + D` | Look up the input with Apple Dictionary. |

Change global shortcuts under Settings → Shortcuts. If a shortcut does not respond, check for a
conflict with another app or a macOS shortcut.

## URL scheme

Use this URL to start a query from another app. The `text` value must be URL-encoded:

```text
easydict://query?text=hello%20world
```

The older `easydict://text` form can fail in some contexts, so always prefer the complete
`query?text=` form.

### Use with PopClip

After installing [PopClip](https://www.popclip.app/), install this AppleScript action as an extension:

```applescript
-- #popclip
-- name: Easydict
-- icon: iconify:ri:translate
-- language: applescript
tell application "Easydict"
  launch
  open location "easydict://query?text={popclip text}"
end tell
```

## Troubleshooting

- **Selection does not work**: check Accessibility permission and confirm that the target app lets
  you select or copy text.
- **Screenshot capture does not work**: check Screen Recording permission and restart Easydict.
- **Only one service fails**: check whether it is enabled, then verify credentials, CLI login, local
  URL, and network status.
- **A language is unsupported**: switch services; translation, OCR, and TTS coverage differ.
- **A setting does not apply**: quit and reopen Easydict, then check whether multiple versions are
  running.

## Contributing

- See the [contribution guide](../../../CONTRIBUTING.md) for development and code contributions.
- See [How to translate Easydict](./How-to-translate-Easydict.md) for localization contributions.
- Report bugs and ideas in [GitHub Issues](https://github.com/tisfeng/Easydict/issues).
