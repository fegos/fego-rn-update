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

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//  NSURL *jsCodeLocation;
//
//  jsCodeLocation = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index" fallbackResource:nil];
//
//  RCTRootView *rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
//                                                      moduleName:@"hotUpdate"
//                                               initialProperties:nil
//                                                   launchOptions:launchOptions];
//  rootView.backgroundColor = [[UIColor alloc] initWithRed:1.0f green:1.0f blue:1.0f alpha:1];
//
//  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
//  UIViewController *rootViewController = [UIViewController new];
//  rootViewController.view = rootView;
//  self.window.rootViewController = rootViewController;
//  [self.window makeKeyAndVisible];
//  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadRnController) name:@"RNHotReloadRequestSuccess" object:nil];
  NIPRnManager *manager = [NIPRnManager sharedManager];
  manager.delegate = self;
  manager.bundleUrl = @"https://raw.githubusercontent.com/fegos/fego-rn-update/master/demo/increment/ios/";
  manager.noHotUpdate = NO;
  manager.noJsServer = YES;
  
  [self loadDefaultKeyWindow];
  
  return YES;
}

- (void)loadDefaultKeyWindow {
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  [self loadRnController];
  /**
   * 注册字体信息
   */
}

-(void)successHandlerWithFilePath:(NSString *)filePath{
  NSLog(@"NIPHotReloadSuccess");
  [[NIPRnManager sharedManager] unzipBundle:filePath];
  [self loadRnController];
}
-(void)failedHandlerWithStatus:(HotReloadStatus)status{
  switch (status) {
    case NIPReadConfigFailed:
    {
      NSLog(@"NIPReadConfigFailed");
    }
      break;
    case NIPDownloadBundleFailed:
    {
      NSLog(@"NIPDownloadBundleFailed");
    }
      break;
    case NIPMD5CheckFailed:
    {
      NSLog(@"NIPMD5CheckFailed");
    }
      break;
    default:
      break;
  }

}

- (void)loadRnController {
//  NIPRnController *controller = [[NIPRnManager sharedManager] loadControllerWithModel:@"hotUpdate"];
  
  NIPRnController *controller = [[NIPRnManager managerWithBundleUrl:@"https://raw.githubusercontent.com/fegos/fego-rn-update/master/demo/increment/ios/increment" noHotUpdate:NO noJsServer:YES] loadControllerWithModel:@"hotUpdate"];
//  [NIPRnManager sharedManager].fontNames = @[@"nsip"];
//  controller.appProperties = @{@"productFlavor": @"ec"};
  
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
  self.window.rootViewController = controller;
#pragma clang diagnostic pop
  
  [self.window makeKeyAndVisible];
}

@end
