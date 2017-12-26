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

+ (instancetype)sharedManager;
/**
 * bundleUrl: 服务器存放bundle的地址
 * noHotUpdate: 用来标记只使用工程自带的rn包，不支持热更新 default:NO
 * noJsServer: 不通过本地启动的server来获取bundle，直接使用离线包 default:NO
 */
+ (instancetype)managerWithBundleUrl:(NSString *)bundleUrl noHotUpdate:(BOOL)noHotUpdate noJsServer:(BOOL)noJsServer;
/**
 *  oc与js联通的桥，在manager初始化的时候就生成
 */
- (RCTBridge *)getBridgeByBundleName:(NSString *)bundleName;

/**
 *  热更新完成后，加载存放在Document目录下的被更新的bundle文件
 */
- (void)loadBundleUnderDocument;
/**
 *  首次启动后根据当前app 存放在Document目录和App自带的jsbundle文件初始化所有业务的bundle
 */
- (void)initBridgeBundle;

/**
 *  加载默认main bundle的指定模块
 */
- (NIPRnController *)loadControllerWithModel:(NSString *)moduleName;

- (NIPRnController *)loadWithBundleName:(NSString *)bundleName
                             moduleName:(NSString *)moduleName;

//- (NIPRnController *)topMostController;

/**
 *  后台静默下载rn资源包
 */
- (void)requestRCTAssetsBehind;

@property (nonatomic, assign) BOOL noHotUpdate;
@property (nonatomic, assign) BOOL noJsServer;
@property (nonatomic, copy) NSString *bundleUrl;
@property (nonatomic, copy) NSArray *fontNames;

@end
