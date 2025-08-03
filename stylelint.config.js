export default {
    extends: ["stylelint-config-standard-scss"],
    ignoreFiles: [
        "**/tailwind.scss",
        "**/application.scss",
        "**/gems/**",
        "vendor/**",
        ".codeql/**",
    ],
    rules: {
        "no-empty-source": undefined,
        "scss/at-extend-no-missing-placeholder": undefined,
        "no-descending-specificity": undefined,
        "media-feature-name-no-unknown": null,
    },
};
