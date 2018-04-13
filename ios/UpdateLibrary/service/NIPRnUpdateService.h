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
 * 检查ipa包版本更新
 *
 * @param JSBundleName JSBundleName
 *
 * @reture needUpdate
 */
- (BOOL)checkIPAVersionUpdateForJSBundleWithName:(NSString *)JSBundleName;

/**
 * 将RN数据从IPA包拷贝到沙盒路径下
 *
 * @param JSBundleName JSBundleName
 *
 * @return copySuccess
 */
- (BOOL)copyJSBundleFromIPAToDocumentDiretoryWithName:(NSString *)JSBundleName;

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
                              failure:(NIPRNUpdateFailureBlock)failureBlock;

/**
 * 加载热更新之后的JSBundle文件
 *
 * @param JSBundleName 包名
 *
 */
- (void)loadHotUpdatedJSBundleWithName:(NSString *)JSBundleName;

/**
 * 更新字体集
 */
- (void)registerFontFamiliesForJSBundle:(NSString *)JSBundleName;

/**
 * 将IPA包中JSBundle信息记录到本地
 *
 * @param JSBundleName 包名
 */
- (void)recordIPAJSBundleInfoToLocalWithName:(NSString *)JSBundleName;

/**
 * 将远端JSBundle信息记录到本地
 *
 * @param JSBundleName 包名
 */
- (void)recordRemoteJSBundleInfoToLocalWithName:(NSString *)JSBundleName;


@end
