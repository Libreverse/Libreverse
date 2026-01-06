// The source code including full typescript support is available at:
// https://github.com/shakacode/react_on_rails_demo_ssr_hmr/blob/master/babel.config.js
require('v8-compile-cache');
const defaultConfigFunc = require("shakapacker/package/babel/preset.js");

module.exports = function (_api) {
    const resultConfig = defaultConfigFunc(_api);

    const extraPresets = [
        [
            "@babel/preset-react",
            {
                development: false,
                useBuiltIns: true,
                runtime: "automatic",
            },
        ],
    ];

    const extraPlugins = [
        "closure-elimination",
        "module:faster.js",
        ["object-to-json-parse", { minJSONStringSize: 1024 }],
        [
            "babel-plugin-transform-react-remove-prop-types",
            {
                removeImport: true,
            },
        ],
        "babel-plugin-react-compiler",
    ];

    resultConfig.presets = [
        ...resultConfig.presets,
        ...extraPresets,
    ];
    resultConfig.plugins = [
        ...resultConfig.plugins,
        ...extraPlugins,
    ];

    return resultConfig;
};
