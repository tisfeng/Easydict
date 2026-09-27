# Use Apple Dictionary in Easydict

Easydict can query system dictionaries and `.dictionary` bundles enabled in the macOS Dictionary
app. This makes them available even in apps that do not support the system three-finger lookup.

## Enable system dictionaries

1. Open the macOS Dictionary app.
2. Open Dictionary → Settings, enable the dictionaries you need, and arrange their order.
3. Open Easydict Settings → Services, then add or enable Apple Dictionary.
4. Look up a word and confirm that Apple Dictionary results appear.

Dictionary content and language availability are controlled by macOS and the Dictionary app, so
they may differ between system versions and regions.

## Add a `.dictionary` bundle

If you have a legally obtained Apple `.dictionary` bundle:

1. In the Dictionary app, choose File → Open Dictionaries Folder.
2. Put the `.dictionary` bundle in that folder.
3. Reopen Dictionary and enable the new dictionary in its settings.
4. Restart Easydict so it reloads the dictionary list.

Do not use dictionary files from unknown or unauthorized sources. Easydict does not provide
third-party dictionary downloads.

## Use MDX/MDD dictionaries

MDX/MDD files are not Apple `.dictionary` bundles. Easydict now includes a native MDict service, so
you can import them without conversion. See [Use MDict in Easydict](./How-to-use-MDict-in-Easydict.md).

## Troubleshooting

- **A new dictionary is missing in Easydict**: enable it in Dictionary settings, then restart
  Easydict.
- **Lookup returns no result**: confirm that the dictionary contains the entry and try moving it
  earlier in the Dictionary app's list.
- **You only want selected dictionaries**: disable the others in Dictionary settings.
