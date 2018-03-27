# 使用方式
# 在终端中执行脚本 sh pack.android.sh platform
# platform可选，ios/android，默认情况下为android
platform=$1
#临时变量记录当前rn资源数据对应sdk的版本号
newVer=1
#生成的最终rn zip包的名称
zipName=''
path=$2
sdkVer=$3
businessName=$4
echo $platform
echo $path
echo $sdkVer
echo $businessName
configDir=$path$platform/$businessName/all/$sdkVer/
hotConfigDir=$path$platform/$businessName/all/
mkdir -p $configDir
mkdir -p $path$platform/$businessName/increment/
#config文件路径
configPath=$configDir"config"
hotConfigPath=$hotConfigDir"config"
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
mkdir -p deploy/common
mkdir deploy/$businessName
#rn资源打包
react-native bundle --entry-file $businessName/index.js --platform $platform --dev false --bundle-output deploy/$businessName/index.jsbundle --assets-dest deploy/$businessName
if [ $businessName = "common" ];then
	echo 'NOT COMMON'
else 
	react-native bundle --entry-file common/index.js --platform $platform --dev false --bundle-output deploy/common/index.jsbundle --assets-dest deploy/common
fi
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
content=$sdkVer"_"$newVer
currentPath=`pwd`
echo $currentPath
if [ $businessName = "common" ];then
	echo 'NOT COMMON'
else 
	node pkgModuleCmd/unpack.js $businessName $currentPath/deploy/
fi
# echo $content>$hotConfigPath
#压缩包的名字
zipName="rn_"$sdkVer"_"$newVer".zip"
echo $newVer
echo $zipName
#拷贝字体文件到打包文件夹中
if [ ! -e "resource/" ]; then 
	echo 'resource not exist'
else
	cp -rf resource/ deploy/
fi
cd deploy
if [ $isexist = 0 ];then
	mkdir -p $currentPath/../android/app/src/main/assets/rn/$businessName/
	cp -rf $businessName/ $currentPath/../android/app/src/main/assets/rn/$businessName/
fi
#生成压缩包放于deploy/businessName下
cd $businessName
zip -r $zipName *
cd ../../
ls -l deploy
#将资源包拷贝到指定目录下
#下边的命令可以使用mv命令，该命令是直接将文件剪切粘贴到指定目录下，原来的文件会被删除；
#使用cp，则是相当于将文件复制粘贴到指定目录下，原来的文件还在
cp deploy/$businessName/$zipName $configDir
# #记录当前所在目录
# currentPath=`pwd`
# echo $currentPath
node ./pkgModuleCmd/md5.js $hotConfigDir $sdkVer $zipName $content