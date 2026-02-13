const generateWebpackConfigs = require("./generateWebpackConfigs.js");
const webpack = require("webpack");
const TerserPlugin = require("terser-webpack-plugin");

// Keep this config focused on JS optimizations to mirror Vite's production setup.
const productionEnvironmentOnly = (
    clientWebpackConfig,
    _serverWebpackConfig,
) => {
    // Match Vite's `define: { global: 'globalThis' }`.
    clientWebpackConfig.plugins ||= [];
    clientWebpackConfig.plugins.push(
        new webpack.DefinePlugin({
            global: "globalThis",
        }),
    );

    // Prefer modern output; this helps tree-shaking and reduces legacy wrappers.
    clientWebpackConfig.target = ["web", "es2020"];

    clientWebpackConfig.optimization ||= {};
    clientWebpackConfig.optimization.minimize = true;
    clientWebpackConfig.optimization.sideEffects = true;
    clientWebpackConfig.optimization.usedExports = true;
    clientWebpackConfig.optimization.innerGraph = true;
    clientWebpackConfig.optimization.concatenateModules = true;
    clientWebpackConfig.optimization.mangleExports = "deterministic";
    clientWebpackConfig.optimization.moduleIds = "deterministic";
    clientWebpackConfig.optimization.chunkIds = "deterministic";

    // Mirror Vite's terser options (drop console/debugger, aggressive compress, toplevel).
    // We override the minimizer list to ensure these options are applied.
    clientWebpackConfig.optimization.minimizer = [
        new TerserPlugin({
            parallel: true,
            extractComments: false,
            terserOptions: {
                parse: {
                    ecma: 2020,
                },
                compress: {
                    ecma: 2020,
                    defaults: true,
                    drop_console: true,
                    drop_debugger: true,
                    passes: 10,
                    toplevel: true,
                    unsafe: true,
                    unsafe_arrows: true,
                    unsafe_comps: true,
                    unsafe_Function: true,
                    unsafe_math: true,
                    unsafe_methods: true,
                    unsafe_proto: true,
                    unsafe_regexp: true,
                    unsafe_symbols: true,
                    unsafe_undefined: true,
                    pure_getters: "strict",
                    pure_funcs: [
                        "console.log",
                        "console.info",
                        "console.debug",
                        "console.warn",
                        "console.error",
                        "console.trace",
                        "console.dir",
                        "console.dirxml",
                        "console.group",
                        "console.groupCollapsed",
                        "console.groupEnd",
                        "console.time",
                        "console.timeEnd",
                        "console.timeLog",
                        "console.assert",
                        "console.count",
                        "console.countReset",
                        "console.profile",
                        "console.profileEnd",
                        "console.table",
                        "console.clear",
                    ],
                },
                mangle: {
                    toplevel: true,
                },
                format: {
                    ecma: 2020,
                    comments: false,
                },
            },
        }),
    ];
};

module.exports = async (_env, _argv) => {
    const config = generateWebpackConfigs(productionEnvironmentOnly);

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
        // Production builds should still work if the replacements plugin cannot be loaded.
    }

    // Optional parity with Vite: bundle obfuscation (generally increases size and can hurt perf).
    // Enable explicitly with WEBPACK_OBFUSCATE=1.
    if (process.env.WEBPACK_OBFUSCATE === "1") {
        try {
            // eslint-disable-next-line global-require
            const WebpackObfuscator = require("webpack-obfuscator");
            const { allObfuscatorConfig } = await import("../vite/common.js");

            const configs = Array.isArray(config) ? config : [config];
            for (const cfg of configs) {
                if (cfg?.entry && cfg.entry["server-bundle"]) continue;
                cfg.plugins ||= [];
                cfg.plugins.push(
                    new WebpackObfuscator(
                        allObfuscatorConfig?.options || { compact: true },
                        allObfuscatorConfig?.excludes || [],
                    ),
                );
            }
        } catch (_e) {
            // If the dependency isn't installed (or options can't be imported), skip obfuscation.
        }
    }

    return config;
};
