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

@property (nonatomic,  strong) UIView *loadingView;

@end

@implementation NIPRnController

/**
 * 初始化函数
 *
 * @return obj
 */
- (instancetype)init {
    self = [super init];
    if (self) {
        self.bundleName = @"index";
        self.moduleName = @"App";
    }
    return self;
}

/**
 * 初始化函数
 *
 * @param bundleName bundleName
 * @param moduleName moduleName
 * @return obj
 */
- (instancetype)initWithBundleName:(NSString *)bundleName moduleName:(NSString *)moduleName {
    self = [super init];
    if (self) {
        if (bundleName) {
            self.bundleName = bundleName;
        } else {
            self.bundleName = @"index";
        }
        if (moduleName) {
            self.moduleName = moduleName;
        } else {
            self.moduleName = @"App";
        }
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadLocalAssetsWithBundleName:self.bundleName moduleName:self.moduleName];
}

/**
 * 加载本地资源文件
 *
 * @param bundleName bundleName
 * @param moduleName moduleName
 */
- (void)loadLocalAssetsWithBundleName:(NSString *)bundleName moduleName:(NSString *)moduleName {
    if (self.rctRootView) {
        [self.rctRootView removeFromSuperview];
    }
    RCTBridge *bridge = [[NIPRnManager sharedManager] getBridgeWithJSBundleName:bundleName];
    self.rctRootView = [[RCTRootView alloc] initWithBridge:bridge
                                                moduleName:moduleName
                                         initialProperties:self.appProperties];
    self.rctRootView.loadingView = self.loadingView;
    self.rctRootView.frame = self.view.bounds;
    [self.view addSubview:self.rctRootView];
    
}

- (void)updateAssets
{
    // 使用方自己处理indicator的显示
//    __weak __typeof(self) weakSelf = self;
//    [[NIPRnUpdateService sharedService] requestRCTAssets:^{
//        [weakSelf updateAssetsSuccess];
//    }
//                                               failBlock:^{
//                                                   [weakSelf updateAssetsFail];
//                                               }];
}

- (void)updateAssetsSuccess {
    [self loadLocalAssetsWithBundleName:self.bundleName moduleName:self.moduleName];
}

- (void)updateAssetsFail {
    [self loadLocalAssetsWithBundleName:@"index" moduleName:@"RNErrorView"];
}

/*
 * 找到目标view下的RCTNavigator，并设置。
 */
- (void)findAndSetNavigator:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[RCTNavigator class]]) {
            self.navigator = (RCTNavigator *)subview;
            break;
        }
        else{
            [self findAndSetNavigator:subview];
        }
    }
}


#pragma mark - Setters && Getters

- (void)setAppProperties:(NSDictionary *)appProperties{
    _appProperties = appProperties;
    BOOL interactivePopDisabled = [[appProperties objectForKey:@"params"] objectForKey:@"popDisable"];
    if (appProperties && interactivePopDisabled) {
        self.navigationController.navigationBar.hidden = interactivePopDisabled;
    }
}

- (RCTNavigator *)navigator {
    if (!_navigator) {
        UIView *rootContentView = [self.rctRootView valueForKey:@"contentView"];
        [self findAndSetNavigator:rootContentView];
    }
    return _navigator;
}

- (UIView *)loadingView {
    if (!_loadingView) {
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        _loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
        _loadingView.backgroundColor = [UIColor whiteColor];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 298, 139)];
        imageView.image = [UIImage imageNamed:@"default_logo"];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_loadingView addSubview:imageView];
        CGPoint center = _loadingView.center;
        center.y -= 31;
        imageView.center = center;
    }
    return _loadingView;
}


@end
