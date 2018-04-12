/**
 * bundle增量生成
 */
var fs = require('fs');
var diff = require('./third/diff_match_patch_uncompressed');
var dmp = new diff.diff_match_patch();

/**
 * bundle增量生成函数
 * @param {*} oldVer bundle老版本号
 * @param {*} newVer bundle新版本号
 * @param {*} sdkVer sdk版本号
 * @param {*} platform 平台，android/ios
 */
module.exports = function (commonFile, businessName, tempPath) {
	// 旧包内容
	var bunOld = '';
	// 新包内容
	var bunNew = '';
	// 获取的增量内容
	var patch_text = '';

	var pathPrefix = tempPath;

	/**
	 * 读取文件内容	
	 * @param {*} src 文件源
	 */
	function readFile(src) {
		var promise = new Promise(function (resolve, reject) {
			fs.readFile(src, 'utf-8', function (err, data) {
				if (!err && data) {
					console.log('读取文件success' + src);
					resolve(data);
				} else {
					console.log('读取文件failure' + src + err);
					reject(err);
				}
			});
		});
		return promise;
	}

	// 读取新旧版本的bundle文件内容	
	let promises = [commonFile, businessName].map(function (id) {
		let file;
		if (id.includes('common')) {
			file = pathPrefix + id + '/index.jsbundle';
		} else {
			file = pathPrefix + id + '/index.jsbundle';
		}
		return readFile(file);

	});

	/**
	 * 做差量分析，并生成差量包
	 */
	function diff_launch() {
		var promise = new Promise(function (resolve, reject) {
			// 生成增量内容
			var text1 = bunOld;
			var text2 = bunNew;
			var diff = dmp.diff_main(text1, text2, true);
			if (diff.length > 2) {
				dmp.diff_cleanupSemantic(diff);
			}
			var patch_list = dmp.patch_make(text1, text2, diff);
			patch_text = dmp.patch_toText(patch_list);
			// 将生成的增量内容存储到指定路径下的bundle文件中
			fs.writeFile(pathPrefix + businessName + '/index.jsbundle', patch_text, function (err) {
				if (err) {
					console.log('生成diff FAILURE' + err);
					reject(err);
				} else {
					console.log('生成diff SUCCESS');
					resolve(true);
				}
			});

		});
		return promise;
	}

	let promise = Promise.all(promises).then(function (posts) {
		bunOld = posts[0].toString();
		bunNew = posts[1].toString();
		//1、生成bundle增量
		return diff_launch();
	});
}