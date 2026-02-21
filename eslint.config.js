import unicorn from "eslint-plugin-unicorn";
import globals from "globals";
import js from "@eslint/js";
import jestPlugin from "eslint-plugin-jest";
// Flat config: use flat-ready presets
const baseConfigs = [
    js.configs.recommended,
    unicorn.configs["flat/recommended"],
];

export default [
    {
        ignores: [
            "app//builds**",
            "app/assets/builds/**",
            "**/node_modules/",
            "**/vendor/",
            "**/tmp/",
            "**.config.js",
            "public/**",
            "app//libs/**",
            "coverage/**",
            ".vite/**",
            "dist/**",
            "**/gems/**",
            "**/haml_lint*/**",
            "**/openid_connect*/**",
            ".codeql/**",
            "**/iodine*/**",
            "log/**",
            "storage/**",
            "config/**",
            "**/generated/**",
        ],
    },
    ...baseConfigs,
    {
        languageOptions: {
            globals: {
                ...globals.browser,
            },

            ecmaVersion: "latest",
            sourceType: "module",
        },

        rules: {
            "unicorn/filename-case": "off",
            "unicorn/no-anonymous-default-export": "off",
            "unicorn/no-empty-file": "off",
            "unicorn/no-document-cookie": "off",
            "unicorn/prefer-top-level-await": "off",
        },
    },
    // Updated Jest test configuration
    {
        ...jestPlugin.configs["flat/recommended"],
        files: ["test/javascript/**/*.js"],
        languageOptions: {
            globals: {
                ...globals.jest,
                ...globals.browser,
                ...globals.node,
            },
            parserOptions: {
                ecmaVersion: "latest",
                sourceType: "module",
            },
        },
    },
];
