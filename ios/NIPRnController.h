//
//  NIPRnController.h
//  NSIP
//
//  Created by 赵松 on 17/2/23.
//  Copyright © 2017年 netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCTNavigator;
@class RCTRootView;

@interface NIPRnController : UIViewController

///**
// *  在rn界面启动更新资源
// */
//- (void)updateAssets;

/**
 *根据业务指定的bundle，加载对应的module
 */
- (id)initWithBundleName:(NSString *)bundleName moduleName:(NSString *)moduleName;

@property (nonatomic, strong) RCTRootView *rctRootView;

/**
 *  业务请求时可能需要的参数
 */
@property (nonatomic, copy, readwrite) NSDictionary *appProperties;

/**
 *  rn内嵌的导航条视图
 */
@property (nonatomic,strong) RCTNavigator *navigator;

@end
