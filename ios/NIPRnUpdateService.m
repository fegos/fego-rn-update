//
//  NIPRnUpdateService.m
//  NSIP
//
//  Created by 赵松 on 17/3/30.
//  Copyright © 2017年 netease. All rights reserved.
//

#import "NIPRnUpdateService.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#import "NIPRnManager.h"
#import <ZipArchive/ZipArchive.h>
#import "DiffMatchPatch.h"
#import "NIPRnHotReloadHelper.h"

#define ZIP @"zip"

@interface NIPRnUpdateService ()

@property (nonatomic, strong) AFHTTPSessionManager *httpSession;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
/**
 *  离线资源下载的路径
 */
@property (nonatomic, strong) NSString *downLoadPath;

/**
 *  用来记录本地数据的版本号，默认为@"0"
 */
@property (nonatomic, strong) NSString* localDataVersion;

/**
 *  用来记录本地数据的SDK版本号,默认=RN_SDK_VERSION
 */
@property (nonatomic, strong) NSString* localSDKVersion;

/**
 *  用来记录远程数据的版本号，默认为@"0"
 */
@property (nonatomic, strong) NSString* remoteDataVersion;

/**
 *  用来记录远程数据的SDK版本号,默认=RN_SDK_VERSION
 */
@property (nonatomic, strong) NSString* remoteSDKVersion;
/**
 *  用来验证文件的MD5值
 */
@property (nonatomic, strong) NSString* remoteMD5;

@property (nonatomic, copy) CFRCTUpdateAssetsSuccesBlock successBlock;
@property (nonatomic, copy) CFRCTUpdateAssetsFailBlock failBlock;

@end

@implementation NIPRnUpdateService
/**
 获取单例
 
 @return obj
 */
+ (instancetype)sharedService
{
    static NIPRnUpdateService *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NIPRnUpdateService alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.httpSession = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
        self.httpSession.requestSerializer.timeoutInterval = 20;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        self.downLoadPath = [paths objectAtIndex:0];
    }
    return self;
}

/**
 *  初始化本地请求数据
 */
- (void)readLocalDataVersion
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id localDataInfo = [defaults objectForKey:RN_DATA_VERSION];
    if (localDataInfo) {
        self.localDataVersion = localDataInfo;
    }
    else {
        self.localDataVersion = NIP_RN_DATA_VERSION;
    }

    id localSDKInfo = [defaults objectForKey:RN_SDK_VERSION];
    if (localSDKInfo) {
        self.localSDKVersion = localSDKInfo;
        if (![self.localSDKVersion isEqualToString:NIP_RN_SDK_VERSION]) {
            self.localDataVersion = @"0";
            self.localSDKVersion = NIP_RN_SDK_VERSION;
        }
    }
    else {
        self.localSDKVersion = NIP_RN_SDK_VERSION;
    }
}

/**
 *  后台静默下载资源包
 */
- (void)requestRCTAssetsBehind
{
    [self requestRCTAssets:nil
                 failBlock:nil];
}

/**
 *  开启rct资源包的下载
 *
 *  @param successBlock
 *  @param failBlock    
 */
- (void)requestRCTAssets:(CFRCTUpdateAssetsSuccesBlock)successBlock
               failBlock:(CFRCTUpdateAssetsFailBlock)failBlock
{
    [self readLocalDataVersion];
    self.successBlock = successBlock;
    self.failBlock = failBlock;
    [self performSelectorInBackground:@selector(doRequest) withObject:nil];
}

/**
 *  后台线程请求网络
 */
- (void)doRequest
{
    //先下载配置文件，根据配置文件决定是否下载资源包
    [self requestRCTConfig];
}

/**
 *  下载远程配置文件
 */
- (void)requestRCTConfig
{
    __weak __typeof(self) weakSelf = self;
//    WEAK_SELF(weakSelf)
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/config?version=%@", [NIPRnManager sharedManager].bundleUrl, self.localDataVersion]];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    [self.downloadTask cancel];
    self.downloadTask = [_httpSession downloadTaskWithRequest:request
        progress:nil
        destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
            return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
        }
        completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
            if (error) {
                [weakSelf requestSuccess:NO];
            }
            else {
                NSString *actualPath = [filePath absoluteString];
                if ([actualPath hasPrefix:@"file://"]) {
                    actualPath = [actualPath substringFromIndex:7];
                }
                [weakSelf readConfigFile:actualPath];
            }
        }];
    [self.downloadTask resume];
}

/**
 *  读取配置文件
 *
 *  @param configFilePath
 */
- (void)readConfigFile:(NSString *)configFilePath
{
    NSString *content = [NSString stringWithContentsOfFile:configFilePath encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"%@", content);
//    NSArray *array = [content componentsSeparatedByString:@"\n"];
    NSArray *array = [content componentsSeparatedByString:@","];
    [[NSFileManager defaultManager] removeItemAtPath:configFilePath error:nil];

  
  BOOL needDownload = NO;
  for (NSString *line in array) {
    NSArray *items = [line componentsSeparatedByString:@"_"];
    NSString *remoteLowDataVersion = nil;
    NSString *wholeStr = nil;
    if (items.count >= 4) {

      self.remoteSDKVersion = [items objectAtIndex:0];
      self.remoteDataVersion = [items objectAtIndex:1];
      remoteLowDataVersion = [items objectAtIndex:2];
      wholeStr = [items objectAtIndex:3];
      self.remoteMD5 = [items objectAtIndex:4];
      if (wholeStr.length > 1) {
        wholeStr = [wholeStr substringWithRange:NSMakeRange(0, 1)];
      }
      if ([self.remoteSDKVersion isEqualToString:NIP_RN_SDK_VERSION]) {
        if ([self.localDataVersion isEqualToString:remoteLowDataVersion]) {
          [self downLoadRCTZip:@"rn" withWholeString:wholeStr];
          needDownload = YES;
          break;
        }
      }
    }
  }
  if (!needDownload) {
    NSString *zipPath = nil;
    if ((zipPath = [self filePathOfRnZip])) {
      [self alertIfUpdateRnZipWithFilePath:zipPath];
    } else {
      [self requestSuccess:YES];
    }
  }
//    for (NSString *line in array) {
//        NSArray *items = [line componentsSeparatedByString:@"_"];
//        if (items.count >= 2) {
////            NSString *remoteSdkVersion = [items objectAtIndex:0];
////            NSString *remoteDataVersion = [items objectAtIndex:1];
////            NSString *remoteDataZip = [items objectAtIndex:2];
////            if ([remoteSdkVersion isEqualToString:NIP_RN_SDK_VERSION]) {
////            if ([self.localDataVersion isEqualToString:@"0"] || ![self.localDataVersion isEqualToString:remoteDataVersion]) {
//            self.remoteSDKVersion = [items objectAtIndex:0];
//            self.remoteDataVersion = [items objectAtIndex:1];
//            if ([self.remoteSDKVersion isEqualToString:NIP_RN_SDK_VERSION]) {
//                if ([self.localDataVersion isEqualToString:@"0"] || ![self.localDataVersion isEqualToString:self.remoteDataVersion]) {
////                    [self downLoadRCTData:remoteDataVersion zip:remoteDataZip];
//                    [self downLoadRCTData:self.remoteDataVersion zip:@"rn"];
//                }
//                else {
//                    NSString *zipPath = nil;
//                    if ((zipPath = [self filePathOfRnZip])) {
//                        [self alertIfUpdateRnZipWithFilePath:zipPath];
//                    } else {
//                        [self requestSuccess:YES];
//                    }
//                }
//                break;
//            }
//        }
//    }
}


/**
 *  执行请求并下载数据
 */
- (void)downLoadRCTZip:(NSString *)zipName withWholeString:(NSString *)wholeStr
{
  __weak __typeof(self) weakSelf = self;
  //    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@.zip?version=%@&sdk=%@", RCT_SERVER_TEST_URL, zipName,self.localDataVersion, self.localSDKVersion]];
  NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@/%@_%@_%@_%@_%@.zip?version=%@&sdk=%@", [NIPRnManager sharedManager].bundleUrl, self.remoteSDKVersion, self.remoteDataVersion, zipName, self.remoteSDKVersion, self.remoteDataVersion, self.localDataVersion, wholeStr, self.localDataVersion, self.localSDKVersion]];
  NSLog(@"%@", URL);
  
  NSURLRequest *request = [NSURLRequest requestWithURL:URL];
  [self.downloadTask cancel];
  self.downloadTask = [_httpSession downloadTaskWithRequest:request
                                                   progress:nil
                                                destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                                                  NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
                                                  return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
                                                }
                                          completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                                            if (error) {
                                              [weakSelf requestSuccess:NO];
                                            }
                                            else {
                                              NSString *actualPath = [filePath absoluteString];
                                              if ([actualPath hasPrefix:@"file://"]) {
                                                actualPath = [actualPath substringFromIndex:7];
                                              }
                                              NSLog(@"热更新zip地址：%@", actualPath);
                                              //检查MD5值是否正确
                                              if(![self checkMD5OfRnZip:actualPath]){
                                                [weakSelf requestSuccess:NO];
                                              }

                                            }
                                          }];
  [self.downloadTask resume];
}

-(BOOL)checkMD5OfRnZip:(NSString*)path{
    NSString* MD5OfZip = [NIPRnHotReloadHelper getFileMD5WithPath:path];
    NSLog(@"下载文件的MD5值为：%@",MD5OfZip);
    
    if ([self.remoteMD5 isEqualToString: MD5OfZip]) {
        [[NSUserDefaults standardUserDefaults] setObject:self.remoteDataVersion forKey:RN_DATA_VERSION];
        [[NSUserDefaults standardUserDefaults] setObject:NIP_RN_SDK_VERSION forKey:RN_SDK_VERSION];
        [self alertIfUpdateRnZipWithFilePath:path];
        return true;
    }
    return false;

}

- (NSString *)filePathOfRnZip {
  NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentPath = [dirPaths objectAtIndex:0];
  NSArray *docmentZipNames = [NIPRnHotReloadHelper fileNameListOfType:ZIP fromDirPath:documentPath];
  if (hotreload_notEmptyArray(docmentZipNames)) {
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    NSString *path = [[documentsDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip", docmentZipNames[0]]] absoluteString];
    if ([path hasPrefix:@"file://"]) {
      path = [path substringFromIndex:7];
    }
    return path;
  }
  return nil;
}

- (void)alertIfUpdateRnZipWithFilePath:(NSString *)filePath {
  /*最低支持ios8，故直接使用alertViewController*/
  UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"有新的资源包可以更新，是否立即更新" preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    [self unzipAssets:filePath];
    HOTRELOAD_SUPPRESS_Undeclaredselector_WARNING([[[UIApplication sharedApplication] delegate] performSelector:@selector(loadRnController)]);

  }];
  UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    
  }];
  [alertVC addAction:actionOK];
  [alertVC addAction:actionCancel];
  
  UIViewController *topController = [[NIPRnHotReloadHelper alloc] topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
  
  if (![topController isKindOfClass:[UIAlertController class]]) { //避免alertcontroller弹出多次
    [topController presentViewController:alertVC animated:YES completion:nil];
  }
  
}

/**
 *  后台请求完成后，在主线程更新数据
 */
- (void)requestSuccess:(BOOL)bSuccess
{
  if (bSuccess && self.successBlock) {
    self.successBlock();
  }
  else if (self.failBlock) {
    self.failBlock();
  }
}

/**
 *  删除老的客户端的rn资源相关文件
 */
- (void)removeOldDataFiles
{
  NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *docsDir = [dirPaths objectAtIndex:0];
  NSString *assetsDir = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:@"/assets"]];
  NSError *error = nil;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath:assetsDir]) {
    [fileManager removeItemAtPath:assetsDir error:&error];
    if (error) {
      NSLog(@"%@", error);
    }
  }
}

- (void)unzipAssets:(NSString *)filePath
{
  ZipArchive *miniZip = [[ZipArchive alloc] init];
  if ([miniZip UnzipOpenFile:filePath]) {
    BOOL ret = [miniZip UnzipFileTo:self.downLoadPath overWrite:YES];
    if (YES == ret) {
      NSLog(@"download ok==");
//      [NIPIconFontService registerIconFonts];
                  [NIPRnHotReloadHelper registerIconFontsByNames:[[NIPRnManager sharedManager] fontNames]];
    }
    [miniZip UnzipCloseFile];
  }
  
  //    [self zipRCTDataTest:filePath];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath:filePath]) {
    [fileManager removeItemAtPath:filePath error:nil];
  }
  
  [self checkAndApplyIncrement];
  [self checkAndApplyAssetsConfig];
  [[NIPRnManager sharedManager] loadBundleUnderDocument];
  [self requestSuccess:YES];
}

- (void)checkAndApplyIncrement {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentPath = [docPaths objectAtIndex:0];
  NSArray *docmentBundleNames = [NIPRnHotReloadHelper fileNameListOfType:JSBUNDLE fromDirPath:documentPath];
  NSString *mainBundleText = nil;
  NSString *increBundleText = nil;
  NSString *mainBundlePath = nil;
  NSString *increBundlePath = nil;
  BOOL hasIncrement = NO;
  for (NSString *bundleName in docmentBundleNames) {
    NSString *jsBundlePath = [[NSString alloc] initWithString:[documentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@.%@", bundleName, JSBUNDLE]]];
    if ([bundleName isEqualToString:@"index"]) {
      mainBundlePath = jsBundlePath;
      mainBundleText = [NSString stringWithContentsOfFile:jsBundlePath encoding:NSUTF8StringEncoding error:nil];
    }
    if ([bundleName isEqualToString:@"increment"]) {
      increBundlePath = jsBundlePath;
      increBundleText = [NSString stringWithContentsOfFile:jsBundlePath encoding:NSUTF8StringEncoding error:nil];
      hasIncrement = YES;
    }
  }
  if (hasIncrement) {
    DiffMatchPatch *patch = [[DiffMatchPatch alloc] init];
    NSError *error = nil;
    NSMutableArray *patches = [patch patch_fromText:increBundleText error:&error];
    if (!error) {
      NSArray *result = [patch patch_apply:patches toString:mainBundleText];
      NSString *content = result[0];
      if (result.count) {
        NSData *data = [content dataUsingEncoding: NSUTF8StringEncoding];
        BOOL success = [fileManager createFileAtPath:mainBundlePath contents:data attributes:nil];
        if (success) {
          [fileManager removeItemAtPath:increBundlePath error:NULL];
        }
      }
    }
  }
}

- (void)checkAndApplyAssetsConfig {
  NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentPath = [docPaths objectAtIndex:0];
  NSString *configFilePath = [documentPath stringByAppendingPathComponent:@"assetsConfig.txt"];
  NSString *content = [NSString stringWithContentsOfFile:configFilePath encoding:NSUTF8StringEncoding error:nil];
  //    NSArray *array = [content componentsSeparatedByString:@"\n"];
  NSArray *array = [content componentsSeparatedByString:@","];
  [[NSFileManager defaultManager] removeItemAtPath:configFilePath error:nil];
  NSString *tempPath = nil;
  for (NSString *path in array) {
    if (path.length) {
      tempPath = [documentPath stringByAppendingPathComponent:path];
      [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
    }
  }
}

@end

