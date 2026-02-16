#!/usr/bin/env node

import process from "node:process";

// Backwards-compatible wrapper.
// The implementation moved to `verify_typehints.mjs` to avoid Node's
// MODULE_TYPELESS_PACKAGE_JSON warning for ESM scripts in repos that are not
// globally `"type": "module"`.

try {
    await import("./verify_typehints.mjs");
} catch (error) {
    console.error(error);
    process.exit(1);
}
