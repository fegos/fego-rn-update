# 使用方式
# 在终端中执行脚本 sh pack.android.sh platform
# platform可选，ios/android，默认情况下为android
echo '*******************全量打包开始*****************'
platform=$1
path=$2
apkVer=$3
bundleName=$4
# 创建生成包目录
configDir=$path$platform/all/$apkVer/
hotConfigDir=$path$platform/all/
incrementDir=$path$platform/increment/$apkVer/
tempDir=$path$platform/all/temp/$apkVer/

mkdir -p $configDir
mkdir -p $incrementDir
mkdir -p $tempDir

# config文件路径
configPath=$configDir"unzipVer"
hotConfigPath=$hotConfigDir"config"

# 判断是否是新一期版本第一次开发
isexist=0
if [ ! -e "$configPath" ]; then 
	echo "0">$configPath
else
	 isexist=1
fi 
echo '*******bundle打包开始*******'
# 打包到临时目录
rm -rf deploy
mkdir -p deploy
#rn资源打包
react-native bundle --entry-file index.js --platform $platform --dev false --bundle-output deploy/$bundleName --assets-dest deploy
echo '*******bundle打包结束*******'

echo '*******config文件读取*******'
#读取config文件的内容，确认当前应该生成的最新版本号
for line in  `cat $configPath`
do
    newVer=${line}
done
# 如果不是第一次打包，且config中版本号为0时，需要改为1（之后不需要改是因为如果做过增量生成之后config就是下一次的最新版本号）
if [ $isexist = 1 ]; then
	if [ $newVer = 0 ]; then
		newVer=1
	fi
fi
content=$apkVer"_"$newVer
currentPath=`pwd`
#压缩包的名字
zipName="rn_"$apkVer"_"$newVer".zip"
echo '*******打包字体文件*******'
#拷贝字体文件到打包文件夹中
if [ ! -e "resource/" ]; then 
	echo 'resource not exist'
else
	cp -rf resource/ deploy/
fi

if [ $isexist = 0 ]; then
	echo 'first pack'
	# if [ $platform = 'android' ]; then
	# 	mkdir -p $currentPath/../android/app/src/main/assets/rn/
	# 	cp -rf deploy/ $currentPath/../android/app/src/main/assets/rn/
	# fi
fi
cd deploy

echo '*******压缩包放于指定目录*******'
#生成压缩包放于deploy下
zip -r $zipName *
cd ../
cp deploy/$zipName $configDir
echo '*******全量包config生成*******'
node ./pkgCmd/md5.js $hotConfigDir $apkVer $zipName $content
echo '*******************全量打包结束*****************'