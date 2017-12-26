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

RCT_EXPORT_MODULE(MiaowHotUpdate)

RCT_EXPORT_METHOD(hotReload) {
  [[NIPRnManager sharedManager] requestRCTAssetsBehind];
}

@end
