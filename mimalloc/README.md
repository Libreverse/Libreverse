# mimalloc (local dev + packaging)

This folder is used to stage a **macOS** `libmimalloc.dylib` so it can be:

1. Preloaded in local development via `DYLD_INSERT_LIBRARIES` (see `/.envrc`).
2. Bundled into the packaged Electron app as an extra resource (see `forge.config.js`).

## How it gets populated

Run:

- `ruby scripts/prepare_mimalloc.rb`

On macOS, this copies Homebrew’s `libmimalloc.dylib` into:

- `mimalloc/libmimalloc.dylib`

The dylib is **gitignored** (we don’t commit binaries).

## Notes

- `DYLD_INSERT_LIBRARIES` must be set *before* a process starts.
- Hardened runtime / SIP can restrict `DYLD_*` variables for some binaries.
