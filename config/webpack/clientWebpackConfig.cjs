const commonWebpackConfig = require('./commonWebpackConfig.cjs');

const configureClient = () => {
  const clientConfig = commonWebpackConfig();
  delete clientConfig.entry['server-bundle'];
  return clientConfig;
};

module.exports = configureClient;
