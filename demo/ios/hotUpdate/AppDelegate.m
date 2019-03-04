/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "AppDelegate.h"

#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>
#import <React/RCTBridge.h>
#import "NIPRnManager.h"
#import "NIPRnController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self loadDefaultKeyWindow];

    return YES;
}

- (void)loadDefaultKeyWindow {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self loadRnController];
}

- (void)loadRnController {
    NIPRnManager *manager = [NIPRnManager sharedManager];
    manager.remoteJSBundleRootPath = @"https://raw.githubusercontent.com/fegos/fego-rn-update/develop/demo/increment/ios/";
    manager.useHotUpdate = YES;
    manager.useJSServer = NO;
    manager.jsServerPath = @"index";
    //    NIPRnController *controller = [[NIPRnManager managerWithRemoteJSBundleRoot:@"https://raw.githubusercontent.com/fegos/fego-rn-update/master/demo/increment/ios/"
    //                                                                  useHotUpdate:NO
    //                                                                andUseJSServer:YES]
    //        loadRNControllerWithModule:@"hotUpdate"];
    NIPRnController *controller = [manager loadRNControllerWithModule:@"hotUpdate"];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
    self.window.rootViewController = controller;
#pragma clang diagnostic pop

    [self.window makeKeyAndVisible];
}

- (void)failedHandlerWithStatus:(NIPHotUpdateStatus)status {
    switch (status) {
        case NIPHotUpdateStatusReadConfigFailed: {
            NSLog(@"NIPReadConfigFailed");
        } break;
        case NIPHotUpdateStatusDownloadBundleFailed: {
            NSLog(@"NIPDownloadBundleFailed");
        } break;
        case NIPHotUpdateStatusCheckMD5Failed: {
            NSLog(@"NIPMD5CheckFailed");
        } break;
        default:
            break;
    }
}

@end

