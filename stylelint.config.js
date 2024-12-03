export default {
  extends: ["stylelint-config-standard-scss"],
  plugins: ["stylelint-sass-render-errors"],
  rules: {
    "plugin/sass-render-errors": true,
  },
};
