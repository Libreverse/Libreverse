import { defineConfig } from "vite";
import RubyPlugin from "vite-plugin-ruby";
import FullReload from "vite-plugin-full-reload";
import StimulusHMR from "vite-plugin-stimulus-hmr";
import Legacy from "vite-plugin-legacy-swc";
import postcssPresetEnv from "postcss-preset-env";
import postcssFlexbugsFixes from "postcss-flexbugs-fixes";
import cssnano from "cssnano";

export default defineConfig({
  build: {
    sourcemap: false,
  },
  css: {
    postcss: {
      plugins: [
        postcssPresetEnv({
          browsers: [
            "Chrome >= 32",
            "Edge >= 79",
            "Safari >= 8",
            "Firefox >= 24",
            "and_chr >= 129",
            "iOS >= 8",
            "and_ff >= 130",
          ],
          stage: 3,
        }),
        postcssFlexbugsFixes(),
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
    RubyPlugin(),
    FullReload(["config/routes.rb", "app/views/**/*"]),
    StimulusHMR(),
    Legacy({
      targets: [
        "Chrome >= 32",
        "Edge >= 79",
        "Safari >= 8",
        "Firefox >= 24",
        "and_chr >= 129",
        "iOS >= 8",
        "and_ff >= 130",
      ],
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
