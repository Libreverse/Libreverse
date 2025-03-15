import { defineConfig } from "vite";
import rubyPlugin from "vite-plugin-ruby";
import fullReload from "vite-plugin-full-reload";
import stimulusHMR from "vite-plugin-stimulus-hmr";
import legacy from "vite-plugin-legacy-swc";
import vitePluginCompression from "vite-plugin-compression";
import postcssPresetEnv from "postcss-preset-env";
import postcssFlexbugsFixes from "postcss-flexbugs-fixes";
import postcssInlineRtl from "postcss-inline-rtl";
import cssnano from "cssnano";
import { constants } from "node:zlib";

export default defineConfig(({ mode }) => {
    const isDevelopment = mode === "development";

    return {
        build: {
            sourcemap: false,
            cache: !isDevelopment,
            rollupOptions: {
                output: {
                    entryFileNames: isDevelopment
                        ? "[name].js"
                        : "[name]-[hash].js",
                    chunkFileNames: isDevelopment
                        ? "[name].js"
                        : "[name]-[hash].js",
                    assetFileNames: isDevelopment
                        ? "[name].[ext]"
                        : "[name]-[hash].[ext]",
                },
            },
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
                      Pragma: "no-cache",
                      Expires: "Fri, 01 Jan 1990 00:00:00 GMT",
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
            stimulusHMR(),
            legacy({
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
            vitePluginCompression({
                algorithm: "brotliCompress",
                compressionOptions: {
                    params: {
                        [constants.BROTLI_PARAM_QUALITY]: 11,
                        [constants.BROTLI_PARAM_LGWIN]: 22,
                        [constants.BROTLI_PARAM_LGBLOCK]: 0,
                        [constants.BROTLI_PARAM_MODE]:
                            constants.BROTLI_MODE_TEXT,
                    },
                },
                filter: /\.(js|css|svg|json|html)$/i,
                threshold: 0,
                ext: ".br",
                deleteOriginFile: false,
            }),
            vitePluginCompression({
                algorithm: "gzip",
                compressionOptions: {
                    level: 6,
                },
                filter: /\.(js|css|svg|json|html)$/i,
                threshold: 0,
                ext: ".gz",
                deleteOriginFile: false,
            }),
        ],
    };
});
