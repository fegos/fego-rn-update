//
//  NIPRnDefines.h
//  NSIP
//
//  Created by 赵松 on 17/2/23.
//  Copyright © 2017年 netease. All rights reserved.
//

#define JSBUNDLE @"jsbundle"
#define ZIP @"zip"
#define COMMON @"common"
#define RN_JSBUNDLE_SUBPATH @"RNJSBundles"
#define RN_JSBUNDLE_ZIP_SUBPATH @"RNJSBundleZips"
#define RN_JSBUNDLE_CONFIG_SUBPATH @"RNJSBundleConfigs"

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
 * 本地bundle包版本信息
 */
#define LOCAL_APP_VERSION @"LOCAL_APP_VERSION"
#define LOCAL_BUILD_VERSION @"LOCAL_BUILD_VERSION"
#define LOCAL_BUNDLE_VERSION @"LOCAL_BUNDLE_VERSION"

/**
 * 远端bundle包版本信息
 */
#define REMOTE_APP_VERSION @"REMOTE_APP_VERSION"
#define REMOTE_BUILD_VERSION @"REMOTE_BUILD_VERSION"
#define REMOTE_BUNDLE_VERSION @"REMOTE_BUNDLE_VERSION"
#define REMOTE_BUNDLE_LOW_VERSION @"REMOTE_BUNDLE_LOW_VERSION"
#define REMOTE_BUNDLE_INCREMENT_FLAG @"REMOTE_BUNDLE_INCREMENT_FLAG"
#define REMOTE_BUNDLE_MD5 @"REMOTE_BUNDLE_MD5"

#define LOCAL_JS_BUNDLE_INFO @"LOCAL_JS_BUNDLE_INFO"
#define LOCAL_JS_BUNDLE_ZIP_INFO @"LOCAL_JS_BUNDLE_ZIP_INFO"


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
