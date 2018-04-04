var fs = require('fs');
var crypto = require('crypto');
/**
 * 生成文件md5值
 * @param {*} filepath 
 */
function generateFileMd5(filepath) {
	var buffer = fs.readFileSync(filepath);
	var fsHash = crypto.createHash('md5');
	fsHash.update(buffer);
	var md5 = fsHash.digest('hex');
	return md5;
}

filepath = process.argv[2];
apkVer = process.argv[3];
zipName = process.argv[4];
content = process.argv[5];

fs.writeFileSync(filepath + 'config', content + '_' + generateFileMd5(filepath + apkVer + '/' + zipName));

fs.writeFileSync(filepath.substring(0, filepath.length - 4) + 'config', fs.readFileSync(filepath + 'config'));