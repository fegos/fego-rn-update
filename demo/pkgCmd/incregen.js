/**
 * 增量包生成脚本入口文件
 */
var configs = require('./config');
var jsbundle = require('./incre/jsbundle');
var fs = require('fs');
var zipper = require("zip-local");

console.log('*******************增量开始******************');
/******************** 变量说明 *******************/
// sdk版本
var apkVer = configs.apkVer;
// 最新版本号
var newVer = 0;
// ios/android, 执行本脚本时可以作为参数传入
var platform = 'android';
if (process.argv.length === 3) {
  platform = process.argv[2];
}
console.log('platform: ' + platform);
// 包路径前缀
var pathPrefix = '';
// 增量包路径前缀；
var incrementPathPrefix = '';
// 全量包路径前缀：
var allPathPrefix = '';
// 全量包bundle的名字
const bundleName = configs.bundleName;
// 最大的增量版本生成个数
let maxVerNum = configs.maxGenNum;
// 增量包里bundle的名字
const incrementBundleName = 'increment.jsbundle';

/******************** 生成步骤 *******************/
/**
 * 1、首先解压未解压的所有需要比较的包
 * @param {*} platform 平台，android/ios
 */
function unzipAll() {
  pathPrefix = configs.path + platform;
  incrementPathPrefix = pathPrefix + '/increment/';
  allPathPrefix = pathPrefix + '/all/';

  // 看增量config是否存在，如果存在，则删除
  if (fs.existsSync(incrementPathPrefix + apkVer + '/config')) {
    fs.unlinkSync(incrementPathPrefix + apkVer + '/config')
  }

  // 看全量包中是否有包存在（打包脚本在第一次使用时会自动生成unzipVer文件，如果没有该文件，说明没有包存在）
  if (!fs.existsSync(allPathPrefix + apkVer + '/unzipVer')) {
    console.log("还没有可用的包，请先生成包");
    newVer = 0;
    return;
  }

  // 读取全量包中unzipVer文件，获取最新版本号
  let unzipVer = fs.readFileSync(allPathPrefix + apkVer + '/unzipVer');
  console.log('最新版本号:', unzipVer.toString());
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
  maxVerNum = newVer - maxVerNum < 0 ? 0 : newVer - maxVerNum;
  for (let i = newVer - 1; i >= maxVerNum; i--) {
    new jsbundle(i, newVer, apkVer, platform);
  }
}

// 1、首先解压未解压的所有需要比较的包
unzipAll();
// 2、开始生成包，其中包括增量包生成、压缩
generateIncrement();
