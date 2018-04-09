# android/ios 默认两个平台都生成
platform="no"
# increment/all 选择是增量还是全量，默认increment
type="test"
if [ $# = 1 ]; then
	if [ $1 = 'increment' ] || [ $1 = 'all' ]; then
		type=$1
	else
		platform=$1
	fi
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
apkVer=`sed -n "/apkVer/s/[^\']*apkVer:[^\']*\'\([^\']*\)'.*/\1/p" pkgCmd/config.js`
echo $apkVer
if [ $type = 'test' ]; then
	# 主执行脚本
	if [ $platform = 'no' ]; then
		# 全量包生成
		sh ./pkgCmd/allPkg.sh android $path $apkVer
		# 增量包生成
		node ./pkgCmd/incregen.js android
		sh ./pkgCmd/allPkg.sh ios $path $apkVer
		node ./pkgCmd/incregen.js ios
	else 
		sh ./pkgCmd/allPkg.sh $platform $path $apkVer
		node ./pkgCmd/incregen.js $platform
	fi
else 
	# 全量包和增量包生成之后将最终的config更新，可根据脚本参数确定使用增量还是全量，increment/all，
	# 此时需将上述两条注释，打开下面的注释
	if [ $platform = 'no' ]; then
		cp ${path}android/$type/config $path$platform
		cp ${path}ios/$type/config $path$platform
	else
		cp $path$platform/$type/config $path$platform
	fi
fi