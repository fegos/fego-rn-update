//
//  NIPRnUpdateServiceTests.m
//  NIPRnHotReloadTests
//
//  Created by zramals on 2018/2/27.
//  Copyright © 2018年 zramals. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NIPRnUpdateService.h"

@interface NIPRnUpdateServiceTests : XCTestCase

@end

@implementation NIPRnUpdateServiceTests

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
    NIPRnUpdateService *Service = [NIPRnUpdateService sharedService];
    NIPRnUpdateService *Service2 = [NIPRnUpdateService sharedService];
    XCTAssertEqualObjects(Service,Service2,@"获取对象非单例");
}


@end
