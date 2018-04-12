var fs = require('fs');
var crypto = require('crypto');
/**
 * 生成文件的md5值
 * @param {*} filepath 文件地址
 */
exports.generateFileMd5 = function (filepath) {
	var buffer = fs.readFileSync(filepath);
	var fsHash = crypto.createHash('md5');
	fsHash.update(buffer);
	var md5 = fsHash.digest('hex');
	return md5;
}

/**
 * 删除目录及下边的所有文件、文件夹
 * @param {*} dir 
 */
exports.deleteFolder = function (dir) {
	var files = [];
	if (fs.existsSync(dir)) {
		files = fs.readdirSync(dir);
		files.forEach(function (file, index) {
			var curPath = dir + "/" + file;
			if (fs.statSync(curPath).isDirectory()) { // recurse
				exports.deleteFolder(curPath);
			} else { // delete file
				fs.unlinkSync(curPath);
			}
		});
		fs.rmdirSync(dir);
	}
}
