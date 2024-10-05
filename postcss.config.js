// mostly taken from my personal website codebase
module.exports = {
  plugins: [
    require("postcss-import")({ 
      extensions: [".scss", ".css"],
    }),
    require("@csstools/postcss-sass"),
    require("tailwindcss"),
    require("postcss-preset-env")({
      stage: 3,
      features: {
        "custom-properties": false,
      },
    }),
    require("postcss-flexbugs-fixes"),
    require("cssnano")({
      preset: [
        "default",
        {
          discardComments: { removeAll: true },
        },
      ],
    }),
  ],
};
