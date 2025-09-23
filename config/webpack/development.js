// The source code including full typescript support is available at: 
// https://github.com/shakacode/react_on_rails_demo_ssr_hmr/blob/master/config/webpack/development.js

// development webpack configuration adjustments for React Refresh
import generateWebpackConfigs from './generateWebpackConfigs.js';
import ReactRefreshWebpackPlugin from '@pmmmwh/react-refresh-webpack-plugin';

const developmentEnvironmentOnly = (clientWebpackConfig) => {
  // React Refresh (Fast Refresh) setup - only when webpack-dev-server is running (HMR mode)
  // This matches the condition in generateWebpackConfigs.js and babel.config.js
  if (process.env.WEBPACK_SERVE) {
    clientWebpackConfig.plugins.push(
      new ReactRefreshWebpackPlugin({
        // Use default overlay configuration for better compatibility
      }),
    );
  }
};

export default generateWebpackConfigs(developmentEnvironmentOnly);
