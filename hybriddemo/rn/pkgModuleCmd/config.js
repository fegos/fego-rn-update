// 写个用户名跟路径对应的字典
let map = {
	/**
	 * 注意：
	 * 1、username为电脑用户名；
	 * 2、path为包存储位置，末尾需要加“/”，否则会报路径错误
	 */
	sxiaoxia: '/Users/sxiaoxia/Desktop/work/kaiyuan/fego-rn-update/hybriddemo/rn/bao/',
}
// 获取系统信息
let os = require('os');
// 获取本机当前用户名
let username = os.userInfo().username;
console.log(map[username]);
module.exports = {
	path: map[username],
	apkVer: '1.0'
}