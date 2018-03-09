# android/ios 默认android
platform="android"
# increment/all 选择是增量还是全量，默认increment
type="increment"
if [ $# = 1 ]; then
	platform=$1
elif [ $# = 2 ]; then
	platform=$1
	type=$2
fi
echo $platform
echo $type
user=`who am i | awk '{print $1}'`
echo $user
path=`sed -n "/$user/s/[^\']*$user:[^\']*\'\([^\']*\)'.*/\1/p" pkgCmd/config.js`
echo $path
sdkVer=`sed -n "/sdkVer/s/[^\']*sdkVer:[^\']*\'\([^\']*\)'.*/\1/p" pkgCmd/config.js`
echo $sdkVer

# 主执行脚本
# 全量包生成
sh ./pkgCmd/pack.sh $platform $path $sdkVer
# 增量包生成
node ./pkgCmd/incregen.js $platform

# 全量包和增量包生成之后将最终的config更新，可根据脚本参数确定使用增量还是全量，increment/all，
# 此时需将上述两条注释，打开下面的注释
# cp $path$platform/$type/config $path$platform