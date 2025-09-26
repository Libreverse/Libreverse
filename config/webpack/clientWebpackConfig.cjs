const commonWebpackConfig = require("./commonWebpackConfig.cjs");

const configureClient = () => {
    const clientConfig = commonWebpackConfig();
    delete clientConfig.entry["server-bundle"];
    clientConfig.output = clientConfig.output || {};
    return clientConfig;
};

module.exports = configureClient;
