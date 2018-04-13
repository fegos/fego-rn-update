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
 * 本地JSBundle包信息
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
 * 下载任务字典
 */
@property (nonatomic, strong) NSMutableDictionary *downloadTaskDic;

/**
 * 用户偏好设置
 */
@property (nonatomic, strong) NSUserDefaults *userDefaults;


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
        [self loadJSBundleInfoFromUserDefauls];
        [self loadJSBundleZipInfoFromUserDefauls];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.httpSession = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
        self.httpSession.requestSerializer.timeoutInterval = 20;
    }
    return self;
}


#pragma mark - IPA包更新模块

/**
 * 检查ipa包版本更新
 *
 * @param JSBundleName JSBundleName
 *
 * @reture needUpdate
 */
- (BOOL)checkIPAVersionUpdateForJSBundleWithName:(NSString *)JSBundleName {
    BOOL isUpdated = NO;
    NSDictionary *localJSBundleInfo = [self getLocalJSBundleInfoWithName:JSBundleName];
    if (localJSBundleInfo) {
        NSString *localAppVersion = localJSBundleInfo[RN_APP_VERSION];
        NSString *localBuildVersion = localJSBundleInfo[RN_BUILD_VERSION];
        if (!noEmptyString(localAppVersion) ||
            [localAppVersion compare:APP_VERSION] == NSOrderedAscending) {
            isUpdated = YES;
        } else if (!noEmptyString(localBuildVersion) ||
                   [localBuildVersion compare:APP_BUILD] == NSOrderedAscending) {
            isUpdated = YES;
        }
    } else {
        isUpdated = YES;
    }
    return isUpdated;
}


/**
 * 将RN数据从IPA包拷贝到沙盒路径下
 *
 * @param JSBundleName JSBundleName
 *
 * @return copySuccess
 */
- (BOOL)copyJSBundleFromIPAToDocumentDiretoryWithName:(NSString *)JSBundleName {
    BOOL copySuccess = NO;
    NSString *srcBundlePath = [[NSBundle mainBundle] pathForResource:JSBundleName ofType:nil inDirectory:RN_JSBUNDLE_SUBPATH];
    NSString *dstBundlePath =  [self.localJSBundleRootPath stringByAppendingPathComponent:JSBundleName];
    NSString *commonBundlePath = [[NSBundle mainBundle] pathForResource:COMMON ofType:nil inDirectory:RN_JSBUNDLE_SUBPATH];
    if ([NIPRnHotReloadHelper folderExistAtPath:commonBundlePath]) {
        BOOL bundleCopySuccess = [NIPRnHotReloadHelper copyFolderAtPath:srcBundlePath toPath:dstBundlePath];
        if (bundleCopySuccess) {
            NSString *srcBundleFilePath = [srcBundlePath stringByAppendingPathComponent:@"index.jsbundle"];
            NSString *dstBundleFilePath = [dstBundlePath stringByAppendingPathComponent:@"index.jsbundle"];
            NSString *commonBundleFilePath = [commonBundlePath stringByAppendingPathComponent:@"index.jsbundle"];
            NSString *tempBundleFilePath = [dstBundlePath stringByAppendingPathComponent:@"temp.jsbundle"];
            BOOL mergeSuccess = [self mergeFileAtPath:srcBundleFilePath withFileAtPath:commonBundleFilePath toFileAtPath:tempBundleFilePath];
            if (mergeSuccess) {
                [NIPRnHotReloadHelper copyFileAtPath:tempBundleFilePath toPath:dstBundleFilePath];
                [NIPRnHotReloadHelper removeFileAtPath:tempBundleFilePath];
                copySuccess = YES;
            }
        }
    } else {
        BOOL bundleCopySuccess = [NIPRnHotReloadHelper copyFolderAtPath:srcBundlePath toPath:dstBundlePath];
        if (bundleCopySuccess) {
            copySuccess = YES;
        }
    }
    return copySuccess;
}


#pragma mark - 热更新模块

/**
 * 执行远程请求,请参数含有本地AppVersion、本地JSBundleVersion
 * 假如没有新版本，则不请求数据，下载服务器上的新包
 *
 * @param JSBundleName JSBunldeName
 * @param successBlock successBlock
 * @param failureBlock failureBlock
 */
- (void)requestRemoteJSBundleWithName:(NSString *)JSBundleName
                              success:(NIPRNUpdateSuccessBlock)successBlock
                              failure:(NIPRNUpdateFailureBlock)failureBlock; {
    self.curJSBundleName = JSBundleName;
    self.successBlock = successBlock;
    self.failureBlock = failureBlock;
    
    // 假如用户没有传入成功回调，则默认为强制更新
    if (!successBlock) {
        self.forceUpdateBundleDic[JSBundleName] = @YES;
    }
    [self downloadRemoteJSBundleConfigFileWithName:JSBundleName];
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
    NSString *localAppVersion = localJSBundleInfo[RN_APP_VERSION];
    NSString *localBundleVersion = localJSBundleInfo[RN_BUNDLE_VERSION];
    if (localJSBundleZipInfo) {
        if ([localAppVersion compare:localJSBundleZipInfo[RN_APP_VERSION]] == NSOrderedAscending) {
            localAppVersion = localJSBundleZipInfo[RN_APP_VERSION];
            localBundleVersion = localJSBundleZipInfo[RN_BUNDLE_VERSION];
        } else if ([localAppVersion isEqualToString:localJSBundleZipInfo[RN_APP_VERSION]] &&
                   [localBundleVersion compare:localJSBundleZipInfo[RN_BUNDLE_VERSION]] == NSOrderedAscending) {
            localBundleVersion = localJSBundleZipInfo[RN_BUNDLE_VERSION];
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
                                                   RN_APP_VERSION : remoteAppVersion,
                                                   RN_BUNDLE_VERSION : remoteBundleVersion,
                                                   RN_BUNDLE_MD5 : items[2]
                                                   };
                    self.remoteJSBundleInfoDic[JSBundleName] = JSBundleInfo;
                    [self downloadRemoteJSBundleWithName:JSBundleName];
                    break;
                }
            } else if (items.count == 5) {
                NSString *remoteLowBundleVersion = items[2];
                if ([localAppVersion isEqualToString:remoteAppVersion] &&
                    [localBundleVersion compare:remoteBundleVersion] == NSOrderedAscending &&
                    [localBundleVersion isEqualToString:remoteLowBundleVersion]) {
                    needDownload = YES;
                }
                if (needDownload) {
                    NSDictionary *remoteJSBundleInfo = @{
                                                         RN_APP_VERSION : remoteAppVersion,
                                                         RN_BUNDLE_VERSION : remoteBundleVersion,
                                                         RN_BUNDLE_LOW_VERSION : remoteLowBundleVersion,
                                                         RN_BUNDLE_INCREMENT_FLAG : items[3],
                                                         RN_BUNDLE_MD5 : items[4]
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
        remoteJSBundlePath = [NSString stringWithFormat:@"%@all/%@/rn_%@_%@.zip", [NIPRnManager sharedManager].remoteJSBundleRootPath, remoteJSBundleInfo[RN_APP_VERSION], remoteJSBundleInfo[RN_APP_VERSION], remoteJSBundleInfo[RN_BUNDLE_VERSION]];
    } else {
        remoteJSBundlePath = [NSString stringWithFormat:@"%@%@/all/%@/rn_%@_%@.zip", [NIPRnManager sharedManager].remoteJSBundleRootPath, JSBundleName, remoteJSBundleInfo[RN_APP_VERSION], remoteJSBundleInfo[RN_APP_VERSION], remoteJSBundleInfo[RN_BUNDLE_VERSION]];
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
        remoteJSBundlePath = [NSString stringWithFormat:@"%@increment/%@/rn_%@_%@_%@_%@.zip", [NIPRnManager sharedManager].remoteJSBundleRootPath, remoteJSBundleInfo[RN_APP_VERSION], remoteJSBundleInfo[RN_APP_VERSION], remoteJSBundleInfo[RN_BUNDLE_VERSION], remoteJSBundleInfo[RN_BUNDLE_LOW_VERSION], remoteJSBundleInfo[RN_BUNDLE_INCREMENT_FLAG]];
    } else {
        remoteJSBundlePath = [NSString stringWithFormat:@"%@%@/increment/%@/rn_%@_%@_%@_%@.zip", [NIPRnManager sharedManager].remoteJSBundleRootPath, JSBundleName, remoteJSBundleInfo[RN_APP_VERSION], remoteJSBundleInfo[RN_APP_VERSION], remoteJSBundleInfo[RN_BUNDLE_VERSION], remoteJSBundleInfo[RN_BUNDLE_LOW_VERSION], remoteJSBundleInfo[RN_BUNDLE_INCREMENT_FLAG]];
    }
    NSURL *requestURL = [NSURL URLWithString:remoteJSBundlePath];
    [self downloadJSBundleForName:JSBundleName withURL:requestURL];
}


#pragma mark - 网络请求模块

/**
 *  下载远程配置文件
 */
- (void)downloadRemoteJSBundleConfigFileWithName:(NSString *)JSBundleName {
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
                                                                   NSString *JSBundleConfigFileDir = [weakSelf getConfigFileDirForJSBundle:JSBundleName];
                                                                   NSString *fileStyleDir = [NSString stringWithFormat:@"file://%@", JSBundleConfigFileDir];
                                                                   NSURL *finalURL = [NSURL URLWithString:fileStyleDir];
                                                                   return [finalURL URLByAppendingPathComponent:[response suggestedFilename]];
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
                                                                   NSString *JSBundleZipFileDir = [weakSelf getZipFileDirForJSBundle:JSBundleName];
                                                                   NSString *fileStyleDir = [NSString stringWithFormat:@"file://%@", JSBundleZipFileDir];
                                                                   NSURL *finalURL = [NSURL URLWithString:fileStyleDir];
                                                                   return [finalURL URLByAppendingPathComponent:[response suggestedFilename]];
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
                                                                         [strongSelf loadHotUpdatedJSBundleWithName:JSBundleName];
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


#pragma mark - JSBundle包管理

/**
 * 检查JSBundle包的合法性
 */
- (BOOL)checkValidityOfJSBundleZipAtPath:(NSString *)JSBundleZipFilePath withName:(NSString *)JSBundleName {
    NSString* MD5OfZip = [NIPRnHotReloadHelper generateMD5ForFileAtPath:JSBundleZipFilePath];
    NSDictionary *remoteJSBundleInfo = self.remoteJSBundleInfoDic[JSBundleName];
    NSString *remoteJSBundleZipMD5 = remoteJSBundleInfo[RN_BUNDLE_MD5];
    if (!remoteJSBundleZipMD5 || [remoteJSBundleZipMD5 isEqualToString: MD5OfZip]) {
        return true;
    }
    return false;
}

/**
 * 加载热更新之后的JSBundle文件
 *
 * @param JSBundleName 包名
 *
 */
- (void)loadHotUpdatedJSBundleWithName:(NSString *)JSBundleName {
    BOOL unzipSuccess = [self unzipJSBundleWithName:JSBundleName];
    if (unzipSuccess) {
        [self checkAndApplyIncrementForJSBundle:JSBundleName];
        [self checkAndApplyAssetsConfigForJSBundle:JSBundleName];
        [self registerFontFamiliesForJSBundle:JSBundleName];
    }
}

/**
 * 解压JSBundleZip文件，并删除原包
 *
 * @param JSBundleName 包名
 *
 * @reture unZipSuccess
 */
- (BOOL)unzipJSBundleWithName:(NSString *)JSBundleName {
    BOOL unZipSuccess = NO;
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
                    unZipSuccess = YES;
                }
                [miniZip UnzipCloseFile];
            }
            if (unZipSuccess) {
                [NIPRnHotReloadHelper removeFileAtPath:zipFilePath];
            }
        }
    }
    
    return unZipSuccess;
}

/**
 * 检查是否需要对JSBundle做增量更新，如果需要则更新
 *
 * @param JSBundleName 包名
 *
 * @return updateSuccess
 */
- (BOOL)checkAndApplyIncrementForJSBundle:(NSString *)JSBundleName {
    BOOL updateSucces = NO;
    
    NSString *JSBundleRootPath = [self.localJSBundleRootPath stringByAppendingPathComponent:JSBundleName];
    NSArray *JSBundleNameArray = [NIPRnHotReloadHelper filenameArrayOfType:JSBUNDLE inDirectory:JSBundleRootPath];
    
    NSString *mainBundlePath = nil;
    NSString *increBundlePath = nil;
    
    BOOL hasIncrement = NO;
    for (NSString *bundleName in JSBundleNameArray) {
        NSString *bundlePath = [JSBundleRootPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@.%@", bundleName, JSBUNDLE]];
        if ([bundleName isEqualToString:@"index"]) {
            mainBundlePath = bundlePath;
        } else if ([bundleName isEqualToString:@"increment"]) {
            increBundlePath = bundlePath;
            hasIncrement = YES;
        }
    }
    
    if (hasIncrement) {
        BOOL mergeSuccess = [self mergeFileAtPath:increBundlePath withFileAtPath:mainBundlePath toFileAtPath:mainBundlePath];
        if (mergeSuccess) {
            [NIPRnHotReloadHelper removeFileAtPath:increBundlePath];
            updateSucces = YES;
        }
    } else {
        NSString *commonBundleDir = [self.localJSBundleRootPath stringByAppendingPathComponent:COMMON];
        NSString *commonBundlePath = [NSString stringWithFormat:@"%@/index.jsbundle", commonBundleDir];
        if ([NIPRnHotReloadHelper fileExistAtPath:commonBundlePath]) {
            BOOL mergeSuccess = [self mergeFileAtPath:mainBundlePath withFileAtPath:commonBundlePath toFileAtPath:mainBundlePath];
            if (mergeSuccess) {
                updateSucces = YES;
            }
        } else {
            updateSucces = YES;
        }
    }
    return updateSucces;
}

/**
 * 根据assetsConfig文件删除多余图片资源
 * @param JSBundleName 包名
 */
- (void)checkAndApplyAssetsConfigForJSBundle:(NSString *)JSBundleName {
    NSString *JSBundleRootPath = [self.localJSBundleRootPath stringByAppendingPathComponent:JSBundleName];
    NSString *assetsConfigFilePath = [JSBundleRootPath stringByAppendingPathComponent:@"assetsConfig.txt"];
    NSString *configContent = [NSString stringWithContentsOfFile:assetsConfigFilePath
                                                        encoding:NSUTF8StringEncoding
                                                           error:nil];
    [NIPRnHotReloadHelper removeFileAtPath:assetsConfigFilePath];
    NSArray *uselessAssetsPathArray = [configContent componentsSeparatedByString:@","];
    for (NSString *uselessAssetsPath in uselessAssetsPathArray) {
        if (uselessAssetsPath.length) {
            [NIPRnHotReloadHelper removeFileAtPath:[JSBundleRootPath stringByAppendingPathComponent:uselessAssetsPath]];
        }
    }
}

/**
 * 更新字体集
 */
- (void)registerFontFamiliesForJSBundle:(NSString *)JSBundleName {
    NSString *JSBundlePath = [self.localJSBundleRootPath stringByAppendingPathComponent:JSBundleName];
    NSArray *fontNames = [NIPRnHotReloadHelper filenameArrayOfType:@"ttf" inDirectory:JSBundlePath];
    [NIPRnHotReloadHelper registerFontFamilies:fontNames inDirectory:JSBundlePath];
}

/**
 * 合包
 *
 * @param srcBundlePath 要合并的文件路径
 * @param commonBundlePath 被合并的公共文件路径
 * @param dstBundlePath 存放合成文件的路径
 *
 * @reture mergeSuccess
 */
- (BOOL)mergeFileAtPath:(NSString *)srcBundlePath withFileAtPath:(NSString *)commonBundlePath toFileAtPath:(NSString *)dstBundlePath {
    NSString *srcBundleContent = [NSString stringWithContentsOfFile:srcBundlePath encoding:NSUTF8StringEncoding error:nil];
    NSString *commonBundleContent = [NSString stringWithContentsOfFile:commonBundlePath encoding:NSUTF8StringEncoding error:nil];
    
    BOOL mergeSuccess = NO;
    DiffMatchPatch *patch = [[DiffMatchPatch alloc] init];
    NSError *err;
    NSMutableArray *patches = [patch patch_fromText:srcBundleContent error:&err];
    if (!err) {
        NSArray *result = [patch patch_apply:patches toString:commonBundleContent];
        if (result.count) {
            NSString *content = result[0];
            NSData *resultData = [content dataUsingEncoding: NSUTF8StringEncoding];
            BOOL success = [[NSFileManager defaultManager] createFileAtPath:dstBundlePath
                                                                   contents:resultData
                                                                 attributes:nil];
            if (success) {
                mergeSuccess = YES;
            }
        }
    }
    return mergeSuccess;
}


#pragma mark - 本地JSBundle信息管理（解压好的包和等待解压的包）

/**
 * 将IPA包中JSBundle信息记录到本地
 *
 * @param JSBundleName 包名
 */
- (void)recordIPAJSBundleInfoToLocalWithName:(NSString *)JSBundleName {
    NSMutableDictionary *localJSBundleInfo = [self getLocalJSBundleInfoWithName:JSBundleName];
    if (!localJSBundleInfo) {
        localJSBundleInfo = [NSMutableDictionary dictionary];
    }
    localJSBundleInfo[RN_APP_VERSION] = APP_VERSION;
    localJSBundleInfo[RN_BUILD_VERSION] = APP_BUILD;
    localJSBundleInfo[RN_BUNDLE_VERSION] = DEFAULT_BUNDLE_VERSION;
    [self saveLocalJSBundleInfoToUserDefaults:localJSBundleInfo withName:JSBundleName];
}

/**
 * 将远端JSBundle信息记录到本地
 *
 * @param JSBundleName 包名
 */
- (void)recordRemoteJSBundleInfoToLocalWithName:(NSString *)JSBundleName {
    NSDictionary *remoteJSBundleInfo = self.remoteJSBundleInfoDic[JSBundleName];
    if (remoteJSBundleInfo) {
        NSMutableDictionary *localJSBundleInfo = [self getLocalJSBundleInfoWithName:JSBundleName];
        
        localJSBundleInfo[RN_BUNDLE_VERSION] = remoteJSBundleInfo[RN_BUNDLE_VERSION];
        [self saveLocalJSBundleInfoToUserDefaults:localJSBundleInfo withName:JSBundleName];
    }
}

/**
 * 记录本地JSBundle压缩包信息
 */
- (void)recordLocalJSBundleZipInfoWithName:(NSString *)JSBundleName {
    NSDictionary *remoteJSBundleInfo = self.remoteJSBundleInfoDic[JSBundleName];
    if (remoteJSBundleInfo) {
        NSMutableDictionary *localJSBundleZipInfo = [self getLocalJSBundleZipInfoWithName:JSBundleName];
        if (!localJSBundleZipInfo) {
            localJSBundleZipInfo = [NSMutableDictionary dictionary];
        }
        localJSBundleZipInfo[RN_APP_VERSION] = remoteJSBundleInfo[RN_APP_VERSION];
        localJSBundleZipInfo[RN_BUNDLE_VERSION] = remoteJSBundleInfo[RN_BUNDLE_VERSION];
        [self saveLocalJSBundleZipInfoToUserDefaults:localJSBundleZipInfo withName:JSBundleName];
    }
}

/**
 * 从用户偏好设置获取本地JSBundle信息
 */
- (void)loadJSBundleInfoFromUserDefauls {
    NSDictionary *localJSBundleInfoDic = [self.userDefaults objectForKey:LOCAL_RN_BUNDLE_INFO];
    if (localJSBundleInfoDic) {
        self.localJSBundleInfoDic = [NSMutableDictionary dictionaryWithDictionary:localJSBundleInfoDic];
    }
}

/**
 * 从用户偏好设置获取指定名字的本地JSBundle信息
 */
- (NSMutableDictionary *)getLocalJSBundleInfoWithName:(NSString *)JSBundleName {
    NSDictionary *localJSBundleInfo = self.localJSBundleInfoDic[JSBundleName];
    return [localJSBundleInfo mutableCopy];
}

/**
 * 将指定名字的本地JSBundle信息保存到用户偏好设置中
 */
- (void)saveLocalJSBundleInfoToUserDefaults:(NSDictionary *)JSBundleInfo
                                   withName:(NSString *)JSBundleName {
    if (JSBundleInfo && JSBundleName) {
        self.localJSBundleInfoDic[JSBundleName] = JSBundleInfo;
        [self.userDefaults setObject:self.localJSBundleInfoDic forKey:LOCAL_RN_BUNDLE_INFO];
    }
}

/**
 * 从用户偏好设置获取本地JSBundle压缩包信息
 */
- (void)loadJSBundleZipInfoFromUserDefauls {
    NSDictionary *localJSBundleZipInfoDic = [self.userDefaults objectForKey:LOCAL_RN_BUNDLE_ZIP_INFO];
    if (localJSBundleZipInfoDic) {
        self.localJSBundleZipInfoDic = [NSMutableDictionary dictionaryWithDictionary:localJSBundleZipInfoDic];
    }
}

/**
 * 从用户偏好设置获取指定名字的本地JSBundle压缩包信息
 */
- (NSMutableDictionary *)getLocalJSBundleZipInfoWithName:(NSString *)JSBundleName {
    NSDictionary *localJSBundleZipInfo = self.localJSBundleZipInfoDic[JSBundleName];
    return [localJSBundleZipInfo mutableCopy];
}

/**
 * 将指定名字的本地JSBundle压缩包信息保存到用户偏好设置中
 */
- (void)saveLocalJSBundleZipInfoToUserDefaults:(NSDictionary *)JSBundleInfo
                                      withName:(NSString *)JSBundleName {
    if (JSBundleInfo && JSBundleName) {
        self.localJSBundleZipInfoDic[JSBundleName] = JSBundleInfo;
        [self.userDefaults setObject:self.localJSBundleZipInfoDic forKey:LOCAL_RN_BUNDLE_ZIP_INFO];
    }
}

/**
 * 删除本地JSBundle压缩包信息
 */
- (void)removeLocalJSBundleZipInfoWithName:(NSString *)JSBundleName {
    self.localJSBundleZipInfoDic[JSBundleName] = nil;
    [self.userDefaults setObject:self.localJSBundleZipInfoDic forKey:LOCAL_RN_BUNDLE_ZIP_INFO];
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


#pragma mark - Setters && Getters

- (NSUserDefaults *)userDefaults {
    if (!_userDefaults) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
    }
    return _userDefaults;
}


@end

