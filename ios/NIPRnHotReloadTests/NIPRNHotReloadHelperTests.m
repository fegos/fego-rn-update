//
//  NIPRNHotReloadHelperTests.m
//  NIPRnHotReloadTests
//
//  Created by zramals on 2018/2/26.
//  Copyright © 2018年 zramals. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NIPRnHotReloadHelper.h"
#import "NIPRnDefines.h"

#define TEMP_DIRECTORY NSTemporaryDirectory()
#define TEST_JSBUNDLE_DIRECTORY [NSTemporaryDirectory() stringByAppendingString:@"test.jsbundle"]
//#define TEST_JSBUNDLE_DIRECTORY_FILE_TO_DEL [NSTemporaryDirectory() stringByAppendingString:@"delTest.jsbundle"]
//#define TEST_JSBUNDLE_DIRECTORY_FOLDER_TO_DEL [NSTemporaryDirectory() stringByAppendingString:@"/delTest/delTest.jsbundle"]

@interface NIPRNHotReloadHelperTests : XCTestCase

@end

@implementation NIPRNHotReloadHelperTests

- (void)setUp {
    [super setUp];
    //temp中添加.jsbundle，用来进行文件系统的相关测试
    NSString *string = @"test";
    [string writeToFile:TEST_JSBUNDLE_DIRECTORY atomically:YES encoding:NSUTF8StringEncoding error:nil];
//    [string writeToFile:TEST_JSBUNDLE_DIRECTORY_FILE_TO_DEL atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void)tearDown {
    [super tearDown];
}

//测试获取bundle文件方法
-(void)testLoadBundle{
    NSArray *docmentBundleNames = [NIPRnHotReloadHelper fileNameListOfType:@"jsbundle" fromDirPath:TEMP_DIRECTORY];
    XCTAssertTrue(hotreload_notEmptyArray(docmentBundleNames),@"文件读取失败");
}
//测试拷贝分件方法
-(void)testCopyFile{
    BOOL isSuccess = [NIPRnHotReloadHelper copyFile:TEST_JSBUNDLE_DIRECTORY toPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"test2.jsbundle"]];
    XCTAssertTrue(isSuccess,@"文件拷贝失败");
}
//测试拷贝文件夹
-(void)testCopyFolder{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    BOOL isSuccess = [NIPRnHotReloadHelper copyFolderFrom:TEMP_DIRECTORY to:docDir];
    XCTAssertTrue(isSuccess,@"文件夹拷贝失败");
}
//测试移除文件
-(void)testRemoveFile{
    BOOL isSuccess = [NIPRnHotReloadHelper removeFileAtPath:TEST_JSBUNDLE_DIRECTORY];
    XCTAssertTrue(isSuccess,@"文件删除失败");
}
//测试移除文件夹
-(void)testRemoveFolder{
    BOOL isSuccess = [NIPRnHotReloadHelper removeFolder:TEMP_DIRECTORY];
    XCTAssertTrue(isSuccess,@"文件夹删除失败");
}
//测试文件是否存在
-(void)testFileExist{
    BOOL isExist = [NIPRnHotReloadHelper fileExistAtPath:TEST_JSBUNDLE_DIRECTORY];
    XCTAssertTrue(isExist,@"应存在的文件显示为不存在");
}
//测试目录是否存在
-(void)testFolderExist{
    BOOL isExist = [NIPRnHotReloadHelper folderExistAtPath:TEMP_DIRECTORY];
    XCTAssertTrue(isExist,@"应存在的文件夹显示为不存在");
}
//测试获取当前VC
-(void)testTopViewcontroller{
    UIViewController *topController = [[NIPRnHotReloadHelper alloc] topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
    BOOL isVC = [topController isKindOfClass:[UIViewController class]];
    XCTAssertTrue(isVC,@"获取到非VC对象");
}
//测试获取MD5值
-(void)testFileMD5{
    NSString *md5str = [NIPRnHotReloadHelper getFileMD5WithPath:TEST_JSBUNDLE_DIRECTORY];
    XCTAssertEqualObjects(md5str,@"098f6bcd4621d373cade4e832627b4f6",@"MD5不正确");
}


@end
