export default [
    {
        ignores: [
            "**/.git/**",
            "**/.vscode/**",
            "**/node_modules/**",
            "**/dist/**",
            "**/build/**",
            "**/vendor/**",
            "**/vite-dev/**",
            "**/public/vite-dev/**",
            "**/public/vite/**",
            "**/public/assets/**",
            "**/*.generated.js",
            "**/*.min.js",
            "**/*-legacy-*.js",
            "**/*.bundle.js",
            "**/coverage/**",
            "**/tmp/**",
            "**/app/builds/**",
            "**/app/libs/**",
        ],
    },
    {
        languageOptions: {
            ecmaVersion: "latest",
            sourceType: "module",
            globals: {
                document: "readonly",
                window: "readonly",
                console: "readonly",
                navigator: "readonly",
                fetch: "readonly",
                Headers: "readonly",
                Request: "readonly",
                Response: "readonly",
                URL: "readonly",
                URLSearchParams: "readonly",
                setTimeout: "readonly",
                clearTimeout: "readonly",
                setInterval: "readonly",
                clearInterval: "readonly",
                requestAnimationFrame: "readonly",
                cancelAnimationFrame: "readonly",
                FormData: "readonly",
                HTMLElement: "readonly",
                CustomEvent: "readonly",
                Event: "readonly",
                Element: "readonly",
                Node: "readonly",
                NodeList: "readonly",
                XMLHttpRequest: "readonly",
                WebSocket: "readonly",
                location: "readonly",
                localStorage: "readonly",
                sessionStorage: "readonly",
                history: "readonly",
                IntersectionObserver: "readonly",
                MutationObserver: "readonly",
                ResizeObserver: "readonly",
                DOMParser: "readonly",
                XMLSerializer: "readonly",
                File: "readonly",
                Blob: "readonly",
                FileReader: "readonly",
                MouseEvent: "readonly",
                KeyboardEvent: "readonly",
                btoa: "readonly",
                atob: "readonly",
                alert: "readonly",
                confirm: "readonly",
                prompt: "readonly",
            },
        },
        rules: {
            "no-console": "off",
            "no-unused-vars": "warn",
        },
    },
    // Test files specific rules
    {
        files: [
            "**/*.test.js",
            "**/__tests__/**/*.js",
            "**/__mocks__/**/*.js",
            "**/jest/*.js",
            "**/test/javascript/**/*.js",
        ],
        languageOptions: {
            // Add Jest globals
            globals: {
                jest: "readonly",
                describe: "readonly",
                it: "readonly",
                expect: "readonly",
                beforeEach: "readonly",
                afterEach: "readonly",
                beforeAll: "readonly",
                afterAll: "readonly",
                test: "readonly",
                mockImplementation: "readonly",
                mockReturnValue: "readonly",
                mockResolvedValue: "readonly",
                mockRejectedValue: "readonly",
            },
        },
        rules: {
            "no-undef": "off",
        },
    },
];
