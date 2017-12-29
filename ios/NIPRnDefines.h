//
//  NIPRnDefines.h
//  NSIP
//
//  Created by 赵松 on 17/2/23.
//  Copyright © 2017年 netease. All rights reserved.
//

//下方的RCT_LOCAL与USE_JS_SERVER已弃用，请在AppDelegate.m中的loadRnController方法设置[NIPRnManager managerWithBundleUrl:nil noHotUpdate:* noJsServer:*]
/**
 *  用来标记只使用工程自带的rn包，不支持热更新. deprecated!!
 */
//#define RCT_LOCAL

/**
 * 开启js server的开关 deprecated!!
 */
//#define USE_JS_SERVER

#define JSBUNDLE @"jsbundle"

/**
 rctversion解析版本号,升级此版本号将会强制下载最新的包,
 策略是当本地数据的sdkversion != 客户端的sdkversion,自动设置本地数据localDataVersion=0
 */
#pragma mark- APP Info
#define APP_VERSION [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]
#define APP_BUILD [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]
#define APP_IDENTIFIER [[[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"] componentsSeparatedByString:@"."] lastObject]
#define APP_SCHEME [[[[[[NSMutableDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"]] objectForKey:@"CFBundleURLTypes"] firstObject] objectForKey:@"CFBundleURLSchemes"] firstObject]

#pragma mark - RN define
#define NIP_RN_SDK_VERSION APP_VERSION
/// 每次打包都要保证app的build号加1
#define NIP_RN_BUILD_VERSION APP_BUILD
/// 每次发新版建议 1.若远程有对应RN包，则与远端RN包版本号同步 2.若远端尚无对应这个app版本的RN包，则此值归0 (不修改也不会出现问题)
#define NIP_RN_DATA_VERSION @"0"

#define RN_SDK_VERSION @"RN_SDK_VERSION"
#define RN_DATA_VERSION @"RN_DATA_VERSION"
#define APP_BUILD_VERSION @"APP_BUILD_VERSION"

#pragma mark - nil & null & class
#define hotreload_notEmptyString(tempString) ([tempString isKindOfClass:[NSString class]] && tempString.length && !([tempString compare:@"null" options:NSCaseInsensitiveSearch] == NSOrderedSame))
#define hotreload_notEmptyArray(tempArray) ([tempArray isKindOfClass:[NSArray class]] && tempArray.count > 0)

// --忽略未定义方法警告
#define  HOTRELOAD_SUPPRESS_Undeclaredselector_WARNING(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wundeclared-selector\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)
