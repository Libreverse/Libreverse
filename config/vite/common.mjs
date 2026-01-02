// Shared Vite config helpers used by both the Rails Vite dev server and Electron Forge.
// Keep this file dependency-free (besides Node builtins) so it can be imported from config files.

export const allObfuscatorConfig = {
    excludes: [],
    enable: true,
    log: true,
    autoExcludeNodeModules: true,
    threadPool: true,
    options: {
        compact: true,
        controlFlowFlattening: true,
        controlFlowFlatteningThreshold: 1,
        deadCodeInjection: false,
        debugProtection: false,
        debugProtectionInterval: 0,
        disableConsoleOutput: false,
        identifierNamesGenerator: "hexadecimal",
        log: false,
        numbersToExpressions: false,
        renameGlobals: false,
        selfDefending: true,
        simplify: true,
        splitStrings: false,
        ignoreImports: true,
        stringArray: true,
        stringArrayCallsTransform: true,
        stringArrayCallsTransformThreshold: 0.5,
        stringArrayEncoding: [],
        stringArrayIndexShift: true,
        stringArrayRotate: true,
        stringArrayShuffle: true,
        stringArrayWrappersCount: 1,
        stringArrayWrappersChainedCalls: true,
        stringArrayWrappersParametersMaxCount: 2,
        stringArrayWrappersType: "variable",
        stringArrayThreshold: 0.75,
        unicodeEscapeSequence: false,
    },
};

export function withInstrumentation(p) {
    let modified = 0;
    return {
        ...p,
        async transform(code, id) {
            const out = await p.transform.call(this, code, id);
            if (out && out.code && out.code !== code) modified += 1;
            return out;
        },
        buildEnd() {
            this.info(`[typehints] Files modified: ${modified}`);
            if (p.buildEnd) return p.buildEnd.call(this);
        },
    };
}

export function createTypehintPlugin(typehintsPluginFactory) {
    return withInstrumentation(
        typehintsPluginFactory({
            variableDocumentation: true,
            objectShapeDocumentation: true,
            maxObjectProperties: 6,
            enableCoercions: true,
            parameterHoistCoercions: false,
        }),
    );
}

export function createEsbuildConfig(isDevelopment) {
    return {
        target: "es2020", // Modern target
        keepNames: false,
        treeShaking: isDevelopment ? false : true, // Disable tree shaking in development for faster builds
        legalComments: isDevelopment ? "none" : "inline", // Skip legal comments in development
    };
}

// Shared development headers for Vite dev servers.
//
// These help when the renderer uses COEP/credentialless and embeds content from
// other local origins (different port), which can otherwise cause CORP/COEP
// blocking in Chromium/Electron.
export function devViteSecurityHeaders() {
    const headers = {
        "Cache-Control": "no-store, no-cache, must-revalidate, max-age=0",
        // Dev-only convenience; production builds should use stricter policies.
        // This allows the Vite renderer (https://localhost:5173) to embed the Rails
        // UI (https://localhost:3000) without CORP/COEP confusion.
        "Cross-Origin-Resource-Policy": "cross-origin",
    };

    // COEP makes the document cross-origin isolated and forces CORP/CORS rules
    // on embedded resources (including iframes). This is useful for features
    // like SharedArrayBuffer, but it can break the Electron dev shell when the
    // Rails UI is embedded from another origin/port.
    //
    // Enable explicitly when needed:
    //   VITE_ENABLE_COEP=1
    if (process.env.VITE_ENABLE_COEP === "1") {
        headers["Cross-Origin-Embedder-Policy"] = "credentialless";
    }

    return headers;
}

export function createTerserOptions(isDevelopment) {
    if (isDevelopment) return undefined;

    return {
        parse: {
            bare_returns: false,
            html5_comments: false,
            shebang: false,
            ecma: 2020, // Modern parsing
        },
        compress: {
            defaults: true,
            arrows: true, // Keep arrow functions
            arguments: true,
            booleans: true,
            booleans_as_integers: false,
            collapse_vars: true,
            comparisons: true,
            computed_props: true,
            conditionals: true,
            dead_code: true,
            directives: true,
            drop_console: true,
            drop_debugger: true,
            ecma: 2020, // Modern compression
            evaluate: true,
            expression: false,
            global_defs: {},
            hoist_funs: true,
            hoist_props: true,
            hoist_vars: true,
            if_return: true,
            inline: true,
            join_vars: true,
            keep_classnames: false,
            keep_fargs: true,
            keep_fnames: false,
            keep_infinity: false,
            loops: true,
            negate_iife: true,
            passes: 10,
            properties: true,
            pure_getters: "strict",
            pure_funcs: [
                "console.log",
                "console.info",
                "console.debug",
                "console.warn",
                "console.error",
                "console.trace",
                "console.dir",
                "console.dirxml",
                "console.group",
                "console.groupCollapsed",
                "console.groupEnd",
                "console.time",
                "console.timeEnd",
                "console.timeLog",
                "console.assert",
                "console.count",
                "console.countReset",
                "console.profile",
                "console.profileEnd",
                "console.table",
                "console.clear",
            ],
            reduce_vars: true,
            reduce_funcs: true,
            sequences: true,
            side_effects: true,
            switches: true,
            toplevel: true,
            top_retain: null,
            typeofs: true,
            unsafe: true,
            unsafe_arrows: true,
            unsafe_comps: true,
            unsafe_Function: true,
            unsafe_math: true,
            unsafe_symbols: true,
            unsafe_methods: true,
            unsafe_proto: true,
            unsafe_regexp: true,
            unsafe_undefined: true,
            unused: true,
        },
        mangle: {
            eval: false,
            keep_classnames: false,
            keep_fnames: false,
            reserved: [],
            toplevel: true,
            safari10: false,
        },
        format: {
            ascii_only: false,
            beautify: false,
            braces: false,
            comments: "some",
            ecma: 2020,
            indent_level: 0,
            inline_script: true,
            keep_numbers: false,
            keep_quoted_props: false,
            max_line_len: 0,
            quote_keys: false,
            preserve_annotations: false,
            safari10: false,
            semicolons: true,
            shebang: false,
            webkit: false,
            wrap_iife: false,
            wrap_func_args: false,
        },
    };
}

export function createRollupOutputConfig() {
    return {
        minifyInternalExports: true,
        inlineDynamicImports: false,
        compact: true,
        generatedCode: {
            preset: "es2015",
            arrowFunctions: true,
            constBindings: true,
            objectShorthand: true,
        },
    };
}

export function createCommonBuild({ isDevelopment, rollupInput } = {}) {
    const build = {
        cache: isDevelopment,
        rollupOptions: {
            output: createRollupOutputConfig(),
            external: [],
            treeshake: {
                moduleSideEffects: true,
                propertyReadSideEffects: false,
                tryCatchDeoptimization: false,
                unknownGlobalSideEffects: false,
            },
        },
        target: ["es2020", "edge88", "firefox78", "chrome87", "safari14"],
        modulePreload: { polyfill: true },
        cssCodeSplit: true,
        assetsInlineLimit: 500000,
        cssTarget: ["esnext"],
        sourcemap: false,
        chunkSizeWarningLimit: 2147483647,
        reportCompressedSize: false,
        minify: isDevelopment ? false : "terser",
        terserOptions: createTerserOptions(isDevelopment),
    };

    if (rollupInput) build.rollupOptions.input = rollupInput;

    return build;
}

export function createOptimizeDepsForce(isDevelopment) {
    return {
        force: isDevelopment && process.env.VITE_FORCE_DEPS === "true",
    };
}

export const commonDefine = {
    global: "globalThis",
};

export const commonLegacyOptions = {
    targets: ["chrome 142"],
    renderLegacyChunks: false,
    modernTargets: ["chrome 142"],
    modernPolyfills: true,
};

export function createBabelOptions(pathModule) {
    return {
        filter: (id) => {
            const base = pathModule.basename(id || "").toLowerCase();
            if (base === "textcomplete.min.js" || base === "ort-web.min.js") {
                return false;
            }
            return (
                !id.includes("@hotwired/stimulus") &&
                !id.includes("@huggingface/jinja") &&
                !id.includes("onnxruntime-web") &&
                /\.(js|coffee)$/.test(id)
            );
        },
        babelConfig: {
            ignore: ["node_modules/locomotive-scroll"],
            babelrc: false,
            configFile: false,
            plugins: [
                ["closure-elimination"],
                ["module:faster.js"],
                [
                    "object-to-json-parse",
                    {
                        minJSONStringSize: 1024,
                    },
                ],
            ],
        },
    };
}

export function createCommonCss(removePrefixPluginFactory) {
    return {
        preprocessorOptions: {
            scss: {
                api: "modern-compiler",
                includePaths: ["node_modules", "./node_modules"],
            },
        },
        postcss: {
            plugins: [
                removePrefixPluginFactory(),
                // The rest are configured by caller because they import different modules.
            ],
        },
    };
}
