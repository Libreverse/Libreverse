// The source code including full typescript support is available at:
// https://github.com/shakacode/react_on_rails_demo_ssr_hmr/blob/master/babel.config.js
require('v8-compile-cache');
const defaultConfigFunc = require("shakapacker/package/babel/preset.js");

module.exports = function (api) {
    const resultConfig = defaultConfigFunc(api);
    const isProductionEnv = api.env("production");

    const changesOnDefault = {
        presets: [
            [
                "@babel/preset-react",
                {
                    development: !isProductionEnv,
                    useBuiltIns: true,
                    runtime: "automatic",
                },
            ],
            // Optional: React-focused micro-optimizations. Enable explicitly to reduce risk.
            // These transforms can be sensitive to React/runtime/tooling changes.
            isProductionEnv &&
                process.env.BABEL_REACT_OPTIMIZE === "1" &&
                "babel-preset-react-optimize",
        ].filter(Boolean),
        plugins: [
            // Mirror Vite's production Babel transforms.
            isProductionEnv && "closure-elimination",
            isProductionEnv && "module:faster.js",
            isProductionEnv && ["object-to-json-parse", { minJSONStringSize: 1024 }],

            // Enable React Refresh (Fast Refresh) only when webpack-dev-server is running (HMR mode)
            // This prevents React Refresh from trying to connect when using static compilation
            !isProductionEnv &&
                process.env.WEBPACK_SERVE &&
                "react-refresh/babel",

            // Optional: React hoists/inlining.
            // Enable explicitly due to potential incompatibilities with modern JSX transforms.
            isProductionEnv &&
                process.env.BABEL_REACT_HOIST === "1" &&
                "babel-plugin-transform-react-constant-elements",
            isProductionEnv &&
                process.env.BABEL_REACT_INLINE === "1" &&
                "babel-plugin-transform-react-inline-elements",

            isProductionEnv && [
                "babel-plugin-transform-react-remove-prop-types",
                {
                    removeImport: true,
                },
            ],

            // Optional: React Compiler (Forget) / auto-memoization.
            // This is experimental; keep opt-in.
            isProductionEnv &&
                process.env.REACT_COMPILER === "1" &&
                "babel-plugin-react-compiler",
        ].filter(Boolean),
    };

    resultConfig.presets = [
        ...resultConfig.presets,
        ...changesOnDefault.presets,
    ];
    resultConfig.plugins = [
        ...resultConfig.plugins,
        ...changesOnDefault.plugins,
    ];

    return resultConfig;
};
