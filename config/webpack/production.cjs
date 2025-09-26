const generateWebpackConfigs = require("./generateWebpackConfigs.cjs");

const productionEnvironmentOnly = () => {};

module.exports = generateWebpackConfigs(productionEnvironmentOnly);
