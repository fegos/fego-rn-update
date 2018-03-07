//
//  NIPRnUpdateService.h
//  NSIP
//
//  Created by 赵松 on 17/3/30.
//  Copyright © 2017年 netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIPRnDefines.h"
#import "NIPRnManager.h"

/**
 资源下载成功回调
 */
typedef void (^CFRCTUpdateAssetsSuccesBlock)(void);
/**
 资源下载失败回调
 */
typedef void (^CFRCTUpdateAssetsFailBlock)(void);


//! 用来检测当前的rn脚本是否需要升级的管理类
@interface NIPRnUpdateService : NSObject

/**
 获取单例

 @return obj
 */
+ (instancetype)sharedService;

/**
 请求远程服务的url，用来确定是否升级本地的rn资源包
 */
@property (nonatomic, strong) NSString *requestUrl;

@property (nonatomic,weak) id<NIPRnManagerDelegate> delegate;

-(void)unzipBundle:(NSString *)filePath;
/**
 静默后台下载rn资源
 */
- (void)requestRCTAssetsBehind;

/**
 执行远程请求,请参数含有本地sdkversion、localDataVersion
 如果服务器的serverVersion==localVersion，则不抛回数据，否则返回服务器上的新包

 @param successBlock successBlock
 @param failBlock failBlock
 */
- (void)requestRCTAssets:(CFRCTUpdateAssetsSuccesBlock)successBlock failBlock:(CFRCTUpdateAssetsFailBlock)failBlock;

@end
