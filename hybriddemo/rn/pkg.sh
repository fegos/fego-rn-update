########################新打包逻辑########################
# android/ios 默认全部
platform="no"
# increment/all 选择是增量还是全量，默认increment
type="test"
# 业务模块名
businessName="no"
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
	type=$2
	businessName=$3
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
		sh ./pkgCmd/allPkg.sh android $path $apkVer $businessName $bundleName
		# 增量包生成
		node ./pkgCmd/incregen.js android $businessName
		sh ./pkgCmd/allPkg.sh ios $path $apkVer $businessName $bundleName
		node ./pkgCmd/incregen.js ios $businessName
	else 
		sh ./pkgCmd/allPkg.sh $platform $path $apkVer $businessName $bundleName
		node ./pkgCmd/incregen.js $platform $businessName
	fi
else 
	# 全量包和增量包生成之后将最终的config更新，可根据脚本参数确定使用增量还是全量，increment/all，
	# 此时需将上述两条注释，打开下面的注释
	if [ $businessName = 'no' ]; then
		if [ $platform = 'no' ]; then
			cp ${path}android/$type/${apkVer}/config ${path}android/${apkVer}_config
			cp ${path}android/$type/${apkVer}/config ${path}ios/${apkVer}_config
		else
			cp $path$platform/$type/${apkVer}/config $path$platform/${apkVer}_config
		fi
	else
		if [ $platform = 'no' ]; then
			cp ${path}android/$businessName/$type/${apkVer}/config ${path}android/$businessName/${apkVer}_config
			cp ${path}android/$businessName/$type/${apkVer}/config ${path}ios/$businessName/${apkVer}_config
		else
			cp $path$platform/$businessName/$type/${apkVer}/config $path$platform/$businessName/${apkVer}_config
		fi
	fi
fi