// to start browser-sync server including inner folders/files 
browser-sync start --server --directory --files "**/*"
//
// to install
npm install -g browser-sync

//to start server from current folder
serve -p 3000
//port is optional
//
// to install
npm install -g serve

//init npm within a project folder
npm init

// install bower
npm install -g bower
// -g stands for global

// init bower within a project folder
bower init
// as a result there should appear 2 files package.json and bower.json

//install packages through bower
bower install --save jquery2 bootsrtap-sass angular angular-ui-router angular-resource
// --save here stands for inserting info into bower.json automatically

// get the list of installed bower components
du -h -d 1 bower_components

// install gulp
npm install gulp --save-dev
//npm install gulp -g --save-dev

// gulp tasks installation
npm install --save-dev gulp-if gulp-sync del gulp-debug gulp-sass gulp-sourcemaps gulp-replace gulp-useref gulp-uglify gulp-clean-css gulp-htmlmin browser-sync

// read local storage from browser console
for (var key in localStorage){console.log(key);console.log(localStorage[key]);console.log("\n");};

// npm ng2/4 dependency WARN
npm update
npm uninstall -g angular-cli
npm cache clean
npm install -g @angular/cli
