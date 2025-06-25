import { defineConfig } from "vite";
import rubyPlugin from "vite-plugin-ruby";
import fullReload from "vite-plugin-full-reload";
import stimulusHMR from "vite-plugin-stimulus-hmr";
import legacy from "@vitejs/plugin-legacy";
import postcssPresetEnv from "postcss-preset-env";
import postcssFlexbugsFixes from "postcss-flexbugs-fixes";
import postcssInlineRtl from "postcss-inline-rtl";
import cssnano from "cssnano";
import coffee from "vite-plugin-coffee";
import postcssUrl from "postcss-url";

export default defineConfig(({ mode }) => {
    const isDevelopment = mode === "development";

    return {
        resolve: {
            extensions: [".js", ".coffee", ".scss"],
        },
        build: {
            sourcemap: false,
            cache: !isDevelopment,
            cssCodeSplit: false,
            rollupOptions: {
                input: {
                    application: "app/javascript/application.js",
                    emails: "app/stylesheets/emails.scss",
                },
                output: {
                    inlineDynamicImports: false,
                    manualChunks: false,
                    entryFileNames: isDevelopment ? "[name].js" : "[name].js",
                    chunkFileNames: isDevelopment ? "[name].js" : "[name].js",
                    assetFileNames: isDevelopment
                        ? "[name].[ext]"
                        : "[name].[ext]",
                },
            },
            assetsInlineLimit: 1000000,
        },
        server: {
            hmr: { overlay: false },
            fs: {
                strict: true,
            },
            headers: isDevelopment
                ? {
                      "Cache-Control":
                          "no-store, no-cache, must-revalidate, max-age=0",
                  }
                : {},
        },
        css: {
            preprocessorOptions: {
                scss: {
                    api: "modern-compiler",
                },
            },
            postcss: {
                plugins: [
                    postcssPresetEnv({ stage: 3 }),
                    postcssFlexbugsFixes(),
                    postcssUrl({ url: "inline", maxSize: 50000 }), // Match a reasonable Vite limit
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
        plugins: [
            rubyPlugin(),
            fullReload(["config/routes.rb", "app/views/**/*"]),
            coffee({
                jsx: false,
            }),
            stimulusHMR(),
            legacy({
                // if you disable renderlegacychunks, you can remove the alt js bundle and the ruby gem
                // this also allows use of the swc version
                renderLegacyChunks: false,
                modernPolyfills: true,
                terserOptions: {
                parse: {
                    bare_returns: false,
                    html5_comments: false,
                    shebang: false,
                },
                compress: {
                    defaults: true,
                    arrows: true,
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
                    ecma: 2015,
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
                    passes: 3,
                    properties: true,
                    pure_getters: "strict",
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
                    properties: {
                        builtins: false,
                        debug: false,
                        keep_quoted: "strict",
                        reserved: [],
                    },
                },
                format: {
                    ascii_only: false,
                    beautify: false,
                    braces: false,
                    comments: "some",
                    ecma: 2015,
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
            }),
        ],
    };
});
