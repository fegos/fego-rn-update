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
 文件系统私有方法，获取bundle文件

 @param type 文件类型
 @param dirPath 文件路径
 @return NSArray
 */
+ (NSArray *)fileNameListOfType:(NSString *)type fromDirPath:(NSString *)dirPath;

/**
 拷贝文件到某个路径

 @param filePath 文件路径
 @param toPath 目标路径
 @return BOOL
 */
+ (BOOL)copyFile:(NSString *)filePath toPath:(NSString *)toPath;
/**
 拷贝文件夹至某个路径

 @param sourcePath 原文件夹路径
 @param destinationPath 目标路径
 @return BOOL
 */
+ (BOOL)copyFolderFrom:(NSString *)sourcePath to:(NSString *)destinationPath;

/**
 移除文件

 @param filePath 目标文件路径
 @return BOOL
 */
+ (BOOL)removeFileAtPath:(NSString *)filePath;
/**
 移除文件夹

 @param folderPath 文件夹路径
 @return BOOL
 */
+ (BOOL)removeFolder:(NSString *)folderPath;

/**
 文件是否存在

 @param filePath 文件路径
 @return BOOL
 */
+ (BOOL)fileExistAtPath:(NSString *)filePath;
/**
 目录是否存在

 @param folderPath 目录的路径
 @return BOOL
 */
+ (BOOL)folderExistAtPath:(NSString *)folderPath;
/**
 获取当前VC

 @param rootViewController 当前的rootViewController
 @return UIViewController
 */
- (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController;
/**
 注册字体文件

 @param names 字体文件名数组
 */
+ (void)registerIconFontsByNames:(NSArray *)names;
@end
