mkdir deploy
# 公共库打包
react-native bundle --entry-file src/common/index.js --platform android --dev false --bundle-output deploy/common.jsbundle --assets-dest deploy
# module1打包
react-native bundle --entry-file src/Hello/index.js --platform android --dev false --bundle-output deploy/module1.jsbundle --assets-dest deploy
# module2打包
react-native bundle --entry-file src/World/index.js --platform android --dev false --bundle-output deploy/module2.jsbundle --assets-dest deploy
# common.bundle、module1.bundle做diff获取纯index1.bundle
node ./pkgModuleCmd/unPack.js
# common.bundle、module2.bundle做diff获取纯index2.bundle