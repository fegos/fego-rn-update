# 使用方式
# 在终端中执行脚本 sh pack.android.sh platform path apkVer
# platform可选，ios/android，默认情况下为android；path为包路径；apkVer：应用版本
platform=$1
path=$2
apkVer=$3
echo $platform
echo $path
echo $apkVer

# 创建生成包目录
configDir=$path$platform/all/$apkVer/
hotConfigDir=$path$platform/all/
incrementDir=$path$platform/increment/$apkVer/
tempDir=$path$platform/all/temp/$apkVer/
mkdir -p $configDir
mkdir -p $incrementDir
mkdir -p $tempDir

#config文件路径
configPath=$configDir"unzipVer"
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
content=$apkVer"_"$newVer
# echo $content>$hotConfigPath
#压缩包的名字
zipName="rn_"$apkVer"_"$newVer".zip"
echo $newVer
echo $zipName
#拷贝字体文件到打包文件夹中
if [ ! -e "resource/" ]; then 
	echo 'resource not exist'
else
	cp -rf resource/ deploy/
fi
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

node ./pkgCmd/md5.js $path$platform/all/ $apkVer $zipName $content
#推送到git
# cd $configDir
# git add .
# git commit -m "V-"$platform"-"$apkVer"-"$newVer
# git push
# cd $currentPath