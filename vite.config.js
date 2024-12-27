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
import { sassFalse } from "sass-embedded";

export default defineConfig({
  build: {
    sourcemap: false,
    terserOptions: {
      ecma: 5,
      warnings: true,
      mangle: {
        properties: false,
        safari10: true,
        toplevel: false, // Disable toplevel mangling for legacy compatibility
      },
      compress: {
        defaults: true,
        arrows: false, // Disable arrow function compression for legacy compatibility
        booleans_as_integers: false, // Disable boolean as integers for legacy compatibility
        booleans: true,
        collapse_vars: true,
        comparisons: true,
        conditionals: true,
        dead_code: true,
        drop_console: sassFalse,
        directives: true,
        evaluate: true,
        hoist_funs: true,
        if_return: true,
        join_vars: true,
        keep_fargs: false, // Drop unused function arguments
        loops: true,
        negate_iife: true,
        passes: 3, // Additional passes can catch more opportunities for compression
        properties: true,
        reduce_vars: true,
        sequences: true,
        side_effects: true, // But be careful, this might remove functions with no apparent side effects
        toplevel: false, // Disable toplevel compression for legacy compatibility
        typeofs: false, // Disable typeof compression for legacy compatibility
        unused: true, // Drop unused variables and functions
      },
      output: {
        comments: /(?:copyright|©)/i,
        beautify: false,
        semicolons: true,
      },
      keep_classnames: false,
      keep_fnames: false,
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
          [constants.BROTLI_PARAM_LGWIN]: 22,
          [constants.BROTLI_PARAM_LGBLOCK]: 0,
          [constants.BROTLI_PARAM_MODE]: constants.BROTLI_MODE_TEXT,
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
});
