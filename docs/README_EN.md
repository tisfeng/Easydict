<p align="center">
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/icon_512x512-1671278252.png" height="256">
  <h1 align="center">Easydict</h1>
  <h4 align="center"> Easy to look up words or translate text</h4>
<p align="center">🇨🇳 🇬🇧 🇯🇵 🇰🇷 🇫🇷 🇪🇸 🇵🇹 🇮🇹 🇷🇺 🇩🇪 🇸🇦 🇸🇪 🇳🇱 🇷🇴 🇹🇭 🇸🇰 🇭🇺 🇬🇷 🇩🇰 🇫🇮 🇵🇱 🇨🇿 🇹🇷 🇱🇹 🇱🇻 🇺🇦 🇧🇬 🇮🇩 🇲🇾 🇸🇮 🇪🇪 🇻🇳 🇮🇷 🇵🇰 🇹🇱 🇹🇦 🇮🇳 🇵🇭 🇫🇮 🇰🇭 🇱🇦 🇧🇳 🇲🇲 🇳🇴 🇷🇸 🇭🇷 🇲🇳 🇮🇱 </p>
</p>

## Easydict 易词典

`Easydict` is a concise and easy-to-use translation dictionary macOS App that allows you to easily and elegantly look up words or translate text. It is an open-source version of [Bob](https://apps.apple.com/cn/app/id1630034110#?platform=mac) and is permanently free. Easydict is ready to use out of the box, can automatically recognize the language of the input text, supports input translate, select translate, and OCR screenshot translate, and can query multiple translation services result at the same time. Currently, it supports [Youdao Dictionary](https://www.youdao.com/), **macOS System Translation**, [DeepL](https://www.deepl.com/translator), [Google](https://translate.google.com/), [Baidu](https://fanyi.baidu.com/), and [Volcano Translation](https://translate.volcengine.com/translate).

![iShot_2023-01-07_19.33.01的副本-1673091295](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-07_19.33.01的副本-1673091295.png)

## Features

- [x] Out of the box, easily look up words or translate text.
- [x] Automatic recognition of input language and automatic query of target preferred language.
- [x] Auto select translate, automatically display the query icon after word search, mouse hover to query.
- [x] Support system OCR screenshot translation.
- [x] Support system TTS.
- [x] Support for configuring different services for different window types.
- [x] Support macOS system translation. (_Please see [How to use 🍎 macOS system translation in Easydict?](https://github.com/tisfeng/Easydict/blob/main/docs/How-to-use-macOS%F0%9F%8D%8Esystem-translation-in-Easydict.md)_)
- [x] Support Youdao Dictionary, DeepL, Google, Baidu and Volcano Translator, no Key required, totally free!
- [x] Support for 48 languages.

Next step.

- [ ] Supports service API calls, such as DeepL.
- [ ] Support more query services.
- [ ] Support for macOS system dictionary.

_**If you like this extension, please give it a [Star](https://github.com/tisfeng/Easydict) ⭐️, thanks!**_

### Installation

[Download](https://github.com/tisfeng/Easydict/releases) the latest release of the app.

### Usage

Once Easydict is launched, in addition to the main window (hidden by default), there will be a menu icon, and clicking on the menu option will trigger the corresponding function, as follows:

![iShot_2023-01-04_17.01.56](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-04_17.01.56-1672847630.png)

| Ways                      | Description                                                                                                                         | Preview                                                                                                                                        |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| Auto select translate     | The query icon is automatically displayed after the word is selected, and the mouse hovers over it to query                         | ![iShot_2023-01-20_11.01.35-1674183779](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.01.35-1674183779.gif) |
| Shortcut select translate | After selecting the text to be translated, press the shortcut key (default `⌥ + D`)                                                 | ![iShot_2023-01-20_11.24.37-1674185125](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.24.37-1674185125.gif) |
| Screenshot translate      | Press the screenshot translate shortcut key (default `⌥ + S`) to capture the area to be translated                                  | ![iShot_2023-01-20_11.26.25-1674185209](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.26.25-1674185209.gif) |
| Input translate           | Press the input translate shortcut key (default `⌥ + A`, or `⌥ + F`), enter the text to be translated, and `Enter` key to translate | ![iShot_2023-01-20_11.28.46-1674185354](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.28.46-1674185354.gif) |

### Services

**Currently, we support Youdao Dictionary, macOS system translation, DeepL, Google, Baidu and Volcano translation, total 6 translation services.**

> Note ⚠️: Since the Chinese version of Google Translate is currently unavailable, you can only use the international version, so you need to use a proxy to use Google Translate.

Supported languages:

| Languages             | Youdao | DeepL | macOS System | Google | Baidu | Volcano |
| :-------------------- | :----: | :---: | :----------: | :----: | :---: | :-----: |
| Chinese (Simplified)  |   ✅   |  ✅   |      ✅      |   ✅   |  ✅   |   ✅    |
| Chinese (Traditional) |   ✅   |  ⚠️   |      ❌      |   ✅   |  ✅   |   ✅    |
| English               |   ✅   |  ✅   |      ✅      |   ✅   |  ✅   |   ✅    |
| Japanese              |   ✅   |  ✅   |      ✅      |   ✅   |  ✅   |   ✅    |
| Korean                |   ✅   |  ❌   |      ✅      |   ✅   |  ✅   |   ✅    |
| French                |   ✅   |  ✅   |      ✅      |   ✅   |  ✅   |   ✅    |
| Spanish               |   ❌   |  ✅   |      ✅      |   ✅   |  ✅   |   ✅    |
| Portuguese            |   ❌   |  ✅   |      ✅      |   ✅   |  ✅   |   ✅    |
| Italian               |   ❌   |  ✅   |      ✅      |   ✅   |  ✅   |   ✅    |
| German                |   ❌   |  ✅   |      ✅      |   ✅   |  ✅   |   ✅    |
| Russian               |   ❌   |  ✅   |      ✅      |   ✅   |  ✅   |   ✅    |
| Arabic                |   ❌   |  ❌   |      ✅      |   ✅   |  ✅   |   ✅    |
| Swedish               |   ❌   |  ✅   |      ❌      |   ✅   |  ✅   |   ✅    |
| Romanian              |   ❌   |  ✅   |      ❌      |   ✅   |  ✅   |   ✅    |
| Thai                  |   ❌   |  ❌   |      ✅      |   ✅   |  ✅   |   ✅    |
| Slovak                |   ❌   |  ✅   |      ❌      |   ✅   |  ✅   |   ✅    |
| Dutch                 |   ❌   |  ✅   |      ✅      |   ✅   |  ✅   |   ✅    |
| Hungarian             |   ❌   |  ✅   |      ❌      |   ✅   |  ✅   |   ✅    |
| Greek                 |   ❌   |  ✅   |      ❌      |   ✅   |  ✅   |   ✅    |
| Danish                |   ❌   |  ✅   |      ❌      |   ✅   |  ✅   |   ✅    |
| Finnish               |   ❌   |  ✅   |      ❌      |   ✅   |  ✅   |   ✅    |
| Polish                |   ❌   |  ✅   |      ✅      |   ✅   |  ✅   |   ✅    |
| Czech                 |   ❌   |  ✅   |      ❌      |   ✅   |  ✅   |   ✅    |
| Turkish               |   ❌   |  ✅   |      ✅      |   ✅   |  ✅   |   ✅    |
| Lithuanian            |   ❌   |  ✅   |      ❌      |   ✅   |  ✅   |   ✅    |
| Latvian               |   ❌   |  ✅   |      ❌      |   ✅   |  ✅   |   ✅    |
| Ukrainian             |   ❌   |  ✅   |      ❌      |   ✅   |  ✅   |   ✅    |
| Bulgarian             |   ❌   |  ✅   |      ❌      |   ✅   |  ✅   |   ✅    |
| Indonesian            |   ❌   |  ✅   |      ✅      |   ✅   |  ✅   |   ✅    |
| Malay                 |   ❌   |  ❌   |      ❌      |   ✅   |  ✅   |   ✅    |
| Slovenian             |   ❌   |  ✅   |      ❌      |   ✅   |  ✅   |   ✅    |
| Estonian              |   ❌   |  ✅   |      ❌      |   ✅   |  ✅   |   ✅    |
| Vietnamese            |   ❌   |  ❌   |      ✅      |   ✅   |  ✅   |   ✅    |
| Persian               |   ❌   |  ❌   |      ❌      |   ✅   |  ✅   |   ✅    |
| Hindi                 |   ❌   |  ❌   |      ❌      |   ✅   |  ✅   |   ✅    |
| Telugu                |   ❌   |  ❌   |      ❌      |   ✅   |  ✅   |   ✅    |
| Tamil                 |   ❌   |  ❌   |      ❌      |   ✅   |  ✅   |   ✅    |
| Urdu                  |   ❌   |  ❌   |      ❌      |   ✅   |  ✅   |   ✅    |
| Filipino              |   ❌   |  ❌   |      ❌      |   ✅   |  ✅   |   ✅    |
| Khmer                 |   ❌   |  ❌   |      ❌      |   ✅   |  ✅   |   ✅    |
| Lao                   |   ❌   |  ❌   |      ❌      |   ✅   |  ✅   |   ✅    |
| Bengali               |   ❌   |  ❌   |      ❌      |   ✅   |  ✅   |   ✅    |
| Burmese               |   ❌   |  ❌   |      ❌      |   ✅   |  ✅   |   ✅    |
| Norwegian             |   ❌   |  ❌   |      ❌      |   ✅   |  ✅   |   ✅    |
| Serbian               |   ❌   |  ❌   |      ❌      |   ✅   |  ✅   |   ✅    |
| Croatian              |   ❌   |  ❌   |      ❌      |   ✅   |  ✅   |   ✅    |
| Mongolian             |   ❌   |  ❌   |      ❌      |   ✅   |  ✅   |   ✅    |
| Hebrew                |   ❌   |  ❌   |      ❌      |   ✅   |  ✅   |   ✅    |

> Note: ⚠️ means the translation of source language to Traditional Chinese is not supported, such as DeepL. If you enter Traditional Chinese for translation, it will be treated as Simplified Chinese.

### Preferences

The settings page provides some preference setting modifications, such as automatically playing word pronunciation after turning on query, modifying translation shortcut keys, turning on and off services, or adjusting the order of services, etc.

#### Settting

![iShot_2023-01-20_11.46.57-1674186468](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.46.57-1674186468.png)

#### Services

Easydict has 3 types of windows and you can set different services for each of them.

- Mini window: displayed when the mouse automatically picks up words.
- Side hover window: displayed when shortcut keys are used to fetch words and screenshot translation.
- Main window: closed by default, you can turn it on in the settings and show it when the program starts. (The main window function will be enhanced later)

![iShot_2023-01-20_11.47.34-1674186506](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.47.34-1674186506.png)

#### Other Shortcuts

- `Enter`: After entering text, press Enter to start the query.
- `Shift + Enter`: Enter a line feed.
- `Cmd + Enter`: Opens Google search engine by default, and the search content is the entered text, which is equivalent to manually clicking the browser search icon in the upper right corner. If you have the Eudicons App installed on your computer, an Eudicons icon will be displayed to the left of the Safari icon, and the `Cmd + Enter` action will open the Eudicons App for searching.

## Related Projects

- [Raycast-Easydict](https://github.com/tisfeng/Raycast-Easydict) is a Raycast extension of Easydict。

## Motivation

Looking up words and translating text is a very useful function in daily life. I have used many translation dictionaries, but I was not satisfied until I met Bob. [`Bob`](https://bobtranslate.com/) is an excellent translation software, but it is not open source and no longer provides free application updates since it hit the Apple Store.

As a developer and beneficiary of a lot of open source software, I think that there should be a free open source version of [Bob](https://github.com/ripperhe/Bob) in the world, so I made [Easydict](https://github.com/tisfeng/Easydict).

Now I use Easydict a lot every day, I like it very much, and I hope more people can know it and use it.

Open source makes the world better.

## Thanks

This project was inspired by [saladict](https://github.com/crimx/ext-saladict) and [Bob](https://github.com/ripperhe/Bob), and the initial version was developed based on [Bob](https://github.com/cheonvo/Bob). [Easydict](https://github.com/tisfeng/Easydict) has made many improvements and optimizations on the original project, and many features and UI are referenced from Bob, thanks to the original author [ripperhe](https://github.com/ripperhe).

> [`Bob`](https://bobtranslate.com/) is a translation and OCR software for macOS platform.
