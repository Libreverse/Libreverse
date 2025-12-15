#!/usr/bin/env node

// Backwards-compatible wrapper.
// The implementation moved to `verify_typehints.mjs` to avoid Node's
// MODULE_TYPELESS_PACKAGE_JSON warning for ESM scripts in repos that are not
// globally `"type": "module"`.

import("./verify_typehints.mjs").catch((error) => {
    // eslint-disable-next-line no-console
    console.error(error);
    process.exit(1);
});
