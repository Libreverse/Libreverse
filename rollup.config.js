//att: xAI Grok 2
import resolve from "@rollup/plugin-node-resolve";
import commonjs from "@rollup/plugin-commonjs";
import babel from "@rollup/plugin-babel";
import terser from "@rollup/plugin-terser";

export default {
  input: "app/javascript/application.js",
  output: {
    file: "app/assets/builds/application.js",
    inlineDynamicImports: true,
    sourcemap: false,
  },
  plugins: [
    resolve({
      extensions: ['.js', '.ts'],
    }),
    commonjs({
      include: 'node_modules/**',
    }),
    babel({
      babelHelpers: 'bundled',
      configFile: './babel.config.js',
      exclude: 'node_modules/**',
    }),
    terser({
      ecma: 5,
      mangle: {
        safari10: true,
      },
      output: {
        comments: false,
      },
    }),
  ],
}; 