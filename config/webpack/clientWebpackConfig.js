require("v8-compile-cache");
const commonWebpackConfig = require("./commonWebpackConfig.js");

const configureClient = () => {
    const clientConfig = commonWebpackConfig();
    delete clientConfig.entry["server-bundle"];
    clientConfig.output = clientConfig.output || {};
    return clientConfig;
};

module.exports = configureClient;
