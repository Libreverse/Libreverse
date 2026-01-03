// NOTE: Do NOT load v8-compile-cache in this config.
// Under Node 25, it can break Vite's CJS shim (vite/index.cjs) which uses dynamic import,
// leading to: ERR_VM_DYNAMIC_IMPORT_CALLBACK_MISSING.
import { defineConfig } from "vite";
import path from "node:path";
import babel from "vite-plugin-babel";
import coffeescript from "../../plugins/coffeescript.mjs";
import typehints from "../../plugins/typehints.mjs";
import vitePluginBundleObfuscator from "vite-plugin-bundle-obfuscator";
import { bytecodePlugin } from "vite-plugin-bytecode2";
import { purgePolyfills } from "unplugin-purge-polyfills";
import replacements from "@e18e/unplugin-replacements/vite";
import {
    allObfuscatorConfig,
    commonDefine,
    createBabelOptions,
    createCommonBuild,
    createEsbuildConfig,
    createOptimizeDepsForce,
    createTypehintPlugin,
} from "../vite/common.js";

export default defineConfig(({ mode }) => {
    const isDevelopment = mode === "development";

    const typehintPlugin = createTypehintPlugin(typehints);

    return {
        esbuild: createEsbuildConfig(isDevelopment),
        resolve: {
            extensions: [".js", ".coffee"],
        },
        build: createCommonBuild({ isDevelopment }),
        server: {
            fs: { strict: false }, // More lenient file system access for development
        },
        define: commonDefine,
        optimizeDeps: createOptimizeDepsForce(isDevelopment),
        plugins: [
            coffeescript(),
            purgePolyfills.vite(),
            replacements(),
            babel(createBabelOptions(path)),
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
