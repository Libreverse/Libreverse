import { defineConfig } from "vite";
import rubyPlugin from "vite-plugin-ruby";
import fullReload from "vite-plugin-full-reload";
import stimulusHMR from "vite-plugin-stimulus-hmr";
import legacy from "vite-plugin-legacy-swc";
import postcssPresetEnv from "postcss-preset-env";
import postcssFlexbugsFixes from "postcss-flexbugs-fixes";
import postcssInlineRtl from "postcss-inline-rtl";
import cssnano from "cssnano";

export default defineConfig({
  build: {
    sourcemap: false,
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
    legacy({
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
    }),
  ],
});
