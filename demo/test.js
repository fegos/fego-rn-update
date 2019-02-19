var fs = require('fs');
const content = fs.readFileSync(__dirname + '/increment/android/increment/1.0/config').toString();
console.log(content.split(",").length);