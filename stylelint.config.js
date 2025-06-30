/* eslint-disable unicorn/no-null */
export default {
    extends: ["stylelint-config-standard-scss"],
    ignoreFiles: [
        "**/tailwind.scss",
        "**/application.scss",
        "**/gems/**",
        "vendor/**",
    ],
    rules: {
        "no-empty-source": undefined,
    },
};
