//
//  NIPRnUpdateService.m
//  NSIP
//
//  Created by 赵松 on 17/3/30.
//  Copyright © 2017年 netease. All rights reserved.
//

#import <AFNetworking/AFHTTPSessionManager.h>
#import <ZipArchive/ZipArchive.h>
#import "NIPRnUpdateService.h"
#import "DiffMatchPatch.h"
#import "NIPRnHotReloadHelper.h"
#import "NIPRnDefines.h"



@interface NIPRnUpdateService ()

@property (nonatomic, strong) AFHTTPSessionManager *httpSession;


/**
 * 当前JSBundleName
 */
@property (nonatomic, strong) NSString *curJSBundleName;

/**
 * 本地资源包信息
 */
@property (nonatomic, strong) NSMutableDictionary *localJSBundleInfoDic;

/**
 * 本地资源压缩包信息
 */
@property (nonatomic, strong) NSMutableDictionary *localJSBundleZipInfoDic;

/**
 * 远端资源包信息
 */
@property (nonatomic, strong) NSMutableDictionary *remoteJSBundleInfoDic;

/**
 * 强制更新字典
 */
@property (nonatomic, strong) NSMutableDictionary *forceUpdateBundleDic;

/**
 *
 */
@property (nonatomic, strong) NSMutableDictionary *downloadTaskDic;

@property (nonatomic, copy) NIPRNUpdateSuccessBlock successBlock;
@property (nonatomic, copy) NIPRNUpdateFailureBlock failureBlock;

@end

@implementation NIPRnUpdateService

/**
 * 获取单例
 *
 * @return obj
 */
+ (instancetype)sharedService {
    static NIPRnUpdateService *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.localJSBundleInfoDic = [NSMutableDictionary dictionary];
        self.localJSBundleZipInfoDic = [NSMutableDictionary dictionary];
        self.remoteJSBundleInfoDic = [NSMutableDictionary dictionary];
        self.forceUpdateBundleDic = [NSMutableDictionary dictionary];
        self.downloadTaskDic = [NSMutableDictionary dictionary];
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.httpSession = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
        self.httpSession.requestSerializer.timeoutInterval = 20;
    }
    return self;
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
    self.curJSBundleName = JSBundleName;
    self.successBlock = successBlock;
    self.failureBlock = failureBlock;
    
    // 假如用户没有传入成功回调，则默认为强制更新
    if (!successBlock) {
        self.forceUpdateBundleDic[JSBundleName] = @YES;
    }
    [self readLocalJSBundleInfoWithName:JSBundleName];
    [self readLocalJSBundleZipInfoWithName:JSBundleName];
    [self requestRemoteJSBundleConfigWithName:JSBundleName];
}


/**
 * 读取本地JSBundle信息
 */
- (void)readLocalJSBundleInfoWithName:(NSString *)JSBundleName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *localJSBundleInfoDic = [defaults objectForKey:LOCAL_JS_BUNDLE_INFO];
    NSDictionary *localJSBundleInfo = localJSBundleInfoDic[JSBundleName];
    if (localJSBundleInfo) {
        self.localJSBundleInfoDic[JSBundleName] = localJSBundleInfo;
    }
}

/**
 * 读取本地JSBundle压缩包信息
 */
- (void)readLocalJSBundleZipInfoWithName:(NSString *)JSBundleName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *localJSBundleZipInfoDic = [defaults objectForKey:LOCAL_JS_BUNDLE_ZIP_INFO];
    NSDictionary *localJSBundleZipInfo = localJSBundleZipInfoDic[JSBundleName];
    if (localJSBundleZipInfo) {
        self.localJSBundleZipInfoDic[JSBundleName] = localJSBundleZipInfo;
    }
}

/**
 * 记录本地JSBundle信息
 */
- (void)recordLocalJSBundleInfoWithName:(NSString *)JSBundleName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *localJSBundleInfoDic = [defaults objectForKey:LOCAL_JS_BUNDLE_ZIP_INFO];
    NSDictionary *localJSBundleInfo = localJSBundleInfoDic[JSBundleName];
    NSMutableDictionary *mutableJSBundleInfo = [localJSBundleInfo mutableCopy];
    NSMutableDictionary *mutableJSBundleInfoDic = [localJSBundleInfoDic mutableCopy];
    NSDictionary *remoteJSBundleInfo = self.remoteJSBundleInfoDic[JSBundleName];
    
    if (remoteJSBundleInfo) {
        mutableJSBundleInfo[LOCAL_BUNDLE_VERSION] = remoteJSBundleInfo[REMOTE_BUNDLE_VERSION];
        mutableJSBundleInfoDic[JSBundleName] = mutableJSBundleInfo;
        [defaults setObject:mutableJSBundleInfoDic forKey:LOCAL_JS_BUNDLE_INFO];
    }
}

/**
 * 记录本地JSBundle压缩包信息
 */
- (void)recordLocalJSBundleZipInfoWithName:(NSString *)JSBundleName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *localJSBundleZipInfoDic = [defaults objectForKey:LOCAL_JS_BUNDLE_ZIP_INFO];
    NSDictionary *localJSBundleZipInfo = localJSBundleZipInfoDic[JSBundleName];
    NSMutableDictionary *mutableJSBundleZipInfo = [localJSBundleZipInfo mutableCopy];
    NSMutableDictionary *mutableJSBundleZipInfoDic = [localJSBundleZipInfoDic mutableCopy];
    NSDictionary *remoteJSBundleInfo = self.remoteJSBundleInfoDic[JSBundleName];
    if (!mutableJSBundleZipInfoDic) {
        mutableJSBundleZipInfoDic = [NSMutableDictionary dictionary];
    }
    if (!mutableJSBundleZipInfo) {
        mutableJSBundleZipInfo = [NSMutableDictionary dictionary];
    }
    
    if (remoteJSBundleInfo) {
        mutableJSBundleZipInfo[LOCAL_APP_VERSION] = remoteJSBundleInfo[REMOTE_APP_VERSION];
        mutableJSBundleZipInfo[LOCAL_BUNDLE_VERSION] = remoteJSBundleInfo[REMOTE_BUNDLE_VERSION];
        mutableJSBundleZipInfoDic[JSBundleName] = mutableJSBundleZipInfo;
        [defaults setObject:mutableJSBundleZipInfoDic forKey:LOCAL_JS_BUNDLE_ZIP_INFO];
    }
}

/**
 * 删除本地JSBundle压缩包信息
 */
- (void)removeLocalJSBundleZipInfoWithName:(NSString *)JSBundleName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *localJSBundleZipInfoDic = [defaults objectForKey:LOCAL_JS_BUNDLE_ZIP_INFO];
    NSDictionary *localJSBundleZipInfo = localJSBundleZipInfoDic[JSBundleName];
    NSMutableDictionary *mutableJSBundleZipInfo = [localJSBundleZipInfo mutableCopy];
    NSMutableDictionary *mutableJSBundleZipInfoDic = [localJSBundleZipInfoDic mutableCopy];
    if (mutableJSBundleZipInfoDic && mutableJSBundleZipInfo) {
        mutableJSBundleZipInfoDic[JSBundleName] = nil;
        [defaults setObject:mutableJSBundleZipInfoDic forKey:LOCAL_JS_BUNDLE_ZIP_INFO];
    }
}

/**
 *  下载远程配置文件
 */
- (void)requestRemoteJSBundleConfigWithName:(NSString *)JSBundleName {
    __weak __typeof(self) weakSelf = self;
    NSString *remoteConfigPath = nil;
    if ([JSBundleName isEqualToString:RN_DEFAULT_BUNDLE_NAME]) {
        remoteConfigPath = [NSString stringWithFormat:@"%@config", self.remoteJSBundleRootPath];
    } else {
        remoteConfigPath = [NSString stringWithFormat:@"%@%@/config", self.remoteJSBundleRootPath, JSBundleName];
    }
    NSURL *URL = [NSURL URLWithString:remoteConfigPath];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    NSURLSessionDownloadTask *task = [_httpSession downloadTaskWithRequest:request
                                                                  progress:nil
                                                               destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                                                                   [weakSelf getConfigFileDirForJSBundle:JSBundleName];
//                                                                   NSURL *tempFileURL = [NSURL URLWithString:[self.localJSBundleRootPath stringByDeletingLastPathComponent]];
//                                                                   return [tempFileURL URLByAppendingPathComponent:[response suggestedFilename]];
                                                                   NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
                                                                   NSURL *configURL = [documentsDirectoryURL URLByAppendingPathComponent:RN_JSBUNDLE_CONFIG_SUBPATH];
                                                                   NSURL *bundleConfigURL = [configURL URLByAppendingPathComponent:JSBundleName];
                                                                   
                                                                   return [bundleConfigURL URLByAppendingPathComponent:[response suggestedFilename]];
                                                               }
                                                         completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                                                             __strong __typeof(weakSelf) strongSelf = weakSelf;
                                                             if (error) {
                                                                 if ([strongSelf.curJSBundleName isEqualToString:JSBundleName] &&
                                                                     strongSelf.failureBlock) {
                                                                     strongSelf.failureBlock(JSBundleName, NIPHotUpdateStatusReadConfigFailed);
                                                                 }
                                                             } else {
                                                                 NSString *configFilePath = [filePath absoluteString];
                                                                 if ([configFilePath hasPrefix:@"file://"]) {
                                                                     configFilePath = [configFilePath substringFromIndex:7];
                                                                 }
                                                                 [strongSelf readConfigFile:configFilePath
                                                                                   withName:JSBundleName];
                                                             }
                                                         }];
    [self recordDownloadTask:task withType:@"config" forJSBundle:JSBundleName];
    [task resume];
}


/**
 * 读取配置文件
 *
 * @param configFilePath configFilePath
 * @param JSBundleName JSBundleName
 */
- (void)readConfigFile:(NSString *)configFilePath withName:(NSString *)JSBundleName {
    NSString *config = [NSString stringWithContentsOfFile:configFilePath
                                                 encoding:NSUTF8StringEncoding
                                                    error:nil];
    NSArray *configItems = [config componentsSeparatedByString:@","];
    
    [NIPRnHotReloadHelper removeFileAtPath:configFilePath];
    
    NSDictionary *localJSBundleInfo = self.localJSBundleInfoDic[JSBundleName];
    if (!localJSBundleInfo) {
        return;
    }
    NSDictionary *localJSBundleZipInfo = self.localJSBundleZipInfoDic[JSBundleName];
    NSString *localAppVersion = localJSBundleInfo[LOCAL_APP_VERSION];
    NSString *localBundleVersion = localJSBundleInfo[LOCAL_BUNDLE_VERSION];
    if (localJSBundleZipInfo) {
        if ([localAppVersion compare:localJSBundleZipInfo[LOCAL_APP_VERSION]] == NSOrderedAscending) {
            localAppVersion = localJSBundleZipInfo[LOCAL_APP_VERSION];
            localBundleVersion = localJSBundleZipInfo[LOCAL_BUNDLE_VERSION];
        } else if ([localAppVersion isEqualToString:localJSBundleZipInfo[LOCAL_APP_VERSION]] &&
                   [localBundleVersion compare:localJSBundleZipInfo[LOCAL_BUNDLE_VERSION]] == NSOrderedAscending) {
            localBundleVersion = localJSBundleZipInfo[LOCAL_BUNDLE_VERSION];
        }
    }
    
    BOOL needDownload = NO;
    for (NSString *configItem in configItems) {
        NSArray *items = [configItem componentsSeparatedByString:@"_"];
        if (items.count > 1) {
            NSString *remoteAppVersion = items[0];
            NSString *remoteBundleVersion = items[1];
            if (items.count == 3) {
                if ([localAppVersion isEqualToString:remoteAppVersion] &&
                    [localBundleVersion compare:remoteBundleVersion] == NSOrderedAscending) {
                    needDownload = YES;
                }
                if (needDownload) {
                    NSDictionary *JSBundleInfo = @{
                                                   REMOTE_APP_VERSION : remoteAppVersion,
                                                   REMOTE_BUNDLE_VERSION : remoteBundleVersion,
                                                   REMOTE_BUNDLE_MD5 : items[2]
                                                   };
                    self.remoteJSBundleInfoDic[JSBundleName] = JSBundleInfo;
                    [self downloadRemoteJSBundleWithName:JSBundleName];
                    break;
                }
            } else if (items.count == 5) {
                NSString *remoteLowBundleVersion = items[2];
                if ([localAppVersion isEqualToString:remoteAppVersion] &&
                    [localBundleVersion compare:remoteBundleVersion] == NSOrderedAscending &&
                    [localJSBundleInfo[LOCAL_APP_VERSION] isEqualToString:remoteLowBundleVersion]) {
                    needDownload = YES;
                }
                if (needDownload) {
                    NSDictionary *remoteJSBundleInfo = @{
                                                         REMOTE_APP_VERSION : remoteAppVersion,
                                                         REMOTE_BUNDLE_VERSION : remoteBundleVersion,
                                                         REMOTE_BUNDLE_LOW_VERSION : remoteLowBundleVersion,
                                                         REMOTE_BUNDLE_INCREMENT_FLAG : items[3],
                                                         REMOTE_BUNDLE_MD5 : items[4]
                                                         };
                    self.remoteJSBundleInfoDic[JSBundleName] = remoteJSBundleInfo;
                    [self downloadIncrementRemoteJSBundleForName:JSBundleName];
                    break;
                }
            }
        }
    }
    if (!needDownload && localJSBundleZipInfo) { // 存在已经下载完成的JSBundle压缩包
        if ([self.curJSBundleName isEqualToString:JSBundleName] && self.successBlock) {
            self.successBlock(JSBundleName);
        }
    }
}

/**
 * 下载全量包
 *
 * @param JSBundleName JSBundleName
 */
- (void)downloadRemoteJSBundleWithName:(NSString *)JSBundleName {
    NSDictionary *remoteJSBundleInfo = self.remoteJSBundleInfoDic[JSBundleName];
    NSString *remoteJSBundlePath = nil;
    if ([JSBundleName isEqualToString:RN_DEFAULT_BUNDLE_NAME]) {
         remoteJSBundlePath = [NSString stringWithFormat:@"%@all/%@/rn_%@_%@.zip", [NIPRnManager sharedManager].remoteJSBundleRootPath, remoteJSBundleInfo[REMOTE_APP_VERSION], remoteJSBundleInfo[REMOTE_APP_VERSION], remoteJSBundleInfo[REMOTE_BUNDLE_VERSION]];
    } else {
         remoteJSBundlePath = [NSString stringWithFormat:@"%@%@/all/%@/rn_%@_%@.zip", [NIPRnManager sharedManager].remoteJSBundleRootPath, JSBundleName, remoteJSBundleInfo[REMOTE_APP_VERSION], remoteJSBundleInfo[REMOTE_APP_VERSION], remoteJSBundleInfo[REMOTE_BUNDLE_VERSION]];
    }
    NSURL *requestURL = [NSURL URLWithString:remoteJSBundlePath];
    [self downloadJSBundleForName:JSBundleName withURL:requestURL];
}

/**
 * 下载增量包
 *
 * @param JSBundleName JSBundleName
 */
- (void)downloadIncrementRemoteJSBundleForName:(NSString *)JSBundleName {
    NSDictionary *remoteJSBundleInfo = self.remoteJSBundleInfoDic[JSBundleName];
    NSString *remoteJSBundlePath = nil;
    if ([JSBundleName isEqualToString:RN_DEFAULT_BUNDLE_NAME]) {
        remoteJSBundlePath = [NSString stringWithFormat:@"%@increment/%@/rn_%@_%@_%@_%@.zip", [NIPRnManager sharedManager].remoteJSBundleRootPath, remoteJSBundleInfo[REMOTE_APP_VERSION], remoteJSBundleInfo[REMOTE_APP_VERSION], remoteJSBundleInfo[REMOTE_BUNDLE_VERSION], remoteJSBundleInfo[REMOTE_BUNDLE_LOW_VERSION], remoteJSBundleInfo[REMOTE_BUNDLE_INCREMENT_FLAG]];
    } else {
        remoteJSBundlePath = [NSString stringWithFormat:@"%@%@/increment/%@/rn_%@_%@_%@_%@.zip", [NIPRnManager sharedManager].remoteJSBundleRootPath, JSBundleName, remoteJSBundleInfo[REMOTE_APP_VERSION], remoteJSBundleInfo[REMOTE_APP_VERSION], remoteJSBundleInfo[REMOTE_BUNDLE_VERSION], remoteJSBundleInfo[REMOTE_BUNDLE_LOW_VERSION], remoteJSBundleInfo[REMOTE_BUNDLE_INCREMENT_FLAG]];
    }
    NSURL *requestURL = [NSURL URLWithString:remoteJSBundlePath];
    [self downloadJSBundleForName:JSBundleName withURL:requestURL];
}

/**
 * 下载JSBundle包
 *
 * @param JSBundleName JSBundleName
 * @param requestURL requestURL
 */
- (void)downloadJSBundleForName:(NSString *)JSBundleName withURL:(NSURL *)requestURL {
    __weak __typeof(self) weakSelf = self;
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    NSURLSessionDownloadTask *task = [_httpSession downloadTaskWithRequest:request
                                                                  progress:nil
                                                               destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                                                                   [weakSelf getZipFileDirForJSBundle:JSBundleName];
//
//                                                                   NSURL *tempFileURL = [NSURL URLWithString:tempFilePath];
//                                                                   return [tempFileURL URLByAppendingPathComponent:[response suggestedFilename]];
                                                                   NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
                                                                   NSURL *configURL = [documentsDirectoryURL URLByAppendingPathComponent:RN_JSBUNDLE_ZIP_SUBPATH];
                                                                   NSURL *bundleConfigURL = [configURL URLByAppendingPathComponent:JSBundleName];
                                                                   
                                                                   return [bundleConfigURL URLByAppendingPathComponent:[response suggestedFilename]];
                                                               }
                                                         completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                                                             __strong __typeof(weakSelf) strongSelf = weakSelf;
                                                             if (error) {
                                                                 if ([strongSelf.curJSBundleName isEqualToString:JSBundleName] &&
                                                                     strongSelf.failureBlock) {
                                                                     strongSelf.failureBlock(JSBundleName, NIPHotUpdateStatusDownloadBundleFailed);
                                                                 }
                                                             } else {
                                                                 NSString *JSBundleZipFilePath = [filePath absoluteString];
                                                                 if ([JSBundleZipFilePath hasPrefix:@"file://"]) {
                                                                     JSBundleZipFilePath = [JSBundleZipFilePath substringFromIndex:7];
                                                                 }
                                                                 //检查MD5值是否正确
                                                                 BOOL isValid = [strongSelf checkValidityOfJSBundleZipAtPath:JSBundleZipFilePath withName:JSBundleName];
                                                                 if (isValid) {
                                                                     [strongSelf recordLocalJSBundleZipInfoWithName:JSBundleName];
                                                                     if (strongSelf.forceUpdateBundleDic[JSBundleName]) {
                                                                         [strongSelf unzipJSBundleWithName:JSBundleName];
                                                                         strongSelf.forceUpdateBundleDic[JSBundleName] = @NO;
                                                                     } else if ([strongSelf.curJSBundleName isEqualToString:JSBundleName] && strongSelf.successBlock) {
                                                                         strongSelf.successBlock(JSBundleName);
                                                                     }
                                                                 } else {
                                                                     if ([strongSelf.curJSBundleName isEqualToString:JSBundleName] &&
                                                                         strongSelf.failureBlock) {
                                                                         strongSelf.failureBlock(JSBundleName, NIPHotUpdateStatusCheckMD5Failed);
                                                                     }
                                                                 }
                                                             }
                                                         }];
    [self recordDownloadTask:task withType:@"config" forJSBundle:JSBundleName];
    [task resume];
}


#pragma mark - JSBundle包管理

/**
 * 检查JSBundle包的合法性
 */
- (BOOL)checkValidityOfJSBundleZipAtPath:(NSString *)JSBundleZipFilePath withName:(NSString *)JSBundleName {
    NSString* MD5OfZip = [NIPRnHotReloadHelper generateMD5ForFileAtPath:JSBundleZipFilePath];
    NSDictionary *remoteJSBundleInfo = self.remoteJSBundleInfoDic[JSBundleName];
    NSString *remoteJSBundleZipMD5 = remoteJSBundleInfo[REMOTE_BUNDLE_MD5];
    if (!remoteJSBundleZipMD5 || [remoteJSBundleZipMD5 isEqualToString: MD5OfZip]) {
        return true;
    }
    return false;
}

/**
 * 解压JSBundleZip文件
 */
- (void)unzipJSBundleWithName:(NSString *)JSBundleName {
    NSString *JSBundleZipDir = [self.localJSBundleZipRootPath stringByAppendingPathComponent:JSBundleName];
    
    NSError *err;
    if ([NIPRnHotReloadHelper folderExistAtPath:JSBundleZipDir]) {
        NSArray *filePathArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:JSBundleZipDir error:&err];
        if (!err && filePathArray.count) {
            NSString *zipFileName = filePathArray.lastObject;
            NSString *zipFilePath = [JSBundleZipDir stringByAppendingPathComponent:zipFileName];
            ZipArchive *miniZip = [[ZipArchive alloc] init];
            if ([miniZip UnzipOpenFile:zipFilePath]) {
                NSString *targetFilePath = [self.localJSBundleRootPath stringByAppendingPathComponent:JSBundleName];
                BOOL ret = [miniZip UnzipFileTo:targetFilePath overWrite:YES];
                if (YES == ret) {
                    [self updateFontFamiliesForJSBundle:JSBundleName];
                    [self checkAndApplyIncrementForJSBundle:JSBundleName];
                    [self checkAndApplyAssetsConfigForJSBundle:JSBundleName];
                    [self recordLocalJSBundleInfoWithName:JSBundleName];
                }
                [miniZip UnzipCloseFile];
            }
            [NIPRnHotReloadHelper removeFileAtPath:zipFilePath];
        }
      
    }
   
    if (self.localJSBundleZipInfoDic[JSBundleName]) {
        self.localJSBundleZipInfoDic[JSBundleName] = nil;
        [self removeLocalJSBundleZipInfoWithName:JSBundleName];
    }
}

/**
 * 更新字体集
 */
- (void)updateFontFamiliesForJSBundle:(NSString *)JSBundleName {
    NSString *JSBundlePath = [self.localJSBundleRootPath stringByAppendingPathComponent:JSBundleName];
    NSArray *fontNames = [NIPRnHotReloadHelper filenameArrayOfType:@"ttf" inDirectory:JSBundlePath];
    [NIPRnHotReloadHelper registerFontFamilies:fontNames inDirectory:JSBundlePath];
}

/**
 * 更新JSBundle
 */
- (void)checkAndApplyIncrementForJSBundle:(NSString *)JSBundleName {
    NSString *JSBundleRootPath = [self.localJSBundleRootPath stringByAppendingPathComponent:JSBundleName];
    NSArray *JSBundleNameArray = [NIPRnHotReloadHelper filenameArrayOfType:JSBUNDLE inDirectory:JSBundleRootPath];
    
    NSString *mainBundleText = nil;
    NSString *increBundleText = nil;
    NSString *mainBundlePath = nil;
    NSString *increBundlePath = nil;
    
    BOOL hasIncrement = NO;
    for (NSString *bundleName in JSBundleNameArray) {
        NSString *bundlePath = [JSBundleRootPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@.%@", bundleName, JSBUNDLE]];
        if ([bundleName isEqualToString:@"index"]) {
            mainBundlePath = bundlePath;
            mainBundleText = [NSString stringWithContentsOfFile:bundlePath encoding:NSUTF8StringEncoding error:nil];
        }
        if ([bundleName isEqualToString:@"increment"]) {
            increBundlePath = bundlePath;
            increBundleText = [NSString stringWithContentsOfFile:bundlePath encoding:NSUTF8StringEncoding error:nil];
            hasIncrement = YES;
        }
    }
    
    if (hasIncrement) {
        DiffMatchPatch *patch = [[DiffMatchPatch alloc] init];
        NSError *error = nil;
        NSMutableArray *patches = [patch patch_fromText:increBundleText error:&error];
        if (!error) {
            NSArray *result = [patch patch_apply:patches toString:mainBundleText];
            if (result.count) {
                NSString *content = result[0];
                NSData *data = [content dataUsingEncoding: NSUTF8StringEncoding];
                BOOL success = [[NSFileManager defaultManager] createFileAtPath:mainBundlePath
                                                                       contents:data
                                                                     attributes:nil];
                if (success) {
                    [NIPRnHotReloadHelper removeFileAtPath:increBundlePath];
                }
            }
        }
    } else {
        NSString *commonBundleDir = [self.localJSBundleRootPath stringByAppendingPathComponent:COMMON];
        NSString *commonBundlePath = [NSString stringWithFormat:@"%@/index.jsbundle", commonBundleDir];
        NSString *commonBundleText = [NSString stringWithContentsOfFile:commonBundlePath
                                                               encoding:NSUTF8StringEncoding
                                                                  error:nil];
        DiffMatchPatch *patch = [[DiffMatchPatch alloc] init];
        NSError *error = nil;
        NSMutableArray *patches = [patch patch_fromText:mainBundleText error:&error];
        if (!error) {
            NSArray *result = [patch patch_apply:patches toString:commonBundleText];
            if (result.count) {
                NSString *content = result[0];
                NSData *data = [content dataUsingEncoding: NSUTF8StringEncoding];
                [[NSFileManager defaultManager] createFileAtPath:mainBundlePath
                                                                       contents:data
                                                                     attributes:nil];
            }
        }
    }
}

/**
 * 更新图片资源
 */
- (void)checkAndApplyAssetsConfigForJSBundle:(NSString *)JSBundleName {
    NSString *JSBundleRootPath = [self.localJSBundleRootPath stringByAppendingPathComponent:JSBundleName];
    NSString *assetsConfigFilePath = [JSBundleRootPath stringByAppendingPathComponent:@"assetsConfig.txt"];
    NSString *content = [NSString stringWithContentsOfFile:assetsConfigFilePath
                                                  encoding:NSUTF8StringEncoding
                                                     error:nil];
    NSArray *array = [content componentsSeparatedByString:@","];
    [NIPRnHotReloadHelper removeFileAtPath:assetsConfigFilePath];
    for (NSString *path in array) {
        if (path.length) {
            [NIPRnHotReloadHelper removeFileAtPath:[JSBundleRootPath stringByAppendingPathComponent:path]];
        }
    }
}


#pragma mark - 下载任务管理

/**
 * 记录下载任务
 */
- (void)recordDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                  withType:(NSString *)taskType
               forJSBundle:(NSString *)JSBundleName {
    if (downloadTask) {
        [self cancelExistedDownloadTaskWithType:taskType forJSBundle:JSBundleName];
        NSString *key = [NSString stringWithFormat:@"%@_%@", JSBundleName, taskType];
        self.downloadTaskDic[key] = downloadTask;
    }
}

/**
 * 删除已存在的下载任务
 */
- (void)cancelExistedDownloadTaskWithType:(NSString *)taskType
                              forJSBundle:(NSString *)JSBundleName {
    NSString *key = [NSString stringWithFormat:@"%@_%@", JSBundleName, taskType];
    NSURLSessionDownloadTask *downloadTask = self.downloadTaskDic[key];
    if (downloadTask) {
        [downloadTask cancel];
        self.downloadTaskDic[key] = nil;
    }
}


#pragma mark - 文件目录管理

/**
 * 获取存储配置文件的地址
 */
- (NSString *)getConfigFileDirForJSBundle:(NSString *)JSBundleName {
    NSString *configFileDir = [self.localJSBundleConfigRootPath stringByAppendingPathComponent:JSBundleName];
    if ([NIPRnHotReloadHelper folderExistAtPath:configFileDir]) {
        [NIPRnHotReloadHelper removeFolderAtPath:configFileDir];
    }
    [[NSFileManager defaultManager] createDirectoryAtPath:configFileDir withIntermediateDirectories:YES attributes:nil error:nil];
    return configFileDir;
}

/**
 * 获取存储JSBundle压缩包文件的地址
 */
- (NSString *)getZipFileDirForJSBundle:(NSString *)JSBundleName {
    NSString *zipFileDir = [self.localJSBundleZipRootPath stringByAppendingPathComponent:JSBundleName];
    if ([NIPRnHotReloadHelper folderExistAtPath:zipFileDir]) {
        [NIPRnHotReloadHelper removeFolderAtPath:zipFileDir];
    }
    [[NSFileManager defaultManager] createDirectoryAtPath:zipFileDir withIntermediateDirectories:YES attributes:nil error:nil];
    return zipFileDir;
}


@end

