//
//  NIPModules.m
//  hotUpdate
//
//  Created by 赵松 on 2017/12/12.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "NIPModules.h"
#import "NIPRnManager.h"
#import <React/RCTBridge.h>

@implementation NIPModules

RCT_EXPORT_MODULE(FegoRnUpdate)

RCT_EXPORT_METHOD(hotReload) {
  NIPRnManager *manager = [NIPRnManager sharedManager];
  [manager requestRemoteJSBundleWithName:RN_DEFAULT_BUNDLE_NAME
                                 success:^(NSString *JSBundleName) {
                                   [manager loadNewHotUpdatedJSBundleWithName:JSBundleName];
                                   [[manager getBridgeWithJSBundleName:RN_DEFAULT_BUNDLE_NAME] reload];
                                 }
                                 failure:^(NSString *JSBundleName, NIPHotUpdateStatus failStatus) {
                                   
                                 }];
}

@end
