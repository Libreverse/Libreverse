const generateWebpackConfigs = require("./generateWebpackConfigs.cjs");

const developmentEnvironmentOnly = (clientWebpackConfig) => {
    if (process.env.WEBPACK_SERVE) {
        const ReactRefreshWebpackPlugin = require("@pmmmwh/react-refresh-webpack-plugin");
        clientWebpackConfig.plugins.push(new ReactRefreshWebpackPlugin({}));
    }
};

module.exports = generateWebpackConfigs(developmentEnvironmentOnly);
