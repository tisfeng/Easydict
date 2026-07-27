# Dark Reader

This directory vendors a minified browser API build from `darkreader@4.9.128`
for Easydict WebView features. Feature-specific pages opt in to the shared
local runtime, so they keep working offline without enabling it for every
WebView.

- Source: https://github.com/darkreader/darkreader
- Package: https://www.npmjs.com/package/darkreader/v/4.9.128
- License: MIT; see `DarkReader-LICENSE.txt`
- Minifier: `terser@5.49.0`
- `darkreader.min.js` SHA-256:
  `567735bf6a5abf07e1f9feb7695fc79cf0d1e11fbc346d5e06cb862c5bb56c0a`

To update the vendored runtime, use `npm pack darkreader@<version>`, copy the
package's `darkreader.js` and `LICENSE`, then run:

```sh
npx terser@5.49.0 darkreader.js \
  --compress \
  --mangle \
  --output darkreader.min.js
```

Update the version and checksum above, and do not commit the unminified source.
