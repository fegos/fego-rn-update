var fs = require('fs');
var crypto = require('crypto');
let Utils = require('./Utils');

filepath = process.argv[2];
apkVer = process.argv[3];
zipName = process.argv[4];
content = process.argv[5];

fs.writeFileSync(filepath + 'config', content + '_' + Utils.generateFileMd5(filepath + apkVer + '/' + zipName));

fs.writeFileSync(filepath.substring(0, filepath.length - 4) + 'config', fs.readFileSync(filepath + 'config'));