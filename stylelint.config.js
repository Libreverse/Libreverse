export default {
    extends: ["stylelint-config-standard-scss"],
    ignoreFiles: [
        "**/tailwind.scss",
        "**/application.scss",
        "**/gems/**",
        "vendor/**",
        ".codeql/**",
        "node_modules/**",
        "app/stylesheets/thredded/**",
        "app/stylesheets/blog.scss",
    ],
    rules: {
        "no-empty-source": undefined,
        "scss/at-extend-no-missing-placeholder": undefined,
        "no-descending-specificity": undefined,
        "media-feature-name-no-unknown": null,
    },
};
