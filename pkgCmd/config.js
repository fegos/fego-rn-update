// 写个用户名跟路径对应的字典
let map = {
	/**
	 * 注意：
	 * 1、username为电脑用户名；
	 * 2、path为包存储位置，末尾需要加“/”，否则会报路径错误
	 */
	username1: 'path1',
	username2: 'path2'
}
// 获取系统信息
let os = require('os');
// 获取本机当前用户名
let username = os.userInfo().username;
console.log(map[username]);
module.exports = {
	path: map[username], // 在此处可以直接更改为自己要生成包的位置
	apkVer: '1.0',		// 需跟apk版本保持一致
	bundleName: 'index.jsbundle', // 需跟原生中保持一致
	maxGenNum: 2, // 增量包生成最大数量
}