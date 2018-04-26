# 使用方式
# 在终端中执行脚本 sh pack.android.sh platform
# platform可选，ios/android，默认情况下为android
platform=$1
path=$2
apkVer=$3
businessName=$4
echo $platform
echo $path
echo $apkVer
echo $businessName

# 创建生成包目录
if [ $businessName = 'no' ]; then
	echo 'not unpack'
	configDir=$path$platform/all/$apkVer/
	hotConfigDir=$path$platform/all/
	incrementDir=$path$platform/increment/$apkVer/
	tempDir=$path$platform/all/temp/$apkVer/
else 
	configDir=$path$platform/$businessName/all/$apkVer/
	hotConfigDir=$path$platform/$businessName/all/
	incrementDir=$path$platform/$businessName/increment/$apkVer/
	tempDir=$path$platform/$businessName/all/temp/$apkVer/
fi
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
echo $isexist

# 打包到临时目录
if [ $businessName = 'no' ]; then
	rm -rf deploy
	mkdir -p deploy
	#rn资源打包
	react-native bundle --entry-file index.js --platform $platform --dev false --bundle-output deploy/index.jsbundle --assets-dest deploy
else 
	#删除deploy目录下的所有文件
	rm -rf deploy
	mkdir -p deploy/common
	mkdir -p deploy/$businessName
	#rn资源打包
	react-native bundle --entry-file $businessName/index.js --platform $platform --dev false --bundle-output deploy/$businessName/index.jsbundle --assets-dest deploy/$businessName
	if [ $businessName = "common" ]; then
		echo 'COMMON'
	else 
		react-native bundle --entry-file common/index.js --platform $platform --dev false --bundle-output deploy/common/index.jsbundle --assets-dest deploy/common
	fi
fi

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
echo $currentPath
if [ $businessName = 'no' ]; then
	echo 'NOT UNPACK'
elif [ $businessName = "common" ]; then
	echo 'COMMON'
else 
	node pkgCmd/unpack.js $businessName $currentPath/deploy/
fi

#压缩包的名字
zipName="rn_"$apkVer"_"$newVer".zip"
echo $newVer
echo $zipName
#拷贝字体文件到打包文件夹中
if [ $businessName = 'no' ]; then
	if [ ! -e "resource/" ]; then 
		echo 'resource not exist'
	else
		cp -rf resource/ deploy/
	fi
else 
	ttfDir=resource/$businessName/
	echo $ttfDir
	if [ ! -e $ttfDir ]; then 
		echo 'resource not exist'
	else
		cp -rf $ttfDir deploy/
	fi
fi

if [ $businessName = 'no' ]; then
	if [ $isexist = 0 ]; then
		echo 'first pack'
		# if [ $platform = 'android' ]; then
		# 	mkdir -p $currentPath/../android/app/src/main/assets/rn/
		# 	cp -rf deploy/ $currentPath/../android/app/src/main/assets/rn/
		# fi
	fi
	cd deploy	
else 
	cd deploy
	if [ $isexist = 0 ]; then
		echo 'first pack'
		# if [ $platform = 'android' ]; then
		# 	mkdir -p $currentPath/../android/app/src/main/assets/rn/$businessName/
		# 	cp -rf $businessName/ $currentPath/../android/app/src/main/assets/rn/$businessName/
		# fi
	fi
	cd $businessName
fi

#生成压缩包放于deploy/businessName下
zip -r $zipName *
if [ $businessName = 'no' ]; then
	cd ../
	cp deploy/$zipName $configDir
else
	cd ../../
	cp deploy/$businessName/$zipName $configDir
fi
node ./pkgCmd/md5.js $hotConfigDir $apkVer $zipName $content