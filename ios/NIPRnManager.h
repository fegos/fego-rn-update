//
//  NIPRnManager.h
//  NSIP
//
//  Created by 赵松 on 17/2/23.
//  Copyright © 2017年 netease. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<React/RCTAssert.h>)
#import <React/RCTBridgeModule.h>
#else
#import "RCTBridgeModule.h"
#endif

@class NIPRnController;

@interface NIPRnManager : NSObject <RCTBridgeModule>

/**
 获取单例

 @return obj
 */
+ (instancetype)sharedManager;

/**
 获取Manager

 @param bundleUrl 服务器存放bundle的地址
 @param noHotUpdate 用来标记只使用工程自带的rn包，不支持热更新 default:NO
 @param noJsServer 不通过本地启动的server来获取bundle，直接使用离线包 default:NO
 @return obj
 */
+ (instancetype)managerWithBundleUrl:(NSString *)bundleUrl noHotUpdate:(BOOL)noHotUpdate noJsServer:(BOOL)noJsServer;
/**
 oc与js联通的桥，在manager初始化的时候就生成

 @param bundleName bundleName
 @return RCTBridge
 */
- (RCTBridge *)getBridgeByBundleName:(NSString *)bundleName;

/**
 热更新完成后，加载存放在Document目录下的被更新的bundle文件
 */
- (void)loadBundleUnderDocument;
/**
 首次启动后根据当前app 存放在Document目录和App自带的jsbundle文件初始化所有业务的bundle
 */
- (void)initBridgeBundle;

/**
 加载默认main bundle的指定模块

 @param moduleName moduleName
 @return NIPRnController
 */
- (NIPRnController *)loadControllerWithModel:(NSString *)moduleName;

/**
 通过bundle和module加载

 @param bundleName bundleName
 @param moduleName moduleName
 @return NIPRnController
 */
- (NIPRnController *)loadWithBundleName:(NSString *)bundleName
                             moduleName:(NSString *)moduleName;

//- (NIPRnController *)topMostController;

/**
 后台静默下载rn资源包
 */
- (void)requestRCTAssetsBehind;

/**
 是否支持热更新
 */
@property (nonatomic, assign) BOOL noHotUpdate;
/**
 是否不使用jsServer
 */
@property (nonatomic, assign) BOOL noJsServer;
/**
 bundle的url
 */
@property (nonatomic, copy) NSString *bundleUrl;
/**
 字体名字
 */
@property (nonatomic, copy) NSArray *fontNames;

@end
