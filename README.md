# fego-rn-update

+ fego-rn 官方热更新方案

# 项目介绍

+ 基于React Native的增量更新库，提供android和ios两端的支持

# 支持平台

+ android
+ ios

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
1. 把下面几行添加到 `android/build.gradle`

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
}
```

5. 在`AndroidManifest.xml`中添加依赖

```
<uses-permission android:name="android.permission.INTERNET" />
```

6. 使`MainActivity`依赖fego-rn-update提供的`ReactActivity`

```
// add these imports
import com.fego.android.service.HotUpdatePackage;
import com.fego.android.service.ReactActivity;
import com.fego.android.service.ReactManager;

public class MainActivity extends ReactActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // 启动后台热更新操作
        // ReactManager.getInstance().loadBundleBehind();
    }

    @Override
    public String getModuleName() {
        return "hotUpdate";
    }

    @Override
    public boolean isDevelopStatus() {
        return BuildConfig.DEBUG;
    }

    @Override
    public void initReactManager() {
        if (ReactManager.getInstance().getRnInstanceManager() == null) {
            // 设置react native启动文件的名称
            ReactManager.getInstance().setJsMainModuleName("index");
            // 设置加载的bundle文件名
            ReactManager.getInstance().setBundleName("index.jsbundle");
            // 设置热更新路径
            ReactManager.getInstance().setSourceUrl("你的下载路径");
            List<ReactPackage> reactPackages = new ArrayList<>();
            // 添加额外的package
            reactPackages.add(new HotUpdatePackage());
            ReactManager.getInstance().init(getApplication(), reactPackages, BuildConfig.DEBUG);
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
    }
}
```
### IOS


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
│   └── increment       # 存放增量包
│       └── README.md
└── ios                 # 存放ios生成的包
    ├── all             # 存放全量包
    │   └── README.md
    └── increment       # 存放增量包
        └── README.md
```

3. 修改配置文件`config.js`中的`path`和`sdk`

```
// 写个用户名跟路径对应的字典，这个方便一个工程多个人维护使用，支持mac
let map = {
}
// 获取系统信息
let os = require('os');
// 获取本机当前用户名
let username = os.userInfo().username;
console.log(map[username]);
module.exports = {
	path: map[username],//在此处可以直接更改为自己要生成包的位置，即第二步中的最外层目录
	sdkVer: '1.0'//需跟apk版本保持一致
}
```
4. 在`node_modules同级目录`下执行脚本`pkg.sh`

```
sh pkg.sh platform  // 其中platform为android/ios
```
**注意**：首次运行，因为只生成一个包，故会提示没有新包，并需要在android和ios两个工程中均放置一份包，android放在`android/app/src/main/assets/rn/`下，ios放于`ios/项目名/rn/`下；之后在同一sdk下继续运行该脚本时，会进行增量包生成。

5. 在原生修改启动文件名字为`index.js`，bundle名字为`index.jsbundle`，请求地址为`config请求地址`

`android`：在MainActivity中修改

`ios`：

**注意**：android和ios需要统一启动文件名称，均为index.js，否则需要修改全量打包脚本；bundle名字也需要两端统一为index.jsbundle，否则需要修改增量更新打包脚本

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