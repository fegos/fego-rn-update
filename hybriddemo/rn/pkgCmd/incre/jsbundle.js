/**
 * bundle增量生成
 */
var configs = require('../config');
var fs = require('fs');
var diff = require('../third/diff_match_patch_uncompressed');
var dmp = new diff.diff_match_patch();
var assets = require('./assets');
var zipper = require("zip-local");
var crypto = require('crypto');
var rd = require('../third/file_list');

/**
 * bundle增量生成函数
 * @param {*} oldVer bundle老版本号
 * @param {*} newVer bundle新版本号
 * @param {*} sdkVer sdk版本号
 * @param {*} platform 平台，android/ios
 */
module.exports = function (oldVer, newVer, sdkVer, platform) {
	// 旧包内容
	var bunOld = '';
	// 新包内容
	var bunNew = '';
	// 获取的增量内容
	var patch_text = '';

	// 包路径前缀
	var pathPrefix = configs.path + platform;
	// 增量包路径前缀；
	var incrementPathPrefix = pathPrefix + '/increment/';
	// 全量包路径前缀：
	var allPathPrefix = pathPrefix + '/all/temp/';
	// 全量包bundle的名字
	const bundleName = 'index.jsbundle';
	// 增量包里bundle的名字
	const incrementBundleName = 'increment.jsbundle';
	// 全量包zip名字
	var zipName = 'rn_' + sdkVer + '_' + newVer;
	// 是否是增量包，'0'表示是增量包，'1'表示全量包
	var isIncrement = '0';
	// 增量包zip名字
	var incrementName = 'rn_' + sdkVer + '_' + newVer + '_' + oldVer + '_' + isIncrement;

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
	let promises = [oldVer, newVer].map(function (id) {
		return readFile(allPathPrefix + sdkVer + '/rn_' + sdkVer + '_' + id + "/" + bundleName);
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

			// 比对增量和新包大小，以防改动较多导致增量包比全量还大的问题
			if (patch_text.length > text2.length) {
				isIncrement = '1';
			} else {
				isIncrement = '0';
			}

			// 生成到的指定路径如果不存在，则一一生成指定目录
			incrementName = 'rn_' + sdkVer + '_' + newVer + '_' + oldVer + '_' + isIncrement;
			let path = sdkVer + '/' + newVer + '/' + incrementName + '/' + incrementBundleName;
			path = path.split('/');
			let sumPath = incrementPathPrefix;
			for (let i = 0; i < path.length - 1; i++) {
				if (!fs.existsSync(sumPath + path[i])) {
					fs.mkdirSync(sumPath + path[i]);
				}
				sumPath = sumPath + path[i] + '/';
			}

			// 将生成的增量内容存储到指定路径下的bundle文件中
			let text = isIncrement === '0' ? patch_text : text2;
			let finalName = isIncrement === '0' ? incrementBundleName : bundleName;
			fs.writeFile(incrementPathPrefix + sdkVer + '/' + newVer + '/' + incrementName + '/' + finalName, text, function (err) {
				if (err) {
					console.log('生成增量包failure' + err);
					reject(err);
				} else {
					console.log('生成增量包' + platform + '_' + newVer + '_' + oldVer + '_' + 'success');
					resolve(isIncrement);
				}
			});

		});
		return promise;
	}

	/**
	 * 合并成最新的全量包（可选）
	 */
	function patch_launch() {
		var promise = new Promise(function (resolve, reject) {
			var text1 = bunOld;
			var patches = dmp.patch_fromText(patch_text);

			// var ms_start = (new Date).getTime();
			var results = dmp.patch_apply(patches, text1);
			// var ms_end = (new Date).getTime();
			// console.log(ms_end - ms_start);

			let error = false;
			let patch_results = results[1];
			var html = '';
			for (var x = 0; x < patch_results.length; x++) {
				if (patch_results[x]) {
				} else {
					error = true;
				}
			}
			if (error) {
				console.log('增量更新failure');
				reject('增量更新failure');
			}
			fs.writeFile(incrementPathPrefix + sdkVer + '/' + newVer + '/' + incrementName + '/all.bundle', results[0], function (err) {
				if (err) {
					console.log('增量更新failure' + err);
					reject(err);
				} else {
					console.log('增量更新success');
					resolve(patch_text);
				}
			});
		});
		return promise;
	}

	/**
	 * 在bundle和assets均生成增量后进行压缩，并更新config文件
	 */
	function zipIncrement() {
		let zipPath = incrementPathPrefix + sdkVer + '/' + newVer + '/' + incrementName;
		zipper.zip(zipPath, function (error, zipped) {
			if (!error) {
				zipped.save(zipPath + '.zip', function (error) {
					if (!error) {
						let md5Value = generateFileMd5(zipPath + '.zip');
						console.log("ZIP EXCELLENT!");
						deleteFolder(zipPath);
						fs.appendFileSync(incrementPathPrefix + '/config', sdkVer + '_' + newVer + '_' + oldVer + '_' + isIncrement + '_' + md5Value + ',');
					} else {
						console.log("ZIP FAIL!");
					}
				});
			}
		});

	}

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

	/**
	 * 删除目录及下边的所有文件、文件夹
	 */
	function deleteFolder(zipPath) {
		var files = [];
		if (fs.existsSync(zipPath)) {
			files = fs.readdirSync(zipPath);
			files.forEach(function (file, index) {
				var curPath = zipPath + "/" + file;
				if (fs.statSync(curPath).isDirectory()) { // recurse
					deleteFolder(curPath);
				} else { // delete file
					fs.unlinkSync(curPath);
				}
			});
			fs.rmdirSync(zipPath);
		}
	}

	let promise = Promise.all(promises).then(function (posts) {
		bunOld = posts[0].toString();
		bunNew = posts[1].toString();
		//1、生成bundle增量
		return diff_launch();
	}).then(function (value) {
		// return patch_launch();
		//2、生成图片资源的增量
		let fileList = rd.readFileSync(allPathPrefix + sdkVer + '/' + zipName);
		for (let i = 0; i < fileList.length; i++) {
			if (fileList[i].search('.ttf') !== -1) {
				let tmp = fileList[i].split('/');
				let name = tmp[tmp.length - 1];
				fs.writeFileSync(incrementPathPrefix + sdkVer + '/' + newVer + '/' + incrementName + '/' + name, fs.readFileSync(fileList[i]));
			}
		}
		let assetsIncrement = new assets(oldVer, newVer, sdkVer, platform, value);
		//3、将生成的增量包进行压缩操作，并删除之前生成的文件夹即其下的所有内容
		zipIncrement();
		return true;
	}, function (err) {

	});
}