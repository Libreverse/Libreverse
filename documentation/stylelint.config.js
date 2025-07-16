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
    },
};
