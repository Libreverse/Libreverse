const generateWebpackConfigs = require('./generateWebpackConfigs.cjs');

const developmentEnvOnly = (clientWebpackConfig) => {
  if (process.env.WEBPACK_SERVE) {
    const ReactRefreshWebpackPlugin = require('@pmmmwh/react-refresh-webpack-plugin');
    clientWebpackConfig.plugins.push(new ReactRefreshWebpackPlugin({}));
  }
};

module.exports = generateWebpackConfigs(developmentEnvOnly);
