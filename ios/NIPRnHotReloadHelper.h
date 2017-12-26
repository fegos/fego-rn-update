//
//  NIPRnHotReloadHelper.h
//  hotUpdate
//
//  Created by zramals on 2017/12/22.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NIPRnHotReloadHelper : NSObject

/**
 * 文件系统私有方法，获取bundle文件
 **/
+ (NSArray *)fileNameListOfType:(NSString *)type fromDirPath:(NSString *)dirPath;

+ (BOOL)copyFile:(NSString *)filePath toPath:(NSString *)toPath;
+ (BOOL)copyFolderFrom:(NSString *)sourcePath to:(NSString *)destinationPath;

+ (BOOL)removeFileAtPath:(NSString *)filePath;
+ (BOOL)removeFolder:(NSString *)folderPath;

+ (BOOL)fileExistAtPath:(NSString *)filePath;
+ (BOOL)folderExistAtPath:(NSString *)folderPath;
/**
 * 获取当前VC
 **/
- (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController;
/**
 * 注册字体文件
 **/
+ (void)registerIconFontsByNames:(NSArray *)names;
@end
