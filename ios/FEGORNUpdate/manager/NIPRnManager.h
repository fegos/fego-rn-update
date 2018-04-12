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

typedef NS_ENUM(NSInteger, NIPHotUpdateStatus) {
    NIPHotUpdateStatusSuccess = 0,
    NIPHotUpdateStatusReadConfigFailed,
    NIPHotUpdateStatusDownloadBundleFailed,
    NIPHotUpdateStatusCheckMD5Failed
    
};


/**
 资源下载成功回调
 */
typedef void (^NIPRNUpdateSuccessBlock)(NSString *JSBundleName);

/**
 资源下载失败回调
 */
typedef void (^NIPRNUpdateFailureBlock)(NSString *JSBundleName, NIPHotUpdateStatus failStatus);


@interface NIPRnManager : NSObject <RCTBridgeModule>

/**
 * 是否使用热更新
 */
@property (nonatomic, assign) BOOL useHotUpdate;

/**
 * 是否使用JSServer
 */
@property (nonatomic, assign) BOOL useJSServer;

/**
 * 本地JSBundle根目录
 */
@property (nonatomic, strong) NSString *localJSBundleRootPath;

/**
 * 本地JSBundle资源压缩包根目录
 */
@property (nonatomic, strong) NSString *localJSBundleZipRootPath;

/**
 * 本地JSBundle配置文件根目录
 */
@property (nonatomic, strong) NSString *localJSBundleConfigRootPath;

/**
 * 远端JSBundle的根目录
 */
@property (nonatomic, copy) NSString *remoteJSBundleRootPath;

/**
 * 字体集名字
 */
@property (nonatomic, copy) NSArray *fontFamilyNameArray;


/**
 * 获取单例
 *
 * @return obj
 */
+ (instancetype)sharedManager;

/**
 * 获取Manager
 *
 * @param remoteJSBundleRoot 远端JSBundle的根目录
 * @param useHotUpdate 是否使用热更新
 * @param useJSServer 是否启用JSServer
 * @return obj
 */
+ (instancetype)managerWithRemoteJSBundleRoot:(NSString *)remoteJSBundleRoot useHotUpdate:(BOOL)useHotUpdate andUseJSServer:(BOOL)useJSServer;

/**
 * 首次启动后根据当前app存放在Document目录和App自带的jsbundle文件初始化所有业务的bundle
 */
- (void)initJSBundle;

/**
 * app与js联通的桥，在manager初始化的时候就生成
 *
 * @param JSBundleName JSBunlde的名字
 *
 * @return RCTBridge
 */
- (RCTBridge *)getBridgeWithJSBundleName:(NSString *)JSBundleName;

/**
 * 热更新完成后，加载存放在Document目录下的被更新的bundle文件
 */
- (void)loadALLJSBundleInDocumentDirectory;

/**
 * 热更新完成后，加载存放在Document目录下指定名字的bundle文件
 */
- (void)loadALLJSBundleInDocumentDirectoryWithName:(NSString *)JSBundleName;

/**
 * 加载默认main bundle的指定模块
 *
 * @param moduleName moduleName
 * @return NIPRnController
 */
- (NIPRnController *)loadRNControllerWithModule:(NSString *)moduleName;

/**
 * 通过bundle和module加载
 *
 * @param JSBundleName JSBundleName
 * @param moduleName moduleName
 * @return NIPRnController
 */
- (NIPRnController *)loadRNControllerWithJSBridgeName:(NSString *)JSBundleName
                                        andModuleName:(NSString *)moduleName;

/**
 * 执行远程请求,请参数含有本地sdkversion、localDataVersion
 * 如果服务器的serverVersion==localVersion，则不抛回数据，否则返回服务器上的新包
 *
 * @param JSBundleName JSBunldeName
 * @param successBlock successBlock
 * @param failureBlock failureBlock
 */
- (void)requestRemoteJSBundleWithName:(NSString *)JSBundleName
                              success:(NIPRNUpdateSuccessBlock)successBlock
                              failure:(NIPRNUpdateFailureBlock)failureBlock;


/**
 * 解压JSBundleZip文件
 */
- (void)unzipJSBundleWithName:(NSString *)JSBundleName;



@end
