const generateWebpackConfigs = require("./generateWebpackConfigs.js");
const webpack = require("webpack");

module.exports = async (_env, _argv) => {
    const config = generateWebpackConfigs();

    // Match Vite's `define: { global: 'globalThis' }`.
    {
        const configs = Array.isArray(config) ? config : [config];
        for (const cfg of configs) {
            if (cfg?.entry && cfg.entry["server-bundle"]) continue;
            cfg.plugins ||= [];
            cfg.plugins.push(
                new webpack.DefinePlugin({
                    global: "globalThis",
                }),
            );
        }
    }

    // Best-effort parity with Vite: apply e18e modernization replacements.
    // This package is ESM-only, so we load it via dynamic import.
    try {
        const { default: replacements } = await import(
            "@e18e/unplugin-replacements/webpack"
        );

        const configs = Array.isArray(config) ? config : [config];
        for (const cfg of configs) {
            // Only apply to browser/client bundles.
            if (cfg?.entry && cfg.entry["server-bundle"]) continue;
            cfg.plugins ||= [];
            cfg.plugins.push(replacements());
        }
    } catch (_e) {
        // If the plugin cannot be loaded, dev should still work.
    }

    return config;
};
