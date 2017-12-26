# 使用说明

## 目录文件介绍

+ jsCmd：增量包生成脚本

+ pack.sh：bundle包打包脚本

+ config.js：配置文件，主要配置了path和sdkVer


## 使用

##### 1、拷贝上述目录到工程的rn入口文件同级目录下

##### 2、创建放置全量包和增量包的文件目录

如创建increment文件夹，放入如下的文件夹目录，如要上传git，最好每个里边加个类似README.md的说明，这样可以将创建好的文件夹上传上去。

```
.
├── android
│   ├── all         //存放全量包
│   └── increment   //存放增量包
└── ios
    ├── all         //存放全量包
    └── increment   //存放增量包
```

##### 3、修改config.js配置文件

主要有两个配置变量：path和sdkVer

    path：该路径主要是指全量包和增量包的目录路径，即上述的increment，具体路径根据实际创建路径
    sdkVer：实则app版本号，versionName

##### 4、pack.sh：打全量包脚本

目前脚本中最后的git上传代码已注释，可根据需求开启，如想要打好包直接进行上传操作，则可打开注释

+ 首次运行，需要将生成的rn包移动到相应平台的相应位置

```
if [ $platform = 'android' ]; then
 	#copy react-bundle包到android assets下的rn目录
 	rm -rf android/app/src/main/assets/rn
 	cp -rf deploy android/app/src/main/assets/rn
else 
 	#copy react-bundle包到ios hotUpdate下的rn目录
 	rm -rf ios/hotUpdate/rn
	cp -rf deploy ios/hotUpdate/rn
fi
```
这一步目前省略，可以将这一步的操作放倒apk打包脚本中，直接在平台的相应目录下产生最新的bundle包

+ 在终端中执行脚本 
```
sh pack.sh platform
```
注：platform可选，ios/android，默认情况下为android

+ 最后，可以在path下找到相应平台打的包

##### 5、jsCmd：增量更新生成脚本

+ 运行脚本
```
node index.js platform
```
注：platform同上可选，ios/android，默认情况下为android

+ 最后，可以在path下找到对应平台生成的增量包

##### 6、原生中修改

+ android

a、添加依赖，目前还没有提交到maven中，只是提交到本地的库中做了测试

// 在项目build.gradle中添加仓库(以本地仓库为例)

allprojects {

    repositories {

        jcenter()

        ...

        maven {

            url "$rootDir/../../mavenlocallib/miaow"

        }

    }

}

// 在主module下添加依赖

dependencies {

    compile "com.miaow.android:miaow-update:0.47.2.5"

}

或者可以直接使用jar包

b、使rn入口的activity继承我们包里的ReactActivity文件，并实现抽象方法

主要是以下三个方法：

getModuleName：主要返回与js中一致的module名字

isDevelopStatus：是否为开发模式

initReactManager：这一步初始化ReactManager中的一些相关值，包括**增量更新地址path**、js入口文件名、bundle名字，如果有其他的ReactPackage要添加，需在此处进行添加，如想在js调用hotReload方法，则需要添加HotUpdatePackage

c、js中调用hotReload方法

+ ios

##### 7、通过以上配置即可开始测试增量更新了

查看一下生成了一版增量包后，increment下的目录结构：

```
.
├── android
│   ├── all
│   │   └── 1.0                         //以sdkver分文件夹保存
│   │       ├── config                  //放置未解压的包的版本号，一般也是要生成的bundle包的最新版本号
│   │       ├── rn_1.0_0                //生成增量包过程对全量包进行了解压
│   │       │   ├── index.jsbundle
│   │       │   └── index.jsbundle.meta
│   │       ├── rn_1.0_0.zip            //未解压前使用pack.sh生成的全量包
│   │       ├── rn_1.0_1                //生成增量包过程对全量包进行了解压
│   │       │   ├── index.jsbundle
│   │       │   └── index.jsbundle.meta
│   │       └── rn_1.0_1.zip            //未解压前使用pack.sh生成的全量包
│   └── increment
│       ├── 1.0
│       │   └── 1
│       │       └── rn_1.0_1_0_0.zip    //生成的增量包
│       └── config
└── ios
    ├── all
    │   └── 1.0
    │       ├── config
    │       ├── rn_1.0_0
    │       │   ├── index.jsbundle
    │       │   └── index.jsbundle.meta
    │       ├── rn_1.0_0.zip
    │       ├── rn_1.0_1
    │       │   ├── index.jsbundle
    │       │   └── index.jsbundle.meta
    │       └── rn_1.0_1.zip
    └── increment
        ├── 1.0
        │   └── 1
        │       └── rn_1.0_1_0_0.zip
        └── config
```
