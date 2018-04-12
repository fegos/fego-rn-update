//
//  NIPModules.m
//  hotUpdate
//
//  Created by 赵松 on 2017/12/12.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "NIPModules.h"
#import "NIPRnManager.h"

@implementation NIPModules

RCT_EXPORT_MODULE(FegoRnUpdate)

RCT_EXPORT_METHOD(hotReload) {
//  [[NIPRnManager sharedManager] requestRemoteJSBundleWithName:@"index" success:nil failure:nil];
}

@end
