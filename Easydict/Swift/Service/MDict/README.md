# MDict Dictionary Service

MDict (`.mdx` / `.mdd`) is a widely used offline dictionary format supporting HTML rich text and multimedia resources.
This directory implements importing, parsing, and querying of MDict files, integrated as a standard Easydict service.

![MDict Architecture Design](./mdict-architecture.svg)

## Directory Structure

```
MDict/
├── MDictReader.swift          # MDict binary parser (Header, Key blocks, Record blocks, libz)
├── MDictDictionary.swift      # High-level dictionary wrapper (Lookup, MDD resource resolution, links)
├── MDictManager.swift         # Dictionary lifecycle management (Import, Persistence, Toggle, Sort, Delete)
├── MDictService.swift         # QueryService subclass, HTML rendering and framework integration
└── MDictConfigurationView.swift  # SwiftUI settings panel (Import, List, Toggle, Sort, Delete)
```

## Core Components

### MDictReader

Low-level parsing of MDict v1.x / v2.x binary format:

- **Header Parsing**: Reads UTF-16LE encoded XML header to extract version, encoding,
  format, title, etc. MDD resource files with an empty `Encoding` attribute fall back
  to UTF-16LE, matching common `Library_Data` files.
- **Key Block Parsing**: Reads key info (v2 has separate compressed key info), decrypts
  `Encrypted="2"` key indexes, and builds an in-memory index of
  `word → recordOffset` (`[String: Int]`).
- **Record Block Reading**: Memory-maps dictionary files when possible, decompresses
  target record blocks on demand, and extracts definition data from offsets.
- **Compression Support**: Supports zlib (type `0x02`) through system `libz` and no
  compression (type `0x00`). LZO will throw an error with a hint.

### MDictDictionary

Wraps an MDX file and its accompanying MDD file:

- `lookup(_:)` — Looks up a trimmed word and returns all matching HTML/text
  definitions, stacking duplicate headword records in source order. Case-insensitive
  dictionaries automatically try lowercase and title case if needed.
- `lookupResource(_:)` — Reads binary resources (CSS, images, audio) from MDD files
  and normalizes keys by trying original, leading-backslash, slash-to-backslash, and
  no-leading-backslash forms, ignoring query or fragment suffixes during lookup.
- Rewrites `entry://` links for in-app lookup, inlines stylesheet links, and converts
  MDD image/audio resources, including `srcset` candidates, to `data:` URLs so WKWebView
  can render them without a custom scheme handler.

### MDictManager

Singleton responsible for persistence and runtime management:

- Saves imported dictionary path lists via `Defaults` (`UserDefaults` wrapper).
- Automatically discovers MDD files with the same name in the same directory (supports multiple parts).
- Accepts `.mdx` dictionary files and `.mdd` resource files. MDD imports are merged into
  the matching MDX record and stale standalone MDD records are migrated into resources.
- Provides enable/disable, reordering, and deletion operations, broadcasting `MDictManagerDidChange` notification on change.

### MDictService

Inherits from `QueryService`, implementing standard query interfaces:

- `serviceType()` returns `.mdict`, registered in `QueryServiceFactory`.
- `translate(_:from:to:)` iterates through all enabled dictionaries, wraps HTML definitions in `<iframe>`, reusing the `apple-dictionary.html` framework template.
- Plain text dictionary entries are automatically converted to HTML paragraphs.
- Embedded media and icon resources are normalized before rendering so pronunciation
  controls stay compact inside the result panel.
- Audio links play in place, while local anchors scroll within the current entry instead
  of leaving or reloading the iframe.
- MDict result HTML is loaded by the result WebView directly, and `mdict-entry://`
  navigation is routed back into Easydict lookup.

### MDictConfigurationView

SwiftUI `Section` injected into the settings panel via `service.configurationListItems()`:

- Displays titles and filenames of imported dictionaries, supporting toggles,
  drag-to-sort, explicit trash-button deletion, and swipe-to-delete.
- `+` button in the top right triggers a file picker for `.mdx` and `.mdd` files.
- Shows an Alert with error details if import fails.

## Main Data Flow

```
User Input Query
    ↓
MDictService.translate(_:from:to:)
    ↓
MDictManager.enabledDictionaries  ← Defaults Persistence
    ↓
MDictDictionary.lookup(_:)
    ↓
MDictReader.lookupData(for:)      ← Memory Key Index O(1)
    ↓
decompressBlock / readRecord      ← On-demand Decompression
    ↓
HTML Wrap → QueryResult.htmlString
    ↓
WKWebView Rendering + mdict-entry lookup routing
```

## Debugging

- **Parsing Failure**: `MDictError` carries detailed info like format version and compression type, output via `logError`.
- **Loading Error**: `MDictManager.loadErrors` dictionary records errors for each path, viewable in the config view.
- **Lookup Miss**: Check if `MDictReader.keyIndex` contains the target word (mind the case policy).
- **Encrypted Dicts**: `Encrypted="2"` key-index encryption is supported. `Encrypted="1"`
  still throws `MDictError.encrypted` because it requires registration data.

## Format Version Differences

| Feature | v1.x | v2.x |
|------|------|------|
| Integer Width | 4 bytes | 8 bytes |
| Key Info Compression | None | zlib |
| Checksum | None | adler32 |
| Offset Width | 4 bytes | 8 bytes |
| Key Info Encryption | Not used | `Encrypted="2"` supported |
