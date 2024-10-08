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
      extensions: ['.js', '.ts'], // Resolve both JavaScript and TypeScript files
    }),
    commonjs({
      include: 'node_modules/**', // Converts CommonJS modules to ES6
    }),
    babel({
      babelHelpers: 'bundled',
      configFile: './babel.config.js', // Assuming you've set up Babel configuration in this file
      exclude: 'node_modules/**', // Exclude node_modules from Babel transformation if not already handled by config
    }),
    terser({
      ecma: 5, // Set the ECMAScript target version to 5 for compatibility
      mangle: {
        safari10: true, // For fixing Safari 10/11 issues
      },
      output: {
        comments: false, // Remove all comments in the output
      },
    }),
  ],
}; 