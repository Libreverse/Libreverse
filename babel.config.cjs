// eslint-disable-next-line no-undef
module.exports = {
    presets: [
        [
            "@babel/preset-env",
            {
                targets: { node: "current" },
                // Compile modules to CommonJS for Jest's runtime.
                modules: "commonjs",
            },
        ],
    ],
};
