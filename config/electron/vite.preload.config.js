import { defineConfig } from "vite";
import path from "node:path";
import babel from "vite-plugin-babel";
import coffeescript from "../../plugins/coffeescript.js";
import typehints from "../../plugins/typehints.js";
import vitePluginBundleObfuscator from "vite-plugin-bundle-obfuscator";
import { bytecodePlugin } from "vite-plugin-bytecode2";
import { purgePolyfills } from "unplugin-purge-polyfills";
import replacements from "@e18e/unplugin-replacements/vite";

// All configurations
const allObfuscatorConfig = {
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

function withInstrumentation(p) {
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

export default defineConfig(({ mode }) => {
    const isDevelopment = mode === "development";

    const typehintPlugin = withInstrumentation(
        typehints({
            variableDocumentation: true,
            objectShapeDocumentation: true,
            maxObjectProperties: 6,
            enableCoercions: true,
            parameterHoistCoercions: false,
        }),
    );

    return {
        esbuild: {
            target: "es2020", // Modern target
            keepNames: false,
            treeShaking: isDevelopment ? false : true, // Disable tree shaking in development for faster builds
            legalComments: isDevelopment ? "none" : "inline", // Skip legal comments in development
        },
        resolve: {
            extensions: [".js", ".coffee"],
        },
        build: {
            cache: isDevelopment, // Enable cache in development for faster rebuilds
            rollupOptions: {
                output: {
                    minifyInternalExports: true,
                    inlineDynamicImports: false,
                    compact: true,
                    generatedCode: {
                        preset: "es2015", // Modern output
                        arrowFunctions: true,
                        constBindings: true,
                        objectShorthand: true,
                    },
                },
                external: [],
                treeshake: {
                    moduleSideEffects: true,
                    propertyReadSideEffects: false,
                    tryCatchDeoptimization: false,
                    unknownGlobalSideEffects: false,
                },
            },
            target: ["es2020", "edge88", "firefox78", "chrome87", "safari14"], // Modern browsers
            modulePreload: { polyfill: true },
            cssCodeSplit: true,
            assetsInlineLimit: 500000,
            cssTarget: ["esnext"],
            sourcemap: false,
            chunkSizeWarningLimit: 2147483647,
            reportCompressedSize: false,
            minify: isDevelopment ? false : "terser",
            terserOptions: isDevelopment
                ? undefined
                : {
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
                          drop_console: true, // Re-enabled to drop console statements
                          drop_debugger: true, // Re-enabled to drop debugger statements
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
                          ], // Re-added console methods as pure functions
                          reduce_vars: true,
                          reduce_funcs: true,
                          sequences: true,
                          side_effects: true,
                          switches: true,
                          toplevel: true,
                          top_retain: null,
                          typeofs: true,
                          unsafe: true,
                          unsafe_arrows: true, // Allow arrow function optimizations
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
                          safari10: false, // No need for Safari 10 workarounds
                      },
                      format: {
                          ascii_only: false,
                          beautify: false,
                          braces: false,
                          comments: "some",
                          ecma: 2020, // Modern output format
                          indent_level: 0,
                          inline_script: true,
                          keep_numbers: false,
                          keep_quoted_props: false,
                          max_line_len: 0,
                          quote_keys: false,
                          preserve_annotations: false,
                          safari10: false, // No Safari 10 workarounds
                          semicolons: true,
                          shebang: false,
                          webkit: false, // No need for webkit workarounds
                          wrap_iife: false,
                          wrap_func_args: false,
                      },
                  },
        },
        server: {
            fs: { strict: false }, // More lenient file system access for development
        },
        define: {
            global: "globalThis",
        },
        optimizeDeps: {
            // Force reoptimization in development
            force: isDevelopment && process.env.VITE_FORCE_DEPS === "true",
        },
        plugins: [
            coffeescript(),
            purgePolyfills.vite(),
            replacements(),
            babel({
                filter: (id) => {
                    // Skip processing for hotwired/stimulus and for the prebuilt textconvert.min.js bundle (case-insensitive)
                    const base = path.basename(id || "").toLowerCase();
                    if (
                        base === "textcomplete.min.js" ||
                        base === "ort-web.min.js"
                    ) {
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
            }),
            !isDevelopment
                ? vitePluginBundleObfuscator(allObfuscatorConfig)
                : null,
            !isDevelopment ? typehintPlugin : null,
            !isDevelopment
                ? bytecodePlugin({
                      chunkAlias: [],
                      transformArrowFunctions: true,
                      removeBundleJS: true,
                      protectedStrings: [],
                  })
                : null,
        ],
    };
});
