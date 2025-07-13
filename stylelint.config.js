/* eslint-disable unicorn/no-null */
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
        "no-descending-specificity": null, // Temporarily disabled for complex glass fallback CSS
    },
};
