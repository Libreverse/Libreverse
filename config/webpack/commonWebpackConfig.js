// Common configuration applying to client and server configuration (CommonJS version)
const { generateWebpackConfig, merge } = require("shakapacker");

const baseClientWebpackConfig = generateWebpackConfig();

const commonOptions = {
    resolve: {
        extensions: [".css", ".ts", ".tsx"],
    },
    output: {
        hashFunction: "sha256",
    },
};

const commonWebpackConfig = () =>
    merge({}, baseClientWebpackConfig, commonOptions);

module.exports = commonWebpackConfig;
