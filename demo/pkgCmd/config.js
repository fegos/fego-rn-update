// 写个用户名跟路径对应的字典
let map = {
	'sxiaoxia': '/Users/sxiaoxia/Desktop/work/project/miaow-rn-hotUpdate/increment/',
	'zhaosong': '/Users/zhaosong/Documents/sourcetree/miaow-rn-hotUpdate/increment/'
}
// 获取系统信息
let os = require('os');
// 获取本机当前用户名
let username = os.userInfo().username;
console.log(map[username]);
module.exports = {
	path: map[username],
	sdkVer: '1.0'
}