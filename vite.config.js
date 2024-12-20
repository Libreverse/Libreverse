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

export default defineConfig({
  build: {
    sourcemap: false,
    terserOptions: {
      ecma: 5,
      output: {
        comments: /@license|@preserve|^!/,
        beautify: false,
        semicolons: true,
      },
      safari10: true,
      module: true,
    },
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
              discardComments: { removeAllButCopyright: true },
              colormin: true,
              normalizeString: true,
              normalizeUrl: true,
              normalizeCharset: true,
              convertValues: { length: true },
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
    legacy(),
    vitePluginCompression({
      algorithm: "brotliCompress",
      compressionOptions: {
        params: {
          [constants.BROTLI_PARAM_QUALITY]: 11,
        },
      },
      filter: (file) => /\.(js|css|svg|json)$/i.test(file),
      threshold: 0,
      ext: ".br",
      deleteOriginFile: false,
    }),
    vitePluginCompression({
      algorithm: "gzip",
      filter: (file) => /\.(js|css|svg|json)$/i.test(file),
      threshold: 0,
      ext: ".gz",
      deleteOriginFile: false,
    }),
  ],
});
