// mostly taken from my personal website codebase
module.exports = {
  plugins: [
    require("postcss-import")({
      extensions: [".scss", ".css"],
    }),
    require("@csstools/postcss-sass"),
    require("postcss-inline-rtl"),
    require("postcss-preset-env")({
      stage: 0,
      autoprefixer: true,
      features: {
        "custom-properties": false,
      },
    }),
    require("postcss-flexbugs-fixes"),
    require("cssnano")({
      preset: [
        "advanced",
        {
          //get rid of the autoprefixer
          autoprefixer: false,

          // Discard all comments that are not used for licensing or important notices
          discardComments: { removeAll: true },

          // Aggressively merge properties when safe
          mergeLonghand: true,

          // Reduce calc() where possible
          calc: { precision: 2 }, // Reduce precision to save bytes

          // Convert colors to shorter format where possible
          colormin: true,

          // Aggressively reduce z-index values outside of @keyframes if possible
          zindex: true,

          // Normalize string, url, and number values
          normalizeString: true,
          normalizeUrl: true,
          normalizeCharset: true,
          mergeRules: true,
          discardUnused: { fontFace: true, keyframes: true },
          svgo: {
            plugins: [
              { removeViewBox: false }, // Can break SVGs, use with caution
              { removeDimensions: true },
            ],
          },
          convertValues: { length: true },
        },
      ],
    }),
  ],
};
