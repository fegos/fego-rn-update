/**
 * 增量包生成脚本入口文件
 */
var configs = require('./config');
var jsbundle = require('./incre/jsbundle');
var assets = require('./incre/assets');
var fs = require('fs');
var zipper = require("zip-local");

/******************** 变量说明 *******************/
// sdk版本
var apkVer = configs.apkVer;
// 最新版本号
var newVer = 0;
// ios/android, 执行本脚本时可以作为参数传入
var platform = 'android';
var businessName = '';
if (process.argv.length === 3) {
	if (process.argv[2] === 'android' || process.argv[2] === 'ios') {
		platform = process.argv[2];
	} else {
		businessName = process.argv[2];
	}
} else if (process.argv.length === 4) {
	platform = process.argv[2];
	businessName = process.argv[3];
}
console.log(platform);
console.log(businessName);
// 包路径前缀
var pathPrefix = '';
// 增量包路径前缀；
var incrementPathPrefix = '';
// 全量包路径前缀：
var allPathPrefix = '';
//全量包bundle的名字
const bundleName = 'index.jsbundle';
//增量包里bundle的名字
const incrementBundleName = 'increment.jsbundle';

/******************** 生成步骤 *******************/
/**
 * 1、首先解压未解压的所有需要比较的包
 * @param {*} platform 平台，android/ios
 */
function unzipAll() {
	if (businessName === 'no') {
		pathPrefix = configs.path + platform;
	} else {
		pathPrefix = configs.path + platform + '/' + businessName;
	}
	incrementPathPrefix = pathPrefix + '/increment/';
	allPathPrefix = pathPrefix + '/all/';

	// 看增量config是否存在，如果存在，则删除
	if (fs.existsSync(incrementPathPrefix + '/config')) {
		fs.unlinkSync(incrementPathPrefix + '/config')
	}

	// 看全量包中是否有包存在（打包脚本在第一次使用时会自动生成unzipVer文件，如果没有该文件，说明没有包存在）
	if (!fs.existsSync(allPathPrefix + apkVer + '/unzipVer')) {
		console.log("还没有可用的包，请先生成包");
		newVer = 0;
		return;
	}

	// 读取全量包中unzipVer文件，获取最新版本号
	let unzipVer = fs.readFileSync(allPathPrefix + apkVer + '/unzipVer');
	console.log(unzipVer + '**************');
	newVer = Number.parseInt(unzipVer);
	if (newVer === 0) {// 如果取到的值为0，则说明这是首次生成增量包，需要将最新版本更改为1
		newVer = 1;
	}

	// 从最新包开始依次解压包
	for (let i = newVer; i >= Number.parseInt(unzipVer); i--) {
		var zipName = 'rn_' + apkVer + '_' + i;

		// 兼容只存在老包就执行增量更新的情况，判断是否存在新包，不存在就终止整个脚本运行
		if (!fs.existsSync(allPathPrefix + apkVer + '/' + zipName + '.zip')) {
			console.log("新包" + zipName + ".zip不存在，请先生成新包");
			newVer = 0;
			return;
		}

		// 将解压包存放至temp文件中，方便git忽略
		if (!fs.existsSync(allPathPrefix + 'temp/' + apkVer + '/' + zipName)) {
			fs.mkdirSync(allPathPrefix + 'temp/' + apkVer + '/' + zipName);
		}

		// 解压包
		zipper.sync.unzip(allPathPrefix + apkVer + '/' + zipName + ".zip").save(allPathPrefix + 'temp/' + apkVer + '/' + zipName);
	}

	// 更新unzipVer文件，将其改为newVer+1
	fs.writeFileSync(allPathPrefix + apkVer + '/unzipVer', (newVer + 1) + '');
}

/**
 * 2、开始生成包，其中包括增量包生成、压缩
 * @param {*} platform 平台，android/ios
 */
function generateIncrement() {
	// 如果是非common模块，需要事先读取common bundle包内容
	let commonText = '';
	if (businessName !== 'no' && businessName !== 'common') {
		let commonAllPath = configs.path + platform + '/common/all/';
		if (!fs.existsSync(commonAllPath + apkVer + '/unzipVer')) {
			console.log("还没有common包，请先生成包");
			newVer = 0;
			return;
		}
		// 读取全量包中config文件，获取最新版本号
		let unzipVer = fs.readFileSync(commonAllPath + apkVer + '/unzipVer');
		let commonNewVer = Number.parseInt(unzipVer);
		var zipName = '';
		if (commonNewVer === 0) {// 如果取到的值为0，则说明这是首次生成增量包
			zipName = 'rn_' + apkVer + '_' + commonNewVer;
			if (!fs.existsSync(commonAllPath + 'temp/' + apkVer + '/' + zipName)) {
				fs.mkdirSync(commonAllPath + 'temp/' + apkVer + '/' + zipName);
			}
			zipper.sync.unzip(commonAllPath + apkVer + '/' + zipName + ".zip").save(commonAllPath + 'temp/' + apkVer + '/' + zipName);
		} else {
			zipName = 'rn_' + apkVer + '_' + (commonNewVer - 1);
		}
		commonText = fs.readFileSync(commonAllPath + 'temp/' + apkVer + '/' + zipName + '/' + bundleName);
	}
	for (let i = newVer - 1; i >= 0; i--) {
		new jsbundle(i, newVer, apkVer, platform, businessName, commonText);
	}
}

// 1、首先解压未解压的所有需要比较的包
unzipAll();
// 2、开始生成包，其中包括增量包生成、压缩
generateIncrement();
