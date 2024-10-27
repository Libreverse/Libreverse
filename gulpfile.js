const gulp = require("gulp");
const watch = require("gulp-watch");
const sass = require("gulp-sass")(require("sass"));
const postcss = require("gulp-postcss");
const postcssRtl = require("postcss-inline-rtl");
const postcssPresetEnv = require("postcss-preset-env");
const postcssFlexbugsFixes = require("postcss-flexbugs-fixes");
const cssnano = require("cssnano");

function cssTask() {
  return gulp
    .src("./app/assets/stylesheets/application.scss")
    .pipe(sass().on("error", sass.logError))
    .pipe(
      postcss([
        postcssRtl(),
        postcssPresetEnv({
          stage: 3,
        }),
        postcssFlexbugsFixes(),
        cssnano({
          preset: [
            "advanced",
            {
              autoprefixer: false,
              discardComments: { removeAll: true },
              mergeLonghand: true,
              calc: { precision: 2 },
              colormin: true,
              zindex: true,
              normalizeString: true,
              normalizeUrl: true,
              normalizeCharset: true,
              mergeRules: true,
              discardUnused: { fontFace: true, keyframes: true },
              convertValues: { length: true },
            },
          ],
        }),
      ]),
    )
    .pipe(gulp.dest("./app/assets/builds/"));
}

function watchTask() {
  watch("./app/assets/stylesheets/**/*.scss", cssTask);
}

// Export a single task that builds and then watches
const buildseuqence = gulp.series(cssTask);
exports.build = buildseuqence;
const devbuildseuqence = gulp.series(cssTask, watchTask);
exports.devbuild = devbuildseuqence;
