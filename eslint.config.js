import unicorn from "eslint-plugin-unicorn";
import globals from "globals";
import path from "node:path";
import { fileURLToPath } from "node:url";
import js from "@eslint/js";
import { FlatCompat } from "@eslint/eslintrc";
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const compat = new FlatCompat({
    baseDirectory: __dirname,
    recommendedConfig: js.configs.recommended,
    allConfig: js.configs.all,
});

export default [
    {
        ignores: [
            "app//builds**",
            "**/node_modules/",
            "**/vendor/",
            "**/tmp/",
            "**.config.js",
            "public/**",
            "app//libs/**",
        ],
    },
    ...compat.extends("eslint:recommended", "plugin:unicorn/recommended"),
    {
        plugins: {
            unicorn,
        },
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
        },
    },
    // Add Jest environment for test files
    {
        files: ["test/javascript/**/*.js"],
        languageOptions: {
            globals: {
                ...globals.jest,
                ...globals.browser,
            },
        },
        rules: {
            "no-undef": "off", // Disable no-undef for test files to allow Jest globals
        },
    },
];
