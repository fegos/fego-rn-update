rm -rf deploy
mkdir deploy
# 公共库打包
react-native bundle --entry-file src/common/index.js --platform android --dev false --bundle-output deploy/common.jsbundle --assets-dest deploy
# module1打包
cd deploy
mkdir module1
cd ..
react-native bundle --entry-file src/Hello/index.js --platform android --dev false --bundle-output deploy/module1/index.jsbundle --assets-dest deploy
# module2打包
cd deploy
mkdir module2
cd ..
react-native bundle --entry-file src/World/index.js --platform android --dev false --bundle-output deploy/module2/index.jsbundle --assets-dest deploy
# 做diff
node ./pkgModuleCmd/unPack.js
# copy 到assets/rn下
# cp -rp deploy/ /Users/sxiaoxia/Desktop/work/kaiyuan/fego-rn-update/hybriddemo/android/app/src/main/assets/rn/