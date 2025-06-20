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
            cssCodeSplit: true,
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
                renderLegacyChunks: true,
                modernPolyfills: true,
                terserOptions: {
                    ecma: 5,
                    warnings: true,
                    mangle: {
                        properties: false,
                        safari10: true,
                        toplevel: false,
                    },
                    compress: {
                        defaults: true,
                        arrows: false,
                        booleans_as_integers: false,
                        booleans: true,
                        collapse_vars: true,
                        comparisons: true,
                        conditionals: true,
                        dead_code: true,
                        drop_console: false,
                        directives: true,
                        evaluate: true,
                        hoist_funs: true,
                        if_return: true,
                        join_vars: true,
                        keep_fargs: false,
                        loops: true,
                        negate_iife: true,
                        passes: 3,
                        properties: true,
                        reduce_vars: true,
                        sequences: true,
                        side_effects: true,
                        toplevel: false,
                        typeofs: false,
                        unused: true,
                    },
                    output: {
                        comments: /(?:copyright|licence|©)/i,
                        beautify: false,
                        semicolons: true,
                    },
                    keep_classnames: false,
                    keep_fnames: false,
                    safari10: true,
                    module: true,
                },
            }),
        ],
    };
});
