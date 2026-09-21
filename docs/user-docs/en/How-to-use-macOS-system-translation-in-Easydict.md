# Use Apple Translate in Easydict

The Apple Translate service has two execution paths:

- **macOS 15 and later**: optionally use Apple's Translation framework for offline translation
  between languages supported by the system.
- **Shortcut fallback**: when offline translation is disabled, unsupported, or unavailable,
  Easydict calls system translation through a specific macOS Shortcut.

## macOS 15 and later: offline translation

1. Download the languages you need in the relevant macOS language and translation settings.
2. Open Easydict Settings → Advanced and enable Apple offline translation.
3. Open Settings → Services, then add or enable Apple Translate.
4. Test with a source and target language supported by the system.

Apple offline translation is disabled by default. Language coverage and downloaded language packs
are managed by the current macOS version. The system may ask for a language download or return an
error when a pack is missing.

## macOS 13/14 or fallback path: install the Shortcut

Open and install
[Easydict-Translate-V1.2.0](https://www.icloud.com/shortcuts/776f8a1d8e43471885e8a505eb9a9deb)
with Safari:

1. Choose Get Shortcut.
2. Allow Safari to open the Shortcuts app.
3. Choose Add Shortcut.
4. Confirm that its name is `Easydict-Translate-V1.2.0`.

Do not rename the Shortcut or change its actions. Easydict invokes it by its expected name. On the
first run, macOS may ask for Automation permission to let Easydict control Shortcuts; allow it.

## Enable the service

Open Easydict Settings → Services, then add or enable Apple Translate. On macOS 15+, Easydict uses
the Translation framework when offline translation is enabled; otherwise it uses the Shortcut
path automatically.

## Troubleshooting

- **The Shortcut cannot be found**: verify the exact name `Easydict-Translate-V1.2.0` and run it
  once in the Shortcuts app.
- **Offline translation returns no result**: verify that you use macOS 15+, enabled the Easydict
  setting, and downloaded the required languages.
- **The call is denied**: check Easydict under System Settings → Privacy & Security → Automation.
- **A language is unavailable**: Apple controls the system language coverage; use another Easydict
  service when necessary.
