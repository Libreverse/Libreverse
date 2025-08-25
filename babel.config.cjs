// eslint-disable-next-line no-undef
module.exports = {
    presets: [
        [
            "@babel/preset-env",
            {
                targets: { node: "current" },
                // Preserve ES modules; Jest will handle ESM via babel-jest with useESM.
                modules: false,
            },
        ],
    ],
};
