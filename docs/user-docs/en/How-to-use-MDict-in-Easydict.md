# Use MDict in Easydict

Easydict can query local MDict dictionaries directly. You do not need to convert them to Apple's
`.dictionary` format or configure an API key.

## Supported files

- `.mdx`: the dictionary entries; required when importing a dictionary.
- `.mdd`: optional images, styles, audio, and other resources.

Only use dictionary files you are authorized to use. Easydict does not provide third-party
dictionary downloads.

## Import a dictionary

1. Put the `.mdx` and matching `.mdd` files for a dictionary in the same folder and keep their
   matching file names.
2. Open Easydict Settings → Services, then add or open the MDict service.
3. Choose the import button and select the `.mdx` file. Easydict automatically discovers matching
   `.mdd` files in the same folder.
4. If a resource file is not linked automatically, select the matching `.mdd` file separately from
   the same screen.
5. Make sure the dictionary is enabled. Drag dictionaries to change their lookup order.

Easydict stores references to the original files; it does not copy them. Do not move, rename, or
delete imported `.mdx` or `.mdd` files unless you plan to import them again.

## Manage dictionaries

The MDict service settings let you:

- enable or disable a dictionary;
- reorder multiple dictionaries;
- remove a dictionary record.

Removing a record does not delete the original files from disk.

## Troubleshooting

### Importing an `.mdd` asks for an `.mdx` first

Import the matching `.mdx` first. If the names or folders do not match, put the files together and
try again.

### Entries have text but no images, styles, or audio

Confirm that the companion `.mdd` files are still at their original paths, then import the `.mdx`
or matching `.mdd` again.

### No entry is found

Make sure both the MDict service and the dictionary are enabled, then confirm that the dictionary
contains the entry. Rendering can vary because MDict files use different indexes, encodings, and
resource layouts.

## Apple Dictionary versus MDict

- For `.dictionary` bundles managed by the macOS Dictionary app, follow the
  [Apple Dictionary guide](./How-to-use-macOS-system-dictionary-in-Easydict.md).
- For `.mdx`/`.mdd` files managed directly by Easydict, follow this guide.
