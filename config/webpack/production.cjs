const generateWebpackConfigs = require('./generateWebpackConfigs.cjs');

const productionEnvOnly = () => {};

module.exports = generateWebpackConfigs(productionEnvOnly);
