# [fego-rn-update](https://fegos.github.io/fego-rn-update/) &middot; [![npm version](https://badge.fury.io/js/fego-rn-update.svg)](https://www.npmjs.com/package/fego-rn-update) [![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/fegos/fego-rn-update/pulls)

+ fego-rn 官方热更新方案

# 项目介绍

+ 基于React Native(0.47~0.53)的热更新库
+ 提供android和ios两端的支持
+ 支持全量、增量更新，配置简单，部署方便，一键打包
+ 支持字体文件更新
+ 支持拆包下的全量、增量更新

# 支持平台

+ android

+ ios

# API文档

[iOS](https://fegos.github.io/fego-rn-update/ios/html/index.html)

[Android](https://fegos.github.io/fego-rn-update/android/index.html)

# 设计原则

+ ios和android两端使用同一套脚本
+ 打全量包和增量包只需要执行一个脚本即可
+ 无论拆包还是非拆包，统一使用一套脚本

# 目录结构

+ 整体目录结构

```
.
├── FegoRnUpdate.podspec      # ios pod库的描述文件
├── android                   # android原生源码
├── demo                      # demo示例
│   ├── App.js                # js主代码
│   ├── android               # android工程
│   ├── increment             # 增量包、全量包存储路径
│   ├── index.js              # js入口文件
│   ├── ios                   # ios工程
│   ├── pkg.sh                # 主打包脚本文件
│   ├── pkgCmd                # 辅助脚本文件夹
│   └── resource              # 存放字体文件
├── docs                      # api文档
├── hybriddemo                # 拆包demo
│   ├── android               # android工程
│   ├── ios                   # ios工程
│   └── rn                    # js相关代码
├── increment                 # 包生成目录
├── index.js                  # js源码
├── ios                       # ios源码
├── package.json              # 项目描述文件
├── pkg.sh                    # 打包文件
└── pkgCmd                    # 辅助脚本文件夹
```
+ 打包脚本目录

```
.
├── pkg.sh                    # 整体打包文件，包含全量打包和增量打包，主执行脚本文件
└── pkgCmd                    # 辅助脚本文件夹
    ├── allPkg.sh             # 全量包打包脚本
    ├── bundleDiff.js         # 拆包时bundle的diff
    ├── config.js             # 配置文件，主要配置生成包的存储位置
    ├── incre                 # bundle和assets增量生成脚本
    │   ├── assets.js         # 资源assets增量生成脚本
    │   └── jsbundle.js       # bundle增量生成脚本
    ├── incregen.js           # 增量包生成脚本
    ├── md5.js                # 生成全量更新config
    ├── third                 # 依赖的第三方脚本
    │   ├── diff_match_patch_uncompressed.js      # 文件差异生成脚本
    │   └── file_list.js      # 列出目录下所有的文件
    ├── unpack.js             # 拆包
    └── Utils                 # 公共方法
```

# 安装

```
$ npm install fego-rn-update --save
```
## 手动安装

### Android
1. 把下面几行添加到 `android/setting.gradle`

```
include ':fego'

project(':fego').projectDir = new File(rootProject.projectDir, '../node_modules/fego-rn-update/android')
```
2. 在`android/build.gradle`中更新build工具版本为`2.2+`

```
buildscript {
    ...
    dependencies {
        classpath 'com.android.tools.build:gradle:2.2.3'
    }
}

```
3. 在`android/gradle/wrapper/gradle-wrapper.properties`中更新gradle版本为`2.14.1以上`

```
...
distributionUrl=https\://services.gradle.org/distributions/gradle-3.3-all.zip
```

4. 在`android/app/build.gradle`添加依赖

```
dependencies {
    compile project(':fego')
	// 需要添加以下依赖项
    compile "com.squareup.retrofit2:retrofit:2.1.0"
    compile "com.squareup.retrofit2:converter-gson:2.0.0"
}
```

5. 在`AndroidManifest.xml`中添加依赖

```
<uses-permission android:name="android.permission.INTERNET" />
```

6. 初始化`ReactManager`
```
ReactManager.getInstance().init(getApplication(), "index", "index.jsbundle", "https://raw.githubusercontent.com/fegos/fego-rn-update/master/demo/increment/android/");
```

7. 生成`ReactRootView`时，需要使用ReactManager中生成的`RnInstanceManager`：

```
// 业务名
String businessName = "";
if (mReactRootView == null) {
    mReactRootView = new ReactRootView(this);
    if (mReactInstanceManager == null) {
        if (ReactManager.getInstance().getRnInstanceManager() == null) {
            List<ReactPackage> reactPackages = new ArrayList<>();
            // 添加额外的package
            reactPackages.add(new HotUpdatePackage());
            ReactManager.getInstance().loadBundle(reactPackages, BuildConfig.DEBUG, "");
        }
		mReactInstanceManager = ReactManager.getInstance().getRnInstanceManager();
	}
    mReactRootView.startReactApplication(mReactInstanceManager, "hotUpdate", null);
    setContentView(mReactRootView);
}
```

8、调用热更新代码（也可js端调用）

```
String businessName = "";
SuccessListener sucListener;// 一般是activity实现了该接口，可以为null，为null时表示不交给用户处理，而是内部默认解压加载
FailListener failListener;	// 一般是activity实现了该接口，可以为null
ReactManager.getInstance().loadBundleBehind(businessName, sucListener, failListenr);
```
9、处理结果通知

+ 默认全部更新，不需做任何其他处理

+ 可以分别实现SuccessListener、FailListener，来处理成功和失败的情况
```
@Override
public void onSuccess() {
    questionUpdateReactSource();// 可以弹窗提示
}

protected void questionUpdateReactSource() {
    //此处标记已经下载了新的rn资源包,提示用户是否进行更新
    AlertDialog dialog = new AlertDialog.Builder(this)
            .setTitle("温馨提示")
            .setMessage("有新的资源包可以更新，是否立即更新?")
            .setNegativeButton("取消", new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {
                    dialog.cancel();
                }
            })
            .setPositiveButton("确定", new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {
                    ReactManager.getInstance().unzipBundle();
                    ReactManager.getInstance().doReloadBundle();
                    // 下次启动应用时更新
                    // ReactManager.getInstance().unzipBundle();
                }
            })
            .create();
    dialog.show();
}

@Override
public void onFail(ReactManager.NPReactManagerTask task) {
    if (task == ReactManager.NPReactManagerTask.GetConfigFail) {
        // 获取config失败
    } else if (task == ReactManager.NPReactManagerTask.GetSourceFail) {
        // 获取zip包失败
    } else if (task == ReactManager.NPReactManagerTask.Md5VerifyFail) {
        // md5验证失败
    }
}
```
**注意**：

如果实现了SuccessListener，则不会解压新包，也不会自动加载最新bundle，所有成功后的操作需要自行实现，可以调用下面的方法进行重新加载
```
String businessName = "";
// 仅解压包，不执行下面的操作时下次启动自动更新
ReactManager.getInstance().unzipBundle(businessName);
// 加载新bundle
ReactManager.getInstance().doReloadBundle(businessName);
```
### IOS
1. pod库引入热更新库，Podfile中添加：
```
pod 'FegoRnUpdate'
```
2. 工程目录下执行pod命令: 
```
pod update
```
3.调用热更新代码
```
NIPRnManager *manager = [NIPRnManager sharedManager];
manager.delegate = self;
manager.bundleUrl = @"https://raw.githubusercontent.com/fegos/fego-rn-update/master/demo/increment/ios/increment";
manager.noHotUpdate = NO;
manager.noJsServer = YES;
[manager requestRCTAssetsBehind];
```
4.处理代理结果
```
-(void)successHandlerWithFilePath:(NSString *)filePath{
    NSLog(@"NIPHotReloadSuccess");
    [[NIPRnManager sharedManager] unzipBundle:filePath];
    [self loadRnController];
}
-(void)failedHandlerWithStatus:(HotReloadStatus)status{
    switch (status) {
    case NIPReadConfigFailed:
    {
    NSLog(@"NIPReadConfigFailed");
    }
    break;
    case NIPDownloadBundleFailed:
    {
    NSLog(@"NIPDownloadBundleFailed");
    }
    break;
    case NIPMD5CheckFailed:
    {
    NSLog(@"NIPMD5CheckFailed");
    }
    break;
    default:
    break;
    }

}
```
5. AppDelegate中添加热更新代码的例子
```
#import "NIPRnManager.h"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self loadRnController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadRnController) name:@"RNHotReloadRequestSuccess" object:nil];

  	return YES;
}

- (void)loadRnController {
    /**
    @param bundleUrl 服务器存放bundle的地址
    @param noHotUpdate 用来标记只使用工程自带的rn包，不支持热更新 default:NO
    @param noJsServer 不通过本地启动的server来获取bundle，直接使用离线包 default:NO
    @param moduleName 默认main bundle的指定模块
    */
    NIPRnController *controller = [[NIPRnManager managerWithBundleUrl:@"bundle下载路径" noHotUpdate:NO noJsServer:YES] loadControllerWithModel:@"moduleName"];

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wincompatible-pointer-types"
    self.window.rootViewController = controller;
    #pragma clang diagnostic pop
}
```


# 使用

1. 将`node_modules/fego-rn-update/`下`pkdCmd文件夹`和`pkg.sh`文件拷贝到与`node_modules同级目录`下

2. 在想要生成包的地方创建包存储目录

存储目录可以参考`node_modules/fego-rn-update/`下的`increment文件夹`（其内部是android和ios目录均是自动生成的）

```
.
├── React-Native 热更新目录
├── android                 # 存放android生成的包
│   └── businessName        # 如果是拆包的情况，会多这一级目录，非拆包的情况，不存在这一级目录
│   	├── all             # 存放全量包
│       │   ├── README.md   
│       │   └── temp        # 该目录为自动生成，存放解压后的包，该目录可添加到.gitignore文件中
│    	├── config          # 最终的config，该文件会自动生成，默认为增量
│       └── increment       # 存放增量包
│           └── README.md
└── ios                     # 存放ios生成的包
	└── businessName
        ├── all             # 存放全量包
        │   └── README.md
        │   └── temp        # 该目录为自动生成，存放解压后的包，该目录可添加到.gitignore文件中
        ├── config          # 最终的config，该文件会自动生成，默认为增量
        └── increment       # 存放增量包
            └── README.md
```
3. 修改配置文件`config.js`中的`path`和`apkVer`（config.js文件位于pkgCmd/下）

	path：生成包存储路径
	apkVer：apk版本号

```
// 写个用户名跟路径对应的字典，这个方便一个工程多个人维护使用，支持mac
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
	path: map[username],//在此处可以直接更改为自己要生成包的位置
	apkVer: '1.0'//需跟apk版本保持一致
}
```
4. 更新字体文件

需在`pkg.sh`同级目录下创建resource，并将ttf文件存放于该目录下，如果有businessName，则需要多创建一层businessName目录，再将相应的ttf文件放置相应的文件夹中

**注意**

	不同的业务的ttf命名需不同

5. 在`node_modules同级目录`下执行脚本`pkg.sh`

```
# platform 平台 ，android或ios，不设置则默认两端都进行生成包操作
# type 更新类型，increment或all，默认为increment，如果type设置了，则说明要更换更新类型，否则默认是去生成包；该属性默认是在生成完好包之后再进行该操作
# businessName 业务名为no，标明不区分业务模块，否则即拆包模式，根据业务名去生成包
sh pkg.sh platform type businessName
```
**注意**：

	+ 首次运行，因为只生成一个包，故会提示没有新包，不会生成增量包；
	+ 运行之后需要在android和ios两个工程中均放置一份解压后的包，android放在`assets/rn/`下，ios放于`项目名/rn/`下（目录若需调整，需要修改原生代码，建议不修改），每次app大版本变化时需要进行该操作；
	+ 之后在同一sdk版本下继续运行该脚本时，会进行增量包生成。
	+ 生成包之后，需要上传到服务器，用于原生更新时请求，此时的地址就是上面需要在原生中配置的sourceUrl
	+ 如果想更换更新方式，可以执行带type参数的脚本，此时会选择将全量还是增量更新的config拷贝到platform/config（此config才是真正的更新config），默认使用的增量模式

6. 在原生修改几处

+ 启动文件名字为`index.js`；
+ bundle名字为`index.jsbundle`；
+ 请求地址为`config请求地址`（如demo中，请求地址为https://raw.githubusercontent.com/fegos/fego-rn-update/master/demo/increment/android/， ios平台只需替换地址中的android即可，ios无需加末尾的‘/’）

`android`：在MainActivity中修改

`ios`：在AppDelegate中修改

**注意**：

	+ android和ios需要统一启动文件名称，均为index.js，否则需要修改全量打包脚本；
	+ bundle名字也需要两端统一为index.jsbundle，否则需要修改增量更新打包脚本

7. js端调用

```
import FegoRNUpdate from 'fego-rn-update'

class App extends Component {
	render() {
		return (
			<View style={styles.container}>
				<TouchableHighlight
					underlayColor="transparent"
					onPress={() => {
						FegoRNUpdate.hotReload(businessName);
					}}>
					<Text style={styles.btnText}>热更新测试</Text>
				</TouchableHighlight>
			</View>
		);
	}
}

const styles = StyleSheet.create({
	container: {
		flex: 1,
		justifyContent: 'center',
		alignItems: 'center',
		backgroundColor: '#F5FCFF',
	},
	btnText: {
		color: 'blue',
		fontSize: 16
	}
});

```

# 欢迎贡献

有任何疑问或问题欢迎在 [github issues](https://github.com/fegos/fego-rn-update/issues)里提问
