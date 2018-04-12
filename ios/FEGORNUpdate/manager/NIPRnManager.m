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
    return [self managerWithRemoteJSBundleRoot:nil useHotUpdate:YES andUseJSServer:YES];
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
        [manager initJSBundle];
    });
    return manager;
}

/**
 *  获取当前app内存在的所有bundle
 *  首先获取位于docment沙盒目录下的jsbundle文件
 *  然后获取位于app包内的jsbundle文件
 *  将文件的路径放在一个字典里，如果有重复以document优先
 */
- (void)initJSBundle {
    NSArray *JSBundleNameArray = [self getJSBundleNameArray];
    [self checkVersionUpdateForJSBundleWithNames:JSBundleNameArray];
    [self loadJSBundleWithNames:JSBundleNameArray];
}

/**
 * 获取所有bundle名
 */
- (NSArray *)getJSBundleNameArray {
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
 * 检查版本更新
 */
- (void)checkVersionUpdateForJSBundleWithNames:(NSArray *)JSBundleNames {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *localRNBundleInfo = [userDefaults objectForKey:LOCAL_JS_BUNDLE_INFO];
    [JSBundleNames enumerateObjectsUsingBlock:^(NSString*  _Nonnull bundleName, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *bundleInfo = localRNBundleInfo[bundleName];
         BOOL needCopyRNBundle = NO;
        if (bundleInfo) {
            NSString *localAppVersion = bundleInfo[LOCAL_APP_VERSION];
            NSString *localBuildVersion = bundleInfo[LOCAL_BUILD_VERSION];
            if (!noEmptyString(localAppVersion) ||
                ![localAppVersion isEqualToString:APP_VERSION]) {
                needCopyRNBundle = YES;
            } else if (!noEmptyString(localBuildVersion) ||
                       ![localBuildVersion isEqualToString:APP_BUILD]) {
                needCopyRNBundle = YES;
            }
        } else {
            needCopyRNBundle = YES;
        }
        if (needCopyRNBundle) {
            [self copyJSBundleToDocumentDiretoryWithName:bundleName];
        }
    }];
}

/**
 * 更新本地RN资源版本信息
 */
- (void)updateLocalJSBundleInfoWithName:(NSString *)JSBundleName {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *localJSBundleInfo = [NSMutableDictionary dictionaryWithDictionary:[userDefaults objectForKey:LOCAL_JS_BUNDLE_INFO]];
    NSMutableDictionary *bundleInfo = [NSMutableDictionary dictionaryWithDictionary:localJSBundleInfo[JSBundleName]];
    bundleInfo[LOCAL_APP_VERSION] = APP_VERSION;
    bundleInfo[LOCAL_BUILD_VERSION] = APP_BUILD;
    bundleInfo[LOCAL_BUNDLE_VERSION] = DEFAULT_BUNDLE_VERSION;
    localJSBundleInfo[JSBundleName] = bundleInfo;
    [userDefaults setObject:localJSBundleInfo forKey:LOCAL_JS_BUNDLE_INFO];
}

/**
 * 将RN数据从主bundle拷贝到沙盒路径下
 */
- (void)copyJSBundleToDocumentDiretoryWithName:(NSString *)JSBundleName {
    NSString *srcBundlePath = [[NSBundle mainBundle] pathForResource:JSBundleName ofType:nil inDirectory:RN_JSBUNDLE_SUBPATH];
    NSString *dstBundlePath =  [self.localJSBundleRootPath stringByAppendingPathComponent:JSBundleName];
    BOOL bundleCopySuccess = [NIPRnHotReloadHelper copyFolderAtPath:srcBundlePath toPath:dstBundlePath];
    
    if (bundleCopySuccess) {
        [self updateLocalJSBundleInfoWithName:JSBundleName];
    }
}

/**
 * 加载JSBundle
 */
- (void)loadJSBundleWithNames:(NSArray *)JSBundleNameArray {
    if (self.useJSServer) {
        NSURL *bundelPath = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index" fallbackResource:@"index"];
        RCTBridge *bridge = [[RCTBridge alloc] initWithBundleURL:bundelPath
                                                  moduleProvider:nil
                                                   launchOptions:nil];
        if (JSBundleNameArray.count) {
            for (NSString *JSBundleName in JSBundleNameArray) {
                [self.JSBundleDictionay setObject:bridge forKey:JSBundleName];
            }
        } else {
            [self.JSBundleDictionay setObject:bridge forKey:@"index"];
        }
    } else {
        for (NSString *JSBundleName in JSBundleNameArray) {
            if (![JSBundleName isEqualToString:COMMON]) {
                NSURL *JSBundelURL = [self getJSBundleURL:JSBundleName];
                RCTBridge *bridge = [[RCTBridge alloc] initWithBundleURL:JSBundelURL
                                                          moduleProvider:nil
                                                           launchOptions:nil];
                [self.JSBundleDictionay setObject:bridge forKey:JSBundleName];
            }
        }
    }
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

/**
 * 热更新完成后，加载存放在Document目录下的被更新的bundle文件
 */
- (void)loadALLJSBundleInDocumentDirectory {
    NSMutableArray *JSBunleNameArray = [NSMutableArray arrayWithCapacity:10];
    
    NSError *err;
    NSArray *allJSBundleNameArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.localJSBundleRootPath error:&err];
    if (!err) {
        for (NSString *JSBundleName in allJSBundleNameArray) {
            if (![JSBundleName isEqualToString:COMMON]) {
                [JSBunleNameArray addObject:JSBundleName];
            }
        }
    }
    [self loadJSBundleWithNames:JSBunleNameArray];
}

/**
 * 热更新完成后，加载存放在Document目录下指定名字的bundle文件
 */
- (void)loadALLJSBundleInDocumentDirectoryWithName:(NSString *)JSBundleName {
     [self loadJSBundleWithNames:@[JSBundleName]];
}


#pragma mark - 加载rn controller

/**
 * 加载默认main bundle的指定模块
 *
 * @param moduleName moduleName
 * @return NIPRnController
 */
- (NIPRnController *)loadRNControllerWithModule:(NSString *)moduleName {
    return [self loadRNControllerWithJSBridgeName:@"index"
                                    andModuleName:moduleName];
}

/**
 * 通过bundle和module加载
 *
 * @param JSBundleName JSBundleName
 * @param moduleName moduleName
 * @return NIPRnController
 */
- (NIPRnController *)loadRNControllerWithJSBridgeName:(NSString *)JSBundleName
                                        andModuleName:(NSString *)moduleName {
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
 * 解压JSBundleZip文件
 */
- (void)unzipJSBundleWithName:(NSString *)JSBundleName {
    NIPRnUpdateService *service = [NIPRnUpdateService sharedService];
    [service unzipJSBundleWithName:JSBundleName];
}


#pragma mark - Getters && Setters

- (NIPRnUpdateService *)updateService {
    if (_updateService) {
        _updateService = [NIPRnUpdateService sharedService];
    }
    return _updateService;
}


@end
