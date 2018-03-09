# [fego-rn-update](https://fegos.github.io/fego-rn-update/) &middot; [![npm version](https://badge.fury.io/js/fego-rn-update.svg)](https://www.npmjs.com/package/fego-rn-update) [![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/fegos/fego-rn-update/pulls)

+ fego-rn 官方热更新方案

# 项目介绍

+ 基于React Native(0.47~0.53)的热更新库
+ 提供android和ios两端的支持
+ 支持增量更新，配置简单，部署方便，一键打包

# 支持平台

+ android

+ ios

# API文档

[iOS](https://fegos.github.io/fego-rn-update/ios/html/index.html)

[Android](https://fegos.github.io/fego-rn-update/android/index.html)

# 设计原则

+ ios和android两端使用同一套脚本
+ 打全量包和增量包只需要执行一个脚本即可

# 目录结构

+ 整体目录结构

```
.
├── FegoRnUpdate.podspec    # ios pod库的描述文件
├── android                 # android原生源码
├── demo                    # demo示例
│   ├── App.js              # js主代码
│   ├── android             # android工程
│   ├── increment           # 增量包、全量包存储路径
│   ├── index.js            # js入口文件
│   ├── ios                 # ios工程
│   ├── pkg.sh              # 主打包脚本文件
│   └── pkgCmd              # 辅助脚本文件夹
├── increment               # 包生成目录
├── index.js                # js源码
├── ios                     # ios源码
├── package.json            # 项目描述文件
├── pkg.sh                  # 打包文件
└── pkgCmd                  # 辅助脚本文件夹
```
+ 打包脚本目录

```
.
├── pkg.sh                  # 整体打包文件，包含全量打包和增量打包，主执行脚本文件
└── pkgCmd                  # 辅助脚本文件夹
    ├── config.js           # 配置文件，主要配置生成包的存储位置
    ├── incre               # bundle和assets增量生成脚本
    │   ├── assets.js       # 资源assets增量生成脚本
    │   └── jsbundle.js     # bundle增量生成脚本
    ├── incregen.js         # 增量包生成脚本
    ├── pack.sh             # 全量包打包脚本
    └── third               # 依赖的第三方脚本
        ├── diff_match_patch_uncompressed.js    # 文件差异生成脚本
        └── file_list.js    # 列出目录下所有的文件
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
	compile "org.greenrobot:eventbus:3.0.0"
    compile "com.squareup.retrofit2:retrofit:2.1.0"
    compile "com.squareup.retrofit2:converter-gson:2.0.0"
}
```

5. 在`AndroidManifest.xml`中添加依赖

```
<uses-permission android:name="android.permission.INTERNET" />
```

6. 生成`ReactRootView`时，需要使用ReactManager中生成的`RnInstanceManager`，设置相应的参数如下：

```
if (mReactRootView == null) {
    mReactRootView = new ReactRootView(this);
    if (mReactInstanceManager == null) {
        if (ReactManager.getInstance().getRnInstanceManager() == null) {
            // 设置react native启动文件的名称
            ReactManager.getInstance().setJsMainModuleName("index");
            // 设置加载的文件名
            ReactManager.getInstance().setBundleName("index.jsbundle");
            // 设置热更新路径
            ReactManager.getInstance().setSourceUrl("https://raw.githubusercontent.com/fegos/fego-rn-update/master/demo/increment/android/increment/");
            List<ReactPackage> reactPackages = new ArrayList<>();
            // 添加额外的package
            reactPackages.add(new HotUpdatePackage());
            ReactManager.getInstance().init(getApplication(), reactPackages, BuildConfig.DEBUG);
        }
        mReactInstanceManager = ReactManager.getInstance().getRnInstanceManager();
	}
    mReactRootView.startReactApplication(mReactInstanceManager, "hotUpdate", null);
    setContentView(mReactRootView);
}
```

7、调用热更新代码（也可js端调用）

```
ReactManager.getInstance().loadBundleBehind();
```
8、处理结果通知

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
// 仅解压包，不执行下面的操作时下次启动自动更新
ReactManager.getInstance().unzipBundle();
// 加载新bundle
ReactManager.getInstance().doReloadBundle();
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

存储目录可以参考`node_modules/fego-rn-update/`下的`increment文件夹`

```
.
├── React-Native 热更新目录
├── android             # 存放android生成的包
│   ├── all             # 存放全量包
│   │   └── README.md   
│   │   └── temp		# 该目录为自动生成，存放解压后的包，该目录可添加到.gitignore文件中
│   └── increment       # 存放增量包
│       └── README.md
└── ios                 # 存放ios生成的包
    ├── all             # 存放全量包
    │   └── README.md
	│   └── temp		# 该目录为自动生成，存放解压后的包，该目录可添加到.gitignore文件中
    └── increment       # 存放增量包
        └── README.md
```

3. 修改配置文件`config.js`中的`path`和`sdk`

	path：生成包存储路径
	sdk：跟apk版本号一致

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
	sdkVer: '1.0'//需跟apk版本保持一致
}
```
4. 在`node_modules同级目录`下执行脚本`pkg.sh`

```
sh pkg.sh platform  // 其中platform为android/ios
```
**注意**：

	+ 首次运行，因为只生成一个包，故会提示没有新包，不会生成增量包；
	+ 运行之后需要在android和ios两个工程中均放置一份解压后的包，android放在`assets/rn/`下，ios放于`项目名/rn/`下（目录若需调整，需要修改原生代码，建议不修改）；
	+ 之后在同一sdk版本下继续运行该脚本时，会进行增量包生成。
	+ 生成包之后，需要上传到服务器，用于原生更新时请求，此时的地址就是上面需要在原生中配置的sourceUrl

5. 在原生修改几处

+ 启动文件名字为`index.js`；
+ bundle名字为`index.jsbundle`；
+ 请求地址为`config请求地址`（如demo中，请求地址为https://raw.githubusercontent.com/fegos/fego-rn-update/master/demo/increment/android/increment/， ios平台只需替换地址中的android即可，ios无需加末尾的‘/’）

`android`：在MainActivity中修改

`ios`：在AppDelegate中修改

**注意**：

	+ android和ios需要统一启动文件名称，均为index.js，否则需要修改全量打包脚本；
	+ bundle名字也需要两端统一为index.jsbundle，否则需要修改增量更新打包脚本

6. js端调用

```
import FegoRNUpdate from 'fego-rn-update'

class App extends Component {
	render() {
		return (
			<View style={styles.container}>
				<TouchableHighlight
					underlayColor="transparent"
					onPress={() => {
						FegoRNUpdate.hotReload();
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
