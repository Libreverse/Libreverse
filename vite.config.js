import { defineConfig } from "vite";
import path from "node:path";
import { execSync } from "node:child_process";
import rubyPlugin from "vite-plugin-ruby";
import fullReload from "vite-plugin-full-reload";
import stimulusHMR from "vite-plugin-stimulus-hmr";
import babel from "vite-plugin-babel";
import postcssInlineRtl from "postcss-inline-rtl";
import cssnano from "cssnano";
import postcssUrl from "postcss-url";
import coffeescript from "./plugins/coffeescript.js";
import typehints from "./plugins/typehints.js";
import postcssRemoveRoot from "postcss-remove-root";
import cssMqpacker from "css-mqpacker";
import stylehacks from "stylehacks";
import postcssMqOptimize from "postcss-mq-optimize";
import autoprefixer from "autoprefixer";
import removePrefix from "./plugins/postcss-remove-prefix.js";
import nodePolyfills from "rollup-plugin-polyfill-node";
import legacy from "vite-plugin-legacy-swc";
import vitePluginBundleObfuscator from "vite-plugin-bundle-obfuscator";
import { purgePolyfills } from "unplugin-purge-polyfills";
import replacements from "@e18e/unplugin-replacements/vite";
import {
    allObfuscatorConfig,
    commonDefine,
    commonLegacyOptions,
    createBabelOptions,
    createCommonBuild,
    createEsbuildConfig,
    createOptimizeDepsForce,
    createTypehintPlugin,
    devViteSecurityHeaders,
} from "./config/vite/common.js";

export default defineConfig(({ mode }) => {
    const isDevelopment = mode === "development";

    const typehintPlugin = createTypehintPlugin(typehints);

    return {
        esbuild: createEsbuildConfig(isDevelopment),
        resolve: {
            extensions: [".js", ".json", ".coffee", ".scss", ".snappy", ".es6"],
            // Workaround for js-cookie packaging (dist folder not present in some installs)
            // Map to ESM source file so Vite can bundle successfully
            alias: {
                // Use explicit path into node_modules since package exports field hides src/*
                "js-cookie": path.resolve(
                    process.cwd(),
                    "node_modules/js-cookie/index.js",
                ),
                timeago_js: path.join(
                    execSync("bundle show timeago_js").toString().trim(),
                    "assets/javascripts",
                ),
                thredded_js: path.join(
                    execSync("bundle show thredded").toString().trim(),
                    "app/assets/javascripts",
                ),
                thredded_vendor: path.join(
                    execSync("bundle show thredded").toString().trim(),
                    "vendor/assets/javascripts",
                ),
            },
        },
        build: createCommonBuild({
            isDevelopment,
            rollupInput: {
                application: "app/javascript/application.js",
                emails: "app/stylesheets/emails.scss",
            },
        }),
        server: {
            hmr: { overlay: true }, // Enable error overlay in development
            headers: isDevelopment ? devViteSecurityHeaders() : {},
            fs: { strict: false }, // More lenient file system access for development
        },
        assetsInclude: ["**/*.snappy", "**/*.gguf", "**/*.wasm"],
        css: {
            preprocessorOptions: {
                scss: {
                    api: "modern-compiler",
                    includePaths: ["node_modules", "./node_modules"],
                },
            },
            postcss: {
                plugins: [
                    removePrefix(),
                    stylehacks({ lint: false }),
                    postcssInlineRtl(),
                    postcssUrl([
                        {
                            filter: "**/*.woff2",
                            url: "inline",
                            encodeType: "base64",
                            maxSize: 2147483647,
                        },
                        {
                            url: "inline",
                            maxSize: 2147483647,
                            encodeType: "encodeURIComponent",
                            optimizeSvgEncode: true,
                            ignoreFragmentWarning: true,
                        },
                    ]),
                    postcssRemoveRoot(),
                    cssMqpacker({
                        sort: true,
                    }),
                    postcssMqOptimize(),
                    cssnano({
                        preset: [
                            "advanced",
                            {
                                autoprefixer: false,
                                discardComments: {
                                    removeAllButCopyright: true,
                                },
                                discardUnused: true,
                                reduceIdents: true,
                                mergeIndents: true,
                                zindex: true,
                            },
                        ],
                    }),
                    autoprefixer(),
                ],
            },
        },
        define: commonDefine,
        optimizeDeps: {
            // Force inclusion of dependencies that might not be detected
            include: [
                "debounced",
                "foundation-sites",
                "what-input",
                "@fingerprintjs/botd",
                "@rails/ujs",
                "js-cookie",
                "@sentry/browser",
                "turbo_power",
                "@rails/activestorage",
                "stimulus_reflex",
                "cable_ready",
                "@rails/actioncable",
                "locomotive-scroll",
                "@rails/request.js",
                "stimulus-store",
                "@hotwired/turbo-rails",
                "leaflet",
                "leaflet.offline",
                "leaflet-ajax",
                "leaflet-spin",
                "leaflet-sleep",
                "leaflet.a11y",
                "leaflet.translate",
                "stimulus-use/hotkeys",
                "jquery",
            ],
            exclude: ["@hotwired/turbo"],
            // Force reoptimization in development
            ...createOptimizeDepsForce(isDevelopment),
        },
        plugins: [
            coffeescript(),
            nodePolyfills(),
            purgePolyfills.vite(),
            replacements(),
            legacy(commonLegacyOptions),
            babel(createBabelOptions(path)),
            rubyPlugin(),
            stimulusHMR(),
            fullReload([
                "config/routes.rb",
                "app/views/**/*",
                "app/javascript/src/**/*",
            ]),
            !isDevelopment
                ? vitePluginBundleObfuscator(allObfuscatorConfig)
                : null,
            !isDevelopment ? typehintPlugin : null,
        ],
    };
});
