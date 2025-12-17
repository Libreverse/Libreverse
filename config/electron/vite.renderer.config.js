import { defineConfig } from "vite";
import path from "node:path";
import fs from "node:fs";
import { execSync } from "node:child_process";
import babel from "vite-plugin-babel";
import postcssInlineRtl from "postcss-inline-rtl";
import cssnano from "cssnano";
import postcssUrl from "postcss-url";
import coffeescript from "../../plugins/coffeescript.js";
import typehints from "../../plugins/typehints.js";
import postcssRemoveRoot from "postcss-remove-root";
import cssMqpacker from "css-mqpacker";
import stylehacks from "stylehacks";
import postcssMqOptimize from "postcss-mq-optimize";
import autoprefixer from "autoprefixer";
import removePrefix from "../../plugins/postcss-remove-prefix.js";
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
} from "../vite/common.js";

export default defineConfig(({ mode }) => {
    const isDevelopment = mode === "development";

    const devHttps = (() => {
        if (!isDevelopment) return undefined;

        const certDir =
            process.env.VITE_DEV_CERT_DIR ||
            path.join(process.cwd(), "tmp", "vite-dev-certs");
        const certPath = path.join(certDir, "localhost.pem");
        const keyPath = path.join(certDir, "localhost-key.pem");

        try {
            fs.mkdirSync(certDir, { recursive: true });
        } catch {
            // ignore
        }

        if (!fs.existsSync(certPath) || !fs.existsSync(keyPath)) {
            try {
                execSync(
                    `mkcert -cert-file "${certPath}" -key-file "${keyPath}" localhost 127.0.0.1 ::1`,
                    { stdio: "ignore" },
                );
            } catch {
                // If mkcert isn't available, fall back to HTTPS without custom certs.
                return true;
            }
        }

        try {
            return {
                cert: fs.readFileSync(certPath),
                key: fs.readFileSync(keyPath),
            };
        } catch {
            return true;
        }
    })();

    const typehintPlugin = createTypehintPlugin(typehints);

    return {
        esbuild: createEsbuildConfig(isDevelopment),
        resolve: {
            extensions: [".js", ".json", ".coffee", ".scss", ".snappy", ".es6"],
        },
        build: createCommonBuild({ isDevelopment }),
        server: {
            hmr: { overlay: true }, // Enable error overlay in development
            https: devHttps,
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
        optimizeDeps: createOptimizeDepsForce(isDevelopment),
        plugins: [
            coffeescript(),
            nodePolyfills(),
            purgePolyfills.vite(),
            replacements(),
            legacy(commonLegacyOptions),
            babel(createBabelOptions(path)),
            !isDevelopment
                ? vitePluginBundleObfuscator(allObfuscatorConfig)
                : null,
            !isDevelopment ? typehintPlugin : null,
        ],
    };
});
