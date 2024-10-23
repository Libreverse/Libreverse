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
      extensions: [".js"],
    }),
    commonjs({
      include: "node_modules/**",
    }),
    babel({
      babelrc: false,
      babelHelpers: "bundled",
      exclude: "node_modules/**",
      presets: [
        [
          "@babel/preset-env",
          {
            useBuiltIns: "usage",
            corejs: 3,
            modules: false,
          },
        ],
      ],
    }),
    terser({
      ecma: 5,
      warnings: true,
      mangle: {
        properties: false,
        safari10: true,
        toplevel: true,
      },
      compress: {
        defaults: true,
        arrows: true,
        booleans_as_integers: true,
        booleans: true,
        collapse_vars: true,
        comparisons: true,
        conditionals: true,
        dead_code: true,
        drop_console: true,
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
        toplevel: true, // If you're sure there are no issues with mangling top-level variables
        typeofs: true,
        unused: true, // Drop unused variables and functions
      },
      output: {
        comments: false,
        beautify: false,
        semicolons: true,
      },
      keep_classnames: false,
      keep_fnames: false,
      safari10: true,
      module: true,
    }),
  ],
};
