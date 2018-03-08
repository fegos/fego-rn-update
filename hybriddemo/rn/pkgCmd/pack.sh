# 使用方式
# 在终端中执行脚本 sh pack.android.sh platform
# platform可选，ios/android，默认情况下为android
paw=`pwd`
echo $paw
user=`who am i | awk '{print $1}'`
echo $user
if [[ $paw =~ "jsCmd" ]]; then
	sedPath=''
else
	sedPath='pkgCmd/'
fi
echo $sedPath
path=`sed -n "/$user/s/[^\']*$user:[^\']*\'\([^\']*\)'.*/\1/p" ${sedPath}config.js`
echo $path
platform="android"
if [ $# = 1 ]; then
	if [ $1 = 'ios' ];then
		platform="ios"
	elif [ $1 = 'android' ];then
		platform="android"
	fi
fi
#当前rn sdk的版本号
sdkVer=`sed -n "/sdkVer/s/[^\']*sdkVer:[^\']*\'\([^\']*\)'.*/\1/p" ${sedPath}config.js`
echo $sdkVer
#临时变量记录当前rn资源数据对应sdk的版本号
newVer=1
#生成的最终rn zip包的名称
zipName=''
#当前目录
# currentPath=`pwd`
#rn资源ftp的相对路径
#mac
configDir=$path/$platform/all/$sdkVer/
if [ ! -e "$configDir" ]; then 
	mkdir $configDir
fi
#config文件路径
configPath=$configDir"config"
# 判断是否是新一期版本第一次开发
isexist=0
if [ ! -e "$configPath" ]; then 
	echo "0">$configPath
else
	 isexist=1
fi 
echo $isexist
#删除deploy目录下的所有文件
rm -rf deploy
mkdir deploy
#rn资源打包
react-native bundle --entry-file index.js --platform $platform --dev false --bundle-output deploy/index.jsbundle --assets-dest deploy

#读取config文件的内容，确认当前应该生成的最新版本号
for line in  `cat $configPath`
do
    newVer=${line}
done
# 如果不是第一次打包，且config中版本号为0时，需要改为1（之后不需要改是因为如果做过增量生成之后config就是下一次的最新版本号）
if [ $isexist = 1 ];then
	if [ $newVer = 0 ];then
		newVer=1
	fi
fi
#压缩包的名字
zipName="rn_"$sdkVer"_"$newVer".zip"
echo $newVer
echo $zipName
#生成压缩包放于deploy下
cd deploy
zip -r $zipName *
cd ../
ls -l deploy
#将资源包拷贝到指定目录下
#下边的命令可以使用mv命令，该命令是直接将文件剪切粘贴到指定目录下，原来的文件会被删除；
#使用cp，则是相当于将文件复制粘贴到指定目录下，原来的文件还在
cp deploy/$zipName $configDir
#记录当前所在目录
currentPath=`pwd`
echo $currentPath
#推送到git
# cd $configDir
# git add .
# git commit -m "V-"$platform"-"$sdkVer"-"$newVer
# git push
# cd $currentPath