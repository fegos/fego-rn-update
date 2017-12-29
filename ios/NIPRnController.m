//
//  NIPRnController.m
//  NSIP
//
//  Created by 赵松 on 17/2/23.
//  Copyright © 2017年 netease. All rights reserved.
//

#import "NIPRnController.h"
#import "NIPRnManager.h"
#import "NIPRnUpdateService.h"

#if __has_include(<React/RCTAssert.h>)
#import <React/RCTRootView.h>
#import <React/RCTNavigator.h>
#else
#import "RCTRootView.h"
#import "RCTNavigator.h"
#endif

@interface NIPRnController ()
@property (nonatomic, strong) NSString *bundleName;
@property (nonatomic, strong) NSString *moduleName;
@end

@implementation NIPRnController

/**
 初始化函数

 @return obj
 */
- (id)init
{
    self = [super init];
    if (self) {
        self.bundleName = @"index";
        self.moduleName = @"App";
    }
    return self;
}

/**
 初始化函数

 @param bundleName bundleName
 @param moduleName moduleName
 @return obj
 */
- (id)initWithBundleName:(NSString *)bundleName moduleName:(NSString *)moduleName
{
    self = [super init];
    if (self) {
        if (bundleName) {
            self.bundleName = bundleName;
        }
        else {
            self.bundleName = @"index";
        }
        if (moduleName) {
            self.moduleName = moduleName;
        }
        else {
            self.moduleName = @"App";
        }
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.fd_prefersNavigationBarHidden = YES;
    [self loadWithBundleName:self.bundleName moduleName:self.moduleName];
}

- (void)setAppProperties:(NSDictionary *)appProperties{
    _appProperties = appProperties;
    BOOL interactivePopDisabled = [[appProperties objectForKey:@"params"]objectForKey:@"popDisable"];
    if (appProperties && interactivePopDisabled) {
//        self.fd_interactivePopDisabled = interactivePopDisabled;
        self.navigationController.navigationBar.hidden = interactivePopDisabled;
    }
}

///**
// 加载本地资源文件

// @param bundleName bundleName
// @param moduleName moduleName
// */
- (void)loadWithBundleName:(NSString *)bundleName moduleName:(NSString *)moduleName
{

    if (self.rctRootView) {
        [self.rctRootView removeFromSuperview];
    }
    RCTBridge *bridge = [[NIPRnManager sharedManager] getBridgeByBundleName:bundleName];
    self.rctRootView = [[RCTRootView alloc] initWithBridge:bridge
                                                moduleName:moduleName
                                         initialProperties:self.appProperties];
    
    UIView *loading = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
    loading.backgroundColor = [UIColor whiteColor];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 298, 139)];
    imageView.image = [UIImage imageNamed:@"default_logo"];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [loading addSubview:imageView];
    [imageView setCenter:CGPointMake(loading.center.x, imageView.center.y)];
    CGRect frame = imageView.frame;
    frame.origin.y = loading.frame.origin.y - 31;
    [imageView setFrame:frame];
    self.rctRootView.loadingView = loading;

    [self.view addSubview:self.rctRootView];
    self.rctRootView.frame = self.view.bounds;
}

-(RCTNavigator*)navigator
{
    if (!_navigator) {
        UIView* rootContentView = [self.rctRootView valueForKey:@"contentView"];
        [self getNavigator:rootContentView];
    }
    return _navigator;
}

-(void)getNavigator:(UIView*)view
{
    for (UIView* sub in view.subviews) {
        if ([sub isKindOfClass:[RCTNavigator class]]) {
            self.navigator = (RCTNavigator*)sub;
        }
        else{
            [self getNavigator:sub];
        }
    }
}
-(void)printSubView:(UIView*)view
{
    NSLog(@"========subview=%@========",[view class]);
    for (UIView* sub in view.subviews) {
        NSLog(@"%@",[sub class]);
        [self printSubView:sub];
    }
    NSLog(@"========subview=%@===end=====",[view class]);
}

- (void)updateAssets
{
  //使用方自己处理indicator的显示
//    [self showLoadingIndicator];
    __weak __typeof(self) weakSelf = self;
    [[NIPRnUpdateService sharedService] requestRCTAssets:^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf updateAssetsSuccess];
    }
                                         failBlock:^{
                                           __strong __typeof(weakSelf) strongSelf = weakSelf;
                                             [strongSelf updateAssetsFail];
                                         }];
}

- (void)updateAssetsSuccess
{
  //使用方自己处理indicator的显示关闭
//    [self dismissLoadingIndicator];
    [self loadWithBundleName:self.bundleName moduleName:self.moduleName];
}

- (void)updateAssetsFail
{
  //使用方自己处理indicator的显示关闭
//    [self dismissLoadingIndicator];
    [self loadWithBundleName:@"index" moduleName:@"RNErrorView"];
}

@end
