//
//  NIPRnDefines.h
//  NSIP
//
//  Created by 赵松 on 17/2/23.
//  Copyright © 2017年 netease. All rights reserved.
//

/**
 rctversion解析版本号,升级此版本号将会强制下载最新的包,
 策略是当本地数据的sdkversion != 客户端的sdkversion,自动设置本地数据localDataVersion=0
 */

#pragma mark- APP Info

/**
 * APP信息
 */
#define APP_VERSION [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"]
#define APP_BUILD [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"]
#define APP_IDENTIFIER [[[[NSBundle mainBundle] infoDictionary][@"CFBundleIdentifier"] componentsSeparatedByString:@"."] lastObject]
#define APP_SCHEME [[[[[[NSMutableDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"]] objectForKey:@"CFBundleURLTypes"] firstObject] objectForKey:@"CFBundleURLSchemes"] firstObject]

/**
 * 程序包中自带RN的bundle版本
 */
#define DEFAULT_BUNDLE_VERSION @"0"

/**
 * 不拆包时的默认包名
 */
#define RN_DEFAULT_BUNDLE_NAME @"default_bundle"

/**
 * RNJSBundle版本信息键值
 */
#define RN_APP_VERSION @"RN_APP_VERSION"
#define RN_BUILD_VERSION @"RN_BUILD_VERSION"
#define RN_BUNDLE_VERSION @"RN_BUNDLE_VERSION"
#define RN_BUNDLE_LOW_VERSION @"RN_BUNDLE_LOW_VERSION"
#define RN_BUNDLE_INCREMENT_FLAG @"RN_BUNDLE_INCREMENT_FLAG"
#define RN_BUNDLE_MD5 @"RN_BUNDLE_MD5"

/**
 * 本地用户偏好设置中的键值
 */
#define LOCAL_RN_BUNDLE_INFO @"LOCAL_RN_BUNDLE_INFO"
#define LOCAL_RN_BUNDLE_ZIP_INFO @"LOCAL_RN_BUNDLE_ZIP_INFO"

/**
 * 默认文件类型和文件路径配置
 */
#define JSBUNDLE @"jsbundle"
#define ZIP @"zip"
#define COMMON @"common"
#define RN_JSBUNDLE_SUBPATH @"RNJSBundles"
#define RN_JSBUNDLE_ZIP_SUBPATH @"RNJSBundleZips"
#define RN_JSBUNDLE_CONFIG_SUBPATH @"RNJSBundleConfigs"



#pragma mark - nil & null & class

#define noEmptyString(tempString) ([tempString isKindOfClass:[NSString class]] && tempString.length && !([tempString compare:@"null" options:NSCaseInsensitiveSearch] == NSOrderedSame))
#define noEmptyArray(tempArray) ([tempArray isKindOfClass:[NSArray class]] && tempArray.count > 0)

// --忽略未定义方法警告
#define  HOTRELOAD_SUPPRESS_Undeclaredselector_WARNING(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wundeclared-selector\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)
