# rm -rf deploy
# mkdir deploy
# # 公共库打包
# react-native bundle --entry-file common/index.js --platform android --dev false --bundle-output deploy/common.jsbundle --assets-dest deploy
# # module1打包
# cd deploy
# mkdir Hello
# cd ..
# react-native bundle --entry-file Hello/index.js --platform android --dev false --bundle-output deploy/Hello/index.jsbundle --assets-dest deploy
# # module2打包
# cd deploy
# mkdir World
# cd ..
# react-native bundle --entry-file World/index.js --platform android --dev false --bundle-output deploy/World/index.jsbundle --assets-dest deploy
# # 做diff
# node ./pkgModuleCmd/unPack.js Hello
# node ./pkgModuleCmd/unPack.js World
# copy 到assets/rn下
# cp -rp deploy/ /Users/sxiaoxia/Desktop/work/kaiyuan/fego-rn-update/hybriddemo/android/app/src/main/assets/rn/
########################新打包逻辑########################
# android/ios 默认android
platform="android"
# increment/all 选择是增量还是全量，默认increment
type="test"
# 业务模块名
businessName="common"
if [ $# = 1 ]; then
	if [ $1 = 'android' ] || [ $1 = 'ios' ]; then
		platform=$1
	elif [ $1 = 'increment' ] || [ $1 = 'all' ]; then
		type=$1
	else
		businessName=$1
	fi
elif [ $# = 2 ]; then
	if [ $1 = 'android' ] || [ $1 = 'ios' ]; then
		platform=$1
		if [ $2 = 'increment' ] || [ $2 = 'all' ]; then
			type=$2
		else 
			businessName=$2
		fi
	else
		type=$1
		businessName=$2
	fi
elif [ $# = 3 ]; then
	platform=$1
	businessName=$2
	type=$3
fi
echo $platform
echo $type
user=`who am i | awk '{print $1}'`
echo $user
path=`sed -n "/$user/s/[^\']*$user:[^\']*\'\([^\']*\)'.*/\1/p" pkgModuleCmd/config.js`
echo $path
sdkVer=`sed -n "/sdkVer/s/[^\']*sdkVer:[^\']*\'\([^\']*\)'.*/\1/p" pkgModuleCmd/config.js`
echo $sdkVer

if [ $type = 'test' ]; then
	# 主执行脚本
	# 全量包生成
	sh ./pkgModuleCmd/pack.sh $platform $path $sdkVer $businessName
	# 增量包生成
	# node ./pkgCmd/incregen.js $platform
else 
	# 全量包和增量包生成之后将最终的config更新，可根据脚本参数确定使用增量还是全量，increment/all，
	# 此时需将上述两条注释，打开下面的注释
	cp $path$platform/$businessName/$type/config $path$platform/$businessName
fi