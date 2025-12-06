const generateWebpackConfigs = require("./generateWebpackConfigs.js");

const productionEnvironmentOnly = () => {};

module.exports = generateWebpackConfigs(productionEnvironmentOnly);
