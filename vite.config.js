import { defineConfig } from "vite";
import RubyPlugin from "vite-plugin-ruby";
import FullReload from "vite-plugin-full-reload";
import StimulusHMR from "vite-plugin-stimulus-hmr";
import ViteCompression from "vite-plugin-compression";
import Legacy from "vite-plugin-legacy-swc";
import postcssPresetEnv from 'postcss-preset-env';
import postcssFlexbugsFixes from 'postcss-flexbugs-fixes';
import cssnano from 'cssnano';

export default defineConfig({
  build: {
    minify: "terser",
    terserOptions: {
      ecma: 5,
      safari10: true,
    },
  },
  css: {
    postcss: {
      plugins: [
        postcssPresetEnv({
          stage: 3,
        }),
        postcssFlexbugsFixes(),
        cssnano({
          preset: 'default'
        })
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
    }),
    ViteCompression(),
  ],
});
