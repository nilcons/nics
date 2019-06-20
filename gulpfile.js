"use strict";

// Load plugins
const autoprefixer = require("gulp-autoprefixer");
const browsersync = require("browser-sync").create();
const del = require("del");
const gulp = require("gulp");
const file = require("gulp-file");
const gfonts = require("gulp-google-webfonts");
const merge = require("merge-stream");
const rename = require("gulp-rename");
const sass = require("gulp-sass");

// BrowserSync
function browserSync(done) {
  browsersync.init({
    server: {
      baseDir: "./"
    },
    port: 3000
  });
  done();
}

// BrowserSync reload
function browserSyncReload(done) {
  browsersync.reload();
  done();
}

// Bring third party dependencies from node_modules into vendor directory
function modules() {
  del.sync("./vendor");

  // Bootstrap
  var bootstrap = gulp.src('./node_modules/bootstrap/dist/**/*')
    .pipe(gulp.dest('./vendor/bootstrap'));
  // Font Awesome CSS
  var fontAwesomeCSS = gulp.src('./node_modules/@fortawesome/fontawesome-free/css/**/*')
    .pipe(gulp.dest('./vendor/fontawesome-free/css'));
  // Font Awesome Webfonts
  var fontAwesomeWebfonts = gulp.src('./node_modules/@fortawesome/fontawesome-free/webfonts/**/*')
    .pipe(gulp.dest('./vendor/fontawesome-free/webfonts'));
  // jQuery
  var jquery = gulp.src([
      './node_modules/jquery/dist/*',
      '!./node_modules/jquery/dist/core.js'
    ])
    .pipe(gulp.dest('./vendor/jquery'));
  var gf = file('fonts.list',
                'Droid+Serif:400,700,400italic,700italic\n' +
                'Droid+Mono:100,300,400,700\n' +
                'Montserrat:400,700\n' +
                'Kaushan+Script\n',
                { src: true })
    .pipe(gfonts({}))
    .pipe(gulp.dest('vendor/google-fonts'));
  return merge(bootstrap, fontAwesomeCSS, fontAwesomeWebfonts, jquery, gf);
}

// CSS task
function css() {
  return gulp
    .src("./nics.scss")
    .pipe(sass({
      outputStyle: "expanded",
    }))
    .pipe(autoprefixer({ cascade: false }))
    .pipe(gulp.dest("./assets"))
    .pipe(browsersync.stream());
}

// Watch files
function watchFiles() {
  gulp.watch("./nics.scss", css);
  gulp.watch(["./index.html"], browserSyncReload);
}

// Define complex tasks
const build = gulp.series(modules, css);
const watch = gulp.series(build, gulp.parallel(watchFiles, browserSync));

// Export tasks
exports.css = css;
exports.build = build;
exports.watch = watch;
exports.default = build;
