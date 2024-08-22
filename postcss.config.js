module.exports = {
  plugins: [
    require('postcss-preset-env')({
      browsers: ['IE 11', 'last 2 versions'],
      stage: 3,
      features: {
        'custom-properties': false,
        'nesting-rules': true
      }
    }),
    require('autoprefixer'),
    require('cssnano')({
      preset: ['default', {
        discardComments: {
          removeAll: true,
        },
        normalizeWhitespace: true,
      }]
    })
  ]
}