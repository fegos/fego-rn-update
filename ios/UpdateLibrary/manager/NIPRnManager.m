//
//  NIPRnManager.m
//  NSIP
//
//  Created by 赵松 on 17/2/23.
//  Copyright © 2017年 netease. All rights reserved.
//

#import "NIPRnManager.h"
#import "NIPRnController.h"
#import "NIPRnUpdateService.h"
#import "NIPRnDefines.h"
#import "NIPRnHotReloadHelper.h"
#import "DiffMatchPatch.h"

#if __has_include(<React/RCTAssert.h>)
#import <React/RCTBridge.h>
#import <React/RCTBundleURLProvider.h>
#else
#import "RCTBridge.h"
#import "RCTBundleURLProvider.h"
#endif

@interface NIPRnManager ()

/**
 *  根据bundle业务名称存储对应的bundle
 */
@property (nonatomic, strong) NSMutableDictionary *JSBundleDictionay;

@property (nonatomic, strong) NIPRnUpdateService *updateService;

@end


@implementation NIPRnManager


#pragma mark - JS Bridge

RCT_EXPORT_MODULE()

/**
 * 初始化
 */
- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        self.localJSBundleRootPath = [documentPath stringByAppendingPathComponent:RN_JSBUNDLE_SUBPATH];
        self.localJSBundleZipRootPath = [documentPath stringByAppendingPathComponent:RN_JSBUNDLE_ZIP_SUBPATH];
        self.localJSBundleConfigRootPath = [documentPath stringByAppendingPathComponent:RN_JSBUNDLE_CONFIG_SUBPATH];
        self.updateService.localJSBundleRootPath = self.localJSBundleRootPath;
        self.updateService.localJSBundleZipRootPath = self.localJSBundleZipRootPath;
        self.updateService.localJSBundleConfigRootPath = self.localJSBundleConfigRootPath;
        self.JSBundleDictionay = [NSMutableDictionary dictionary];
    }
    return self;
}

/**
 * 获取单例
 *
 * @return obj
 */
+ (instancetype)sharedManager {
    return [self managerWithRemoteJSBundleRoot:nil useHotUpdate:YES andUseJSServer:NO];
}

/**
 * 获取Manager
 *
 * @param remoteJSBundleRootPath 远端JSBundle的根目录
 * @param useHotUpdate 是否使用热更新
 * @param useJSServer 是否启用JSServer
 * @return obj
 */
+ (instancetype)managerWithRemoteJSBundleRoot:(NSString *)remoteJSBundleRootPath useHotUpdate:(BOOL)useHotUpdate andUseJSServer:(BOOL)useJSServer {
    static dispatch_once_t onceToken;
    static NIPRnManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
        manager.useHotUpdate = useHotUpdate;
        manager.useJSServer = useJSServer;
        if (noEmptyString(remoteJSBundleRootPath)) {
            manager.remoteJSBundleRootPath = remoteJSBundleRootPath;
            manager.updateService.remoteJSBundleRootPath = remoteJSBundleRootPath;
        }
    });
    return manager;
}

/**
 * 加载所需JSBundle
 * @param JSBundleName JSBundle名
 *
 * @return RCTBridge
 */
- (RCTBridge *)loadJSBundleWithName:(NSString *)JSBundleName {
    BOOL isUpdated = [self.updateService checkIPAVersionUpdateForJSBundleWithName:JSBundleName];
    if (isUpdated) {
        BOOL copySuccess = [self.updateService copyJSBundleFromIPAToDocumentDiretoryWithName:JSBundleName];
        if (copySuccess) {
            [self.updateService recordIPAJSBundleInfoToLocalWithName:JSBundleName];
        }
    }
    RCTBridge *bridge = self.JSBundleDictionay[JSBundleName];
    if (bridge) {
        [bridge reload];
    } else {
        [self.updateService registerFontFamiliesForJSBundle:JSBundleName];
        bridge = [self getBridgeForJSBundleWithName:JSBundleName];
    }
    return bridge;
}

/**
 * 加载所需JSBundles
 * @param JSBundleNameArray JSBundle名称数组
 *
 * @return RCTBridge字典
 */
- (NSDictionary *)loadJSBundlesWithNames:(NSArray *)JSBundleNameArray {
    NSMutableDictionary *bridgeDic = [NSMutableDictionary dictionaryWithCapacity:JSBundleNameArray.count];
    [JSBundleNameArray enumerateObjectsUsingBlock:^(NSString*  _Nonnull JSBundleName, NSUInteger idx, BOOL * _Nonnull stop) {
        RCTBridge *bridge = [self loadJSBundleWithName:JSBundleName];
        bridgeDic[JSBundleName] = bridge;
    }];
    return bridgeDic;
}

/**
 * 加载所有JSBundles
 *
 * return RCTBridge字典
 */
- (NSDictionary *)loadAllJSBundles {
    NSArray *allJSBundleNameArray = [self getAllJSBundleNameArray];
    return [self loadJSBundlesWithNames:allJSBundleNameArray];
}


/**
 * 获取所有bundle名
 */
- (NSArray *)getAllJSBundleNameArray {
    NSArray *bundlePathArray = [[NSBundle mainBundle] pathsForResourcesOfType:nil inDirectory:RN_JSBUNDLE_SUBPATH];
    NSMutableArray *bundleNameArray = [NSMutableArray arrayWithCapacity:bundlePathArray.count];
    [bundlePathArray enumerateObjectsUsingBlock:^(NSString*  _Nonnull bundlePath, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *bundleName = [bundlePath lastPathComponent];
        if (bundleName) {
            [bundleNameArray addObject:bundleName];
        }
    }];
    return bundleNameArray;
}

/**
 * 初始化RCTBridge
 */
- (RCTBridge *)getBridgeForJSBundleWithName:(NSString *)JSBundleName {
    RCTBridge *bridge = nil;
    if (self.useJSServer) {
        NSURL *bundelPath = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index" fallbackResource:@"index"];
        bridge = [[RCTBridge alloc] initWithBundleURL:bundelPath
                                       moduleProvider:nil
                                        launchOptions:nil];
        if (noEmptyString(JSBundleName)) {
            [self.JSBundleDictionay setObject:bridge forKey:JSBundleName];
        } else {
            [self.JSBundleDictionay setObject:bridge forKey:@"index"];
        }
    } else {
        if (noEmptyString(JSBundleName) && ![JSBundleName isEqualToString:COMMON]) {
            NSURL *JSBundelURL = [self getJSBundleURL:JSBundleName];
            bridge = [[RCTBridge alloc] initWithBundleURL:JSBundelURL
                                           moduleProvider:nil
                                            launchOptions:nil];
            [self.JSBundleDictionay setObject:bridge forKey:JSBundleName];
        }
    }
    return bridge;
}

/**
 * 获取JSBundlePath
 */
- (NSURL *)getJSBundleURL:(NSString *)JSBundleName
{
    NSURL *JSBundleURL = nil;
    NSString *subDir = [NSString stringWithFormat:@"%@/%@", RN_JSBUNDLE_SUBPATH, JSBundleName];
    if (self.useHotUpdate) {
        // 优先使用沙盒中存储的JSBundle包
        NSString *JSBundlePath = [NSString stringWithFormat:@"%@/%@/index.%@", self.localJSBundleRootPath, JSBundleName, JSBUNDLE];
        if (![NIPRnHotReloadHelper fileExistAtPath:JSBundlePath]) {
            JSBundlePath = [[NSBundle mainBundle] pathForResource:@"index"
                                                           ofType:JSBUNDLE
                                                      inDirectory:subDir];
        }
        JSBundleURL = [NSURL URLWithString:JSBundlePath];
    } else {
        JSBundleURL = [[NSBundle mainBundle] URLForResource:@"index"
                                              withExtension:JSBUNDLE
                                               subdirectory:subDir];
        
    }
    return JSBundleURL;
}


#pragma mark - 根据业务获取bundle

/**
 * oc与js联通的桥，在manager初始化的时候就生成
 *
 * @param JSBundleName JSBunlde的名字
 *
 * @return RCTBridge
 */
- (RCTBridge *)getBridgeWithJSBundleName:(NSString *)JSBundleName {
    return [self.JSBundleDictionay objectForKey:JSBundleName];
}


#pragma mark - 加载rn controller

/**
 * 加载默认main bundle的指定模块
 *
 * @param moduleName moduleName
 * @return NIPRnController
 */
- (NIPRnController *)loadRNControllerWithModule:(NSString *)moduleName {
    return [self loadRNControllerWithJSBundleName:RN_DEFAULT_BUNDLE_NAME
                                    andModuleName:moduleName];
}

/**
 * 通过bundle和module加载
 *
 * @param JSBundleName JSBundleName
 * @param moduleName moduleName
 * @return NIPRnController
 */
- (NIPRnController *)loadRNControllerWithJSBundleName:(NSString *)JSBundleName
                                        andModuleName:(NSString *)moduleName {
    [self loadJSBundleWithName:JSBundleName];
    NIPRnController *controller = [[NIPRnController alloc] initWithBundleName:JSBundleName
                                                                   moduleName:moduleName];
    return controller;
}

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
                              failure:(NIPRNUpdateFailureBlock)failureBlock {
    NIPRnUpdateService *service = [NIPRnUpdateService sharedService];
    [service requestRemoteJSBundleWithName:JSBundleName
                                   success:successBlock
                                   failure:failureBlock];
}

/**
 * 加载热更新JSBundle
 * @param JSBundleName 包名
 */
- (void)loadNewHotUpdatedJSBundleWithName:(NSString *)JSBundleName {
    NIPRnUpdateService *service = [NIPRnUpdateService sharedService];
    [service loadHotUpdatedJSBundleWithName:JSBundleName];
}


#pragma mark - Getters && Setters

- (NIPRnUpdateService *)updateService {
    if (!_updateService) {
        _updateService = [NIPRnUpdateService sharedService];
    }
    return _updateService;
}

- (void)setRemoteJSBundleRootPath:(NSString *)remoteJSBundleRootPath {
    _remoteJSBundleRootPath = remoteJSBundleRootPath;
    self.updateService.remoteJSBundleRootPath = remoteJSBundleRootPath;
}

- (void)setLocalJSBundleRootPath:(NSString *)localJSBundleRootPath {
    _localJSBundleRootPath = localJSBundleRootPath;
    self.updateService.localJSBundleRootPath = localJSBundleRootPath;
}

- (void)setLocalJSBundleZipRootPath:(NSString *)localJSBundleZipRootPath {
    _localJSBundleZipRootPath = localJSBundleZipRootPath;
    self.updateService.localJSBundleZipRootPath = localJSBundleZipRootPath;
}

- (void)setLocalJSBundleConfigRootPath:(NSString *)localJSBundleConfigRootPath {
    _localJSBundleConfigRootPath = localJSBundleConfigRootPath;
    self.updateService.localJSBundleConfigRootPath = localJSBundleConfigRootPath;
}

@end
