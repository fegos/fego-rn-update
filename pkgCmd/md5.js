var fs = require('fs');
let Utils = require('./Utils');

filepath = process.argv[2];
apkVer = process.argv[3];
zipName = process.argv[4];
content = process.argv[5];

fs.writeFileSync(filepath + apkVer + '/config', content + '_' + Utils.generateFileMd5(filepath + apkVer + '/' + zipName));

fs.writeFileSync(filepath.substring(0, filepath.length - 4) + apkVer + '_config', fs.readFileSync(filepath + apkVer + '/config'));