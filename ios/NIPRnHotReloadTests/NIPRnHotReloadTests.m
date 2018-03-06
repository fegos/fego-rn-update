//
//  NIPRnHotReloadTests.m
//  NIPRnHotReloadTests
//
//  Created by zramals on 2018/2/26.
//  Copyright © 2018年 zramals. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NIPRnManager.h"
#import "NIPRnController.h"
#import "NIPRnHotReloadHelper.h"

@interface NIPRnHotReloadTests : XCTestCase
@property (nonatomic,strong)XCTestExpectation* exception;
@end

@implementation NIPRnHotReloadTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}
//测试获取单例
-(void)testgetInstance{
    NIPRnManager *manager = [NIPRnManager sharedManager];
    NIPRnManager *manager2 = [NIPRnManager sharedManager];
    XCTAssertEqualObjects(manager,manager2,@"获取对象非单例");
}
-(void)testGetRnController{
    NIPRnController *controller = [[NIPRnManager managerWithBundleUrl:@"https://raw.githubusercontent.com/fegos/fego-rn-update/master/demo/increment/ios/increment" noHotUpdate:NO noJsServer:YES] loadControllerWithModel:@"hotUpdate"];
    XCTAssertNotNil(controller,@"获取不成功");
}
-(void)testManagerRequest{
    
    //声明XCTestExpectation对象
    XCTestExpectation *exception = [self expectationWithDescription:@"des"];
    self.exception = exception;
    
    //发起网络请求
    NIPRnManager *manager = [NIPRnManager sharedManager];
    manager.bundleUrl=@"https://raw.githubusercontent.com/fegos/fego-rn-update/master/demo/increment/ios/increment";
    manager.noHotUpdate = NO;
    manager.noJsServer = YES;
    [manager requestRCTAssetsBehind];

    //十秒后检查是否有zip文件
    [self performSelector:@selector(checkZipFile) withObject:self afterDelay:10];
    
    //等待 XCTestExpectation对象触发fulfill方法，或超时之后再向下执行
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
}
-(void)checkZipFile{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:docDir error:nil];
    [files enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[(NSString*)obj pathExtension] isEqualToString:@"zip"]) {
            //有zip文件则实现处理处理，否则报超时异常test fail
            [self.exception fulfill];
        }
    }];
}



@end
