/**
 * 资源增量生成
 */
var configs = require('../config');
var fs = require('fs');
var rd = require('../third/file_list');
var diff = require('../third/diff_match_patch_uncompressed');
var dmp = new diff.diff_match_patch();
var crypto = require('crypto');
let Utils = require('../Utils');

/**
 * 资源增量生成
 * @param {*} oldVer bundle老版本号
 * @param {*} newVer bundle新版本号
 * @param {*} apkVer sdk版本号
 * @param {*} platform 平台，android/ios
 * @param {*} isIncrement 是否增量
 */
module.exports = function (oldVer, newVer, apkVer, platform, isIncrement, businessName) {

	var resultOld = [];//旧版本下的所有文件数组
	var resultNew = [];//新版本下所有的文件数组

	var hashOld = {};//将旧版本数组转化为hash
	var hashNew = {};//将新版本数组转化为hash

	var delArray = [];//删除的文件数组
	var addArray = [];//增加的文件数组

	//包路径前缀
	var pathPrefix = '';
	if (businessName === 'no') {
		pathPrefix = configs.path + platform;
	} else {
		pathPrefix = configs.path + platform + '/' + businessName;
	}
	//增量包路径前缀；
	var incrementPathPrefix = pathPrefix + '/increment/';
	//全量包路径前缀：
	var allPathPrefix = pathPrefix + '/all/temp/';
	//全量包zip名字
	var zipName = 'rn_' + apkVer;
	var oldZipName = zipName + '_' + oldVer;
	var newZipName = zipName + '_' + newVer;
	// //是否是增量包，'0'表示是增量包，'1'表示全量包
	// var isIncrement = '0';
	//增量包zip名字
	var incrementName = 'rn_' + apkVer + '_' + newVer + '_' + oldVer + '_' + isIncrement;

	/**
	 * 读取指定目录下的所有文件
	 */
	function readFileList() {
		var dir = platform === 'android' ? '' : '/assets'
		if (!fs.existsSync(allPathPrefix + apkVer + '/' + newZipName + dir)) {
			return;
		}
		let max;
		if (!fs.existsSync(allPathPrefix + apkVer + '/' + oldZipName + dir)) {
			// 此时应让将最新的包中的资源放到增量包中
			resultNew = rd.readFileSync(allPathPrefix + apkVer + '/' + newZipName + dir);
			max = resultNew.length;
			for (let i = 0; i < max; i++) {
				if (platform === 'android' && resultNew[i].search('drawable-') !== -1) {
					resultNew[i] = resultNew[i].substring(resultNew[i].indexOf('drawable-'));
					mkDir(resultNew[i]);
					fs.writeFileSync(incrementPathPrefix + apkVer + '/' + incrementName + '/' + resultNew[i], fs.readFileSync(allPathPrefix + apkVer + '/' + newZipName + '/' + resultNew[i]));
				} else if (platform === 'ios' && resultNew[i].search('assets') !== -1) {
					resultNew[i] = resultNew[i].substring(resultNew[i].indexOf('assets'));
					mkDir(resultNew[i]);
					fs.writeFileSync(incrementPathPrefix + apkVer + '/' + incrementName + '/' + resultNew[i], fs.readFileSync(allPathPrefix + apkVer + '/' + newZipName + '/' + resultNew[i]));
				} else {
					//删除不是drawable下的文件
					resultNew.splice(i, 1);
					max = max - 1;
					i = i - 1;
				}
			}
			resultNew = [];
			return;
		}
		resultOld = rd.readFileSync(allPathPrefix + apkVer + '/' + oldZipName + dir);
		resultNew = rd.readFileSync(allPathPrefix + apkVer + '/' + newZipName + dir);
		max = resultOld.length;
		for (let i = 0; i < max; i++) {
			if (platform === 'android' && resultOld[i].search('drawable-') !== -1) {
				resultOld[i] = resultOld[i].substring(resultOld[i].indexOf('drawable-'))
				hashOld[resultOld[i]] = true;
			} else if (platform === 'ios' && resultOld[i].search('assets') !== -1) {
				resultOld[i] = resultOld[i].substring(resultOld[i].indexOf('assets'))
				hashOld[resultOld[i]] = true;
			} else {
				//删除不是drawable下的文件
				resultOld.splice(i, 1);
				max = max - 1;
				i = i - 1;
			}
		}
		max = resultNew.length;
		for (let i = 0; i < max; i++) {
			if (platform === 'android' && resultNew[i].search('drawable-') !== -1) {
				resultNew[i] = resultNew[i].substring(resultNew[i].indexOf('drawable-'))
				hashNew[resultNew[i]] = true;
			} else if (platform === 'ios' && resultNew[i].search('assets') !== -1) {
				resultNew[i] = resultNew[i].substring(resultNew[i].indexOf('assets'))
				hashNew[resultNew[i]] = true;
			} else {
				//删除不是drawable下的文件
				resultNew.splice(i, 1);
				max = max - 1;
				i = i - 1;
			}
		}
	}

	function mkDir(newPath) {
		let path = newPath.split('/');
		let sumPath = incrementPathPrefix + apkVer + '/' + incrementName + '/';
		for (let i = 0; i < path.length - 1; i++) {
			if (!fs.existsSync(sumPath + path[i])) {
				fs.mkdirSync(sumPath + path[i]);
			}
			sumPath = sumPath + path[i] + '/';
		}
	}

	/**
	 * 生成资源的增量包
	 * 目前想的是增加和改动图片直接复制到目标目录，对于删除的文件需要在目标目录中删除相应的文件
	 */
	function generateIncrement() {
		readFileList();
		for (let i = 0, max = resultNew.length; i < max; i++) {
			if (typeof hashOld[resultNew[i]] !== "undefined") {
				// 相同元素,比较两个文件大小进一步判断
				let oldMd5 = Utils.generateFileMd5(allPathPrefix + apkVer + '/' + oldZipName + '/' + resultNew[i]);
				let newMd5 = Utils.generateFileMd5(allPathPrefix + apkVer + '/' + newZipName + '/' + resultNew[i]);
				if (oldMd5 !== newMd5) {
					console.log(allPathPrefix + apkVer + '/' + oldZipName + '/' + resultNew[i]);
					console.log(allPathPrefix + apkVer + '/' + newZipName + '/' + resultNew[i]);
					addArray.push(resultNew[i]);
					mkDir(resultNew[i]);
					fs.writeFileSync(incrementPathPrefix + apkVer + '/' + incrementName + '/' + resultNew[i], fs.readFileSync(allPathPrefix + apkVer + '/' + newZipName + '/' + resultNew[i]));
				}
			} else {
				// 不同元素    
				addArray.push(resultNew[i])
				mkDir(resultNew[i]);
				let tmp = fs.readFileSync(allPathPrefix + apkVer + '/' + newZipName + '/' + resultNew[i]);
				fs.writeFileSync(incrementPathPrefix + apkVer + '/' + incrementName + '/' + resultNew[i], tmp);
			}
		}
		for (let i = 0, max = resultOld.length; i < max; i++) {
			if (typeof hashNew[resultOld[i]] !== "undefined") {
				//相同元素，在上一步已比较二者大小，故此处不需再比较
			} else {
				//被删除的元素
				delArray.push(resultOld[i]);
			}
		}
		generateImgConfig();
	}

	/**
	 * 产生图片差异配置文件（主要包含删除文件的目录）
	 */
	function generateImgConfig() {
		let fileString = '';
		for (let i = 0; i < delArray.length; i++) {
			if (i === delArray.length - 1) {
				fileString = fileString + delArray[i];
			} else {
				fileString = fileString + delArray[i] + ',';
			}
		}
		fs.writeFileSync(incrementPathPrefix + apkVer + '/' + incrementName + '/assetsConfig.txt', fileString);
	}

	generateIncrement();
}