//
//  ViewController.m
//  MultiBundleDemo
//
//  Created by Eric on 2018/4/13.
//  Copyright © 2018年 Eric. All rights reserved.
//

#import "ViewController.h"
#import "NIPRnController.h"
#import "NIPRNManager.h"
#import <React/RCTBridge.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [NIPRnManager managerWithRemoteJSBundleRoot:@"https://raw.githubusercontent.com/fegos/fego-rn-update/master/hybriddemo/rn/bao/ios/"
                                   useHotUpdate:YES
                                 andUseJSServer:NO];
    [[NIPRnManager sharedManager] loadJSBundleWithName:@"common"];
}


- (IBAction)jumpToFirstRnController:(id)sender {
    NIPRnManager *manager = [NIPRnManager sharedManager];
    NIPRnController *controller = [manager loadRNControllerWithJSBundleName:@"Hello" andModuleName:@"First"];
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)jumpToSecondRnController:(id)sender {
    NIPRnManager *manager = [NIPRnManager sharedManager];
    NIPRnController *controller = [manager loadRNControllerWithJSBundleName:@"World" andModuleName:@"Second"];
    [self.navigationController pushViewController:controller animated:YES];
}


@end
