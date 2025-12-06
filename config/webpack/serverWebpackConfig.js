const { config } = require("shakapacker");
const commonWebpackConfig = require("./commonWebpackConfig.js");
const webpack = require("webpack");

const configureServer = () => {
    const serverWebpackConfig = commonWebpackConfig();
    const serverEntry = {
        "server-bundle": serverWebpackConfig.entry["server-bundle"],
    };
    if (!serverEntry["server-bundle"]) {
        throw new Error(
            "Create a pack with the file name 'server-bundle.js' containing all the server rendering files",
        );
    }
    serverWebpackConfig.entry = serverEntry;
    for (const loader of serverWebpackConfig.module.rules) {
        if (loader.use && loader.use.filter) {
            loader.use = loader.use.filter(
                (item) =>
                    !(
                        typeof item === "string" &&
                        /mini-css-extract-plugin/.test(item)
                    ),
            );
        }
    }
    serverWebpackConfig.optimization = { minimize: false };
    serverWebpackConfig.plugins.unshift(
        new webpack.optimize.LimitChunkCountPlugin({ maxChunks: 1 }),
    );
    serverWebpackConfig.output = {
        filename: "server-bundle.js",
        globalObject: "this",
        path: config.outputPath,
        publicPath: config.publicPath,
        hashFunction: "sha256",
    };
    serverWebpackConfig.plugins = serverWebpackConfig.plugins.filter(
        (plugin) =>
            plugin.constructor.name !== "WebpackAssetsManifest" &&
            plugin.constructor.name !== "MiniCssExtractPlugin" &&
            plugin.constructor.name !== "ForkTsCheckerWebpackPlugin",
    );
    const rules = serverWebpackConfig.module.rules;
    for (const rule of rules) {
        if (Array.isArray(rule.use)) {
            rule.use = rule.use.filter((item) => {
                let testValue;
                if (typeof item === "string") testValue = item;
                else if (typeof item.loader === "string")
                    testValue = item.loader;
                return !(
                    /mini-css-extract-plugin/.test(testValue) ||
                    testValue === "style-loader"
                );
            });
            const cssLoader = rule.use.find((item) => {
                let testValue;
                if (typeof item === "string") testValue = item;
                else if (typeof item.loader === "string")
                    testValue = item.loader;
                return testValue.includes("css-loader");
            });
            if (cssLoader && cssLoader.options) {
                // Preserve any existing css-loader modules configuration (like namedExport / localIdentName)
                // and simply add exportOnlyLocals for the server bundle so the same shape of exports is kept.
                const priorModules = cssLoader.options.modules;
                cssLoader.options.modules =
                    priorModules && typeof priorModules === "object"
                        ? {
                              ...priorModules,
                              exportOnlyLocals: true,
                          }
                        : { exportOnlyLocals: true };
            }
        } else if (
            rule.use &&
            (rule.use.loader === "url-loader" ||
                rule.use.loader === "file-loader")
        ) {
            rule.use.options.emitFile = false;
        }
    }
    serverWebpackConfig.devtool = "eval";
    return serverWebpackConfig;
};

module.exports = configureServer;
