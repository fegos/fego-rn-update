//
//  FEGORNUpdateServiceTests.m
//  FEGORNUpdateTests
//
//  Created by Eric on 2018/4/10.
//  Copyright © 2018年 Eric. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NIPRnManager.h"

@interface FEGORNUpdateServiceTests : XCTestCase

@end

@implementation FEGORNUpdateServiceTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}


- (void)testGetInstance {
    NIPRnManager *manager = [NIPRnManager sharedManager];
    NIPRnManager *manager2 = [NIPRnManager sharedManager];
    XCTAssertEqualObjects(manager,manager2,@"获取对象非单例");
}
-(void)testGetRnController{
    NIPRnController *controller = [[NIPRnManager managerWithRemoteJSBundleRoot:@"https://raw.githubusercontent.com/fegos/fego-rn-update/master/demo/increment/ios/increment" useHotUpdate:YES andUseJSServer:NO] loadRNControllerWithModule:@"hotUpdate"];
    XCTAssertNotNil(controller,@"获取不成功");
}
-(void)testManagerRequest{
    
    //声明XCTestExpectation对象
    XCTestExpectation *exception = [self expectationWithDescription:@"des"];
    
    //发起网络请求
    NIPRnManager *manager = [NIPRnManager sharedManager];
    manager.remoteJSBundleRootPath=@"https://raw.githubusercontent.com/fegos/fego-rn-update/master/demo/increment/ios/increment";
    manager.useHotUpdate = YES;
    manager.useJSServer = NO;
    [manager requestRemoteJSBundleWithName:@"index" success:nil failure:nil];
    
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
//            [self.exception fulfill];
        }
    }];
}

@end
