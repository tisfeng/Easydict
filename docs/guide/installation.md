# Installation

You can install it using one of the following two methods. Support macOS 11.0+

### 1. Manual Installation

[Download](https://github.com/tisfeng/Easydict/releases) the latest release of the app.

### 2. Homebrew

Thanks to [BingoKingo](https://github.com/tisfeng/Easydict/issues/1#issuecomment-1445286763) for the initial installation version.

```bash
brew install --cask easydict
```

### Developer Build

If you are a developer, or you are interested in this project, you can also try to build and run it manually. The whole process is very simple, even without knowing macOS development knowledge.

<details> <summary> Build Steps </summary>

<p>

1. Download this Repo, and then open the `Easydict.xcworkspace` file with [Xcode](https://developer.apple.com/xcode/) (⚠️⚠️⚠️ Note that it is not `Easydict.xcodeproj` ⚠️⚠️⚠️).
2. Use `Cmd + R` to compile and run.

![image-20231212125308372](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231212125308372-1702356789.png)

The following steps are optional and intended for development collaborators only.

If you often need to debug permission-related features, such as word fetching or OCR, you can choose to run it with your own Apple account, change `DEVELOPMENT_TEAM`` in the `Easydict-debug.xcconfig`` file to your own Apple Team ID (you can find it by logging in to the Apple developer website) and `CODE_SIGN_IDENTITY`` to Apple Development.

Be careful not to commit the `Easydict-debug.xcconfig`` file; you can ignore local changes to this file with the following git command

```bash
git update-index --skip-worktree Easydict-debug.xcconfig
```

#### Build Environment

Xcode 13+, macOS Big Sur 11.3+. To avoid unnecessary problems, it is recommended to use the latest Xcode and macOS version https://github.com/tisfeng/Easydict/issues/79

> [!NOTE]
> Since the latest code uses the String Catalog feature, Xcode 15+ is required to compile.
> If your Xcode version is lower, please use the [xcode-14](https://github.com/tisfeng/Easydict/tree/xcode-14) branch, note that this is a fixed version branch, not maintained.

If the run encounters the following error, try updating CocoaPods and then `pod install`.

>  [DT_TOOLCHAIN_DIR cannot be used to evaluate LD_RUNPATH_SEARCH_PATHS, use TOOLCHAIN_DIR instead](https://github.com/CocoaPods/CocoaPods/issues/12012)

</p>

</details>

### Signature Problem ⚠️

Easydict is open source software and is inherently secure, but due to Apple's strict checking mechanism, you may encounter warning blocks when opening it.

FAQ:

1. If you encounter the following [Cannot open Easydict problem](https://github.com/tisfeng/Easydict/issues/2), please refer to [Open Mac App from an unidentified developer](https://support.apple.com/en-us/guide/mac-help/mh40616/mac)

> Cannot open "Easydict.dmg" because Apple cannot check to see if it contains malware.

<div >
    <img src="https://github.com/Jerry23011/Easydict/assets/89069957/5ecb4cc7-53e7-45c6-8606-df36cf4adb73" width="30%">
    <img src="https://github.com/Jerry23011/Easydict/assets/89069957/7c44e542-62f3-458a-abbb-6ae555b743d7"  width="30%">
    <img src="https://github.com/Jerry23011/Easydict/assets/89069957/060f4927-8df5-4bfd-9283-363cc8d3fa52"  width="30%">
</div>

<div style="display: flex; justify-content: space-between;">
  <img src="https://github.com/Jerry23011/Easydict/assets/89069957/eb2852c1-6ffd-4575-8bb0-5c97d451d582" width="100%" />
</div>

2. If it indicates that the app is corrupted, please refer to [macOS Bypassing Notary and App Signing Methods](https://www.5v13.com/sz/31695.html)

> "Easydict" is corrupted and cannot be opened.

Just type the following command in the terminal and enter the password.

```bash
sudo xattr -rd com.apple.quarantine /Applications/Easydict.app
```

---

## Usage

Once Easydict is launched, in addition to the main window (hidden by default), there will be a menu icon, and clicking on the menu option will trigger the corresponding actions, as follows:

<div>
  <img src="https://github.com/Jerry23011/Easydict/assets/89069957/f0c7da85-b9e0-4003-b673-e93f6477a75b" width="50%" />
</div>

| Ways                      | Description                                                                                                                                  | Preview                                                                                                                                        |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| Mouse select translate    | The query icon is automatically displayed after the word is selected, and the mouse hovers over it to query                                  | ![iShot_2023-01-20_11.01.35-1674183779](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.01.35-1674183779.gif) |
| Shortcut select translate | After selecting the text to be translated, press the shortcut key (default `⌥ + D`)                                                          | ![iShot_2023-01-20_11.24.37-1674185125](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.24.37-1674185125.gif) |
| Screenshot translate      | Press the screenshot translate shortcut key (default `⌥ + S`) to capture the area to be translated                                           | ![iShot_2023-01-20_11.26.25-1674185209](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.26.25-1674185209.gif) |
| Input translate           | Press the input translate shortcut key (default `⌥ + A`, or `⌥ + F`), enter the text to be translated, and `Enter` key to translate          | ![iShot_2023-01-20_11.28.46-1674185354](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.28.46-1674185354.gif) |
| Silent Screenshot OCR     | Press the Silent Screenshot shortcut key（default `⌥ + ⇧ + S`）to capture the area, the OCR results will be copied directly to the clipboard | ![屏幕录制 2023-05-20 22 39 11](https://github.com/Jerry23011/Easydict/assets/89069957/c16f3c20-1748-411e-be04-11d8fe0e61af)                    |
