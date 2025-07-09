import { defineConfig } from "vite";
import rubyPlugin from "vite-plugin-ruby";
import fullReload from "vite-plugin-full-reload";
import stimulusHMR from "vite-plugin-stimulus-hmr";
import postcssInlineRtl from "postcss-inline-rtl";
import cssnano from "cssnano";
import * as coffee from "coffeescript";
import postcssUrl from "postcss-url";

export default defineConfig(({ mode }) => {
    const isDevelopment = mode === "development";

    return {
        esbuild: {
            target: "esnext",
            keepNames: false,
            treeShaking: true,
            legalComments: "inline",
        },
        resolve: {
            extensions: [".js", ".json", ".coffee", ".scss"],
            alias: {
                "~": "/node_modules/",
            },
        },
        build: {
            cache: !isDevelopment,
            rollupOptions: {
                input: {
                    application: "app/javascript/application.js",
                    emails: "app/stylesheets/emails.scss",
                },
                output: {
                    minifyInternalExports: true,
                    inlineDynamicImports: false,
                    compact: true,
                    generatedCode: {
                        preset: "es2015", // Rollup only supports 'es5' or 'es2015'
                        arrowFunctions: true,
                        constBindings: true,
                        objectShorthand: true,
                    },
                },

                external: [],
                treeshake: {
                    moduleSideEffects: false,
                    propertyReadSideEffects: false,
                    tryCatchDeoptimization: false,
                    unknownGlobalSideEffects: false,
                },
            },
            target: ["esnext"],
            modulePreload: { polyfill: true },
            cssCodeSplit: false,
            assetsInlineLimit: 2147483647,
            cssTarget: ["esnext"],
            sourcemap: false,
            chunkSizeWarningLimit: 2147483647,
            reportCompressedSize: false,
            minify: "terser",
            terserOptions: {
                parse: {
                    bare_returns: false,
                    html5_comments: false,
                    shebang: false,
                },
                compress: {
                    defaults: true,
                    arrows: false,
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
                    ecma: 5,
                    evaluate: true,
                    expression: false,
                    global_defs: {},
                    hoist_funs: true,
                    hoist_props: true,
                    hoist_vars: false,
                    if_return: true,
                    inline: true,
                    join_vars: true,
                    keep_classnames: false,
                    keep_fargs: true,
                    keep_fnames: false,
                    keep_infinity: false,
                    loops: true,
                    negate_iife: true,
                    passes: 3,
                    properties: true,
                    pure_getters: "strict",
                    pure_funcs: [
                        "console.log",
                        "console.info",
                        "console.debug",
                        "console.trace",
                    ],
                    reduce_vars: true,
                    reduce_funcs: true,
                    sequences: true,
                    side_effects: true,
                    switches: true,
                    toplevel: false,
                    top_retain: null,
                    typeofs: true,
                    unsafe: false,
                    unsafe_arrows: false,
                    unsafe_comps: false,
                    unsafe_Function: false,
                    unsafe_math: false,
                    unsafe_symbols: false,
                    unsafe_methods: false,
                    unsafe_proto: false,
                    unsafe_regexp: false,
                    unsafe_undefined: false,
                    unused: true,
                },
                mangle: {
                    eval: false,
                    keep_classnames: false,
                    keep_fnames: false,
                    reserved: [],
                    toplevel: false,
                    safari10: true,
                },
                format: {
                    ascii_only: false,
                    beautify: false,
                    braces: false,
                    comments: "some",
                    ecma: 5,
                    indent_level: 4,
                    inline_script: true,
                    keep_numbers: false,
                    keep_quoted_props: false,
                    max_line_len: 0,
                    quote_keys: false,
                    preserve_annotations: false,
                    safari10: true,
                    semicolons: true,
                    shebang: false,
                    webkit: true,
                    wrap_iife: false,
                    wrap_func_args: false,
                },
            },
        },
        server: {
            hmr: { overlay: false },
            headers: isDevelopment
                ? {
                      "Cache-Control":
                          "no-store, no-cache, must-revalidate, max-age=0",
                  }
                : {},
            fs: { strict: true },
        },
        css: {
            preprocessorOptions: {
                scss: {
                    api: "modern-compiler",
                    includePaths: ["node_modules", "./node_modules"],
                },
            },
            postcss: {
                plugins: [
                    postcssUrl({ url: "inline", maxSize: 2147483647 }),
                    postcssInlineRtl(),
                    cssnano({
                        preset: [
                            "advanced",
                            {
                                autoprefixer: false,
                                discardComments: {
                                    removeAllButCopyright: true,
                                },
                                normalizeString: true,
                                normalizeUrl: true,
                                normalizeCharset: true,
                            },
                        ],
                    }),
                ],
            },
        },
        define: {
            global: "globalThis",
        },
        plugins: [
            rubyPlugin(),
            fullReload(["config/routes.rb", "app/views/**/*"]),
            {
                name: "vite-plugin-coffeescript",
                transform(code, id) {
                    if (id.endsWith(".coffee")) {
                        try {
                            const compiled = coffee.compile(code, {
                                filename: id,
                                bare: true,
                            });
                            return {
                                code:
                                    typeof compiled === "string"
                                        ? compiled
                                        : compiled.js,
                                map: undefined,
                            };
                        } catch (error) {
                            throw error;
                        }
                    }
                    return undefined;
                },
            },
            stimulusHMR(),
        ],
    };
});
