//
//  NIPRnUpdateService.h
//  NSIP
//
//  Created by 赵松 on 17/3/30.
//  Copyright © 2017年 netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIPRnManager.h"


@interface NIPRnUpdateService : NSObject

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
 * 获取单例
 *
 * @return obj
 */
+ (instancetype)sharedService;

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
