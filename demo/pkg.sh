########################新打包逻辑########################
# android/ios 默认全部
platform="no"
# increment/all 选择是增量还是全量，默认increment
type="test"
if [ $# = 1 ]; then
	if [ $1 = 'android' ] || [ $1 = 'ios' ]; then
		platform=$1
	else
		type=$1
	fi
elif [ $# = 2 ]; then
	platform=$1
	type=$2
fi
echo 'platform: '$platform
echo 'type: '$type
user=`who am i | awk '{print $1}'`
echo 'user: '$user
path=`sed -n "/$user/s/[^\']*$user:[^\']*\'\([^\']*\)'.*/\1/p" pkgCmd/config.js`
echo 'path: '$path
apkVer=`sed -n "/apkVer/s/[^\']*apkVer:[^\']*\'\([^\']*\)'.*/\1/p" pkgCmd/config.js`
echo 'apkVer: '$apkVer
bundleName=`sed -n "/bundleName/s/[^\']*bundleName:[^\']*\'\([^\']*\)'.*/\1/p" pkgCmd/config.js`
echo 'bundleName: '$bundleName

if [ $type = 'test' ]; then
	# 主执行脚本
	if [ $platform = 'no' ]; then
		# 全量包生成
		sh ./pkgCmd/allPkg.sh android $path $apkVer $bundleName
		# 增量包生成
		node ./pkgCmd/incregen.js android
		sh ./pkgCmd/allPkg.sh ios $path $apkVer $bundleName
		node ./pkgCmd/incregen.js ios
	else 
		sh ./pkgCmd/allPkg.sh $platform $path $apkVer $bundleName
		node ./pkgCmd/incregen.js $platform
	fi
else 
	# 全量包和增量包生成之后将最终的config更新，可根据脚本参数确定使用增量还是全量，increment/all，
	# 此时需将上述两条注释，打开下面的注释
		if [ $platform = 'no' ]; then
			cp ${path}android/$type/${apkVer}/config ${path}android/${apkVer}_config
			cp ${path}android/$type/${apkVer}/config ${path}ios/${apkVer}_config
		else
			cp $path$platform/$type/${apkVer}/config $path$platform/${apkVer}_config
		fi
fi