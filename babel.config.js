module.exports = {
  presets: [
    ['@babel/preset-env', {
      useBuiltIns: 'usage',
      corejs: 0,
      modules: false,
    }],
    '@babel/preset-typescript', // This will strip TypeScript types by default
  ],
};