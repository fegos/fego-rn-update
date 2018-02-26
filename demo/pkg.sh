platform="ios"
if [ $# = 1 ]; then
	if [ $1 = 'ios' ];then
		platform="ios"
	elif [ $1 = 'android' ];then
		platform="android"
	fi
fi
sh ./pkgCmd/pack.sh $platform
node ./pkgCmd/incregen.js $platform
