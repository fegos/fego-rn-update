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
 *
 * @param filetype 文件类型
 * @param directory 文件路径
 * @return NSArray
 */
+ (NSArray *)filenameArrayOfType:(NSString *)filetype inDirectory:(NSString *)directory;

/**
 * 拷贝文件到某个路径
 *
 * @param srcPath 源文件路径
 * @param dstPath 目标文件路径
 * @return BOOL
 */
+ (BOOL)copyFileAtPath:(NSString *)srcPath toPath:(NSString *)dstPath;

/**
 * 拷贝文件夹至某个路径
 *
 * @param srcPath 源路径
 * @param dstPath 目标路径
 * @return BOOL
 */
+ (BOOL)copyFolderAtPath:(NSString *)srcPath toPath:(NSString *)dstPath;

/**
 * 移除文件
 *
 * @param filePath 需要删除的文件路径
 * @return BOOL
 */
+ (BOOL)removeFileAtPath:(NSString *)filePath;

/**
 * 移除文件夹
 *
 * @param folderPath 文件夹路径
 * @return BOOL
 */
+ (BOOL)removeFolderAtPath:(NSString *)folderPath;

/**
 * 文件是否存在
 *
 * @param filePath 文件路径
 * @return BOOL
 */
+ (BOOL)fileExistAtPath:(NSString *)filePath;

/**
 * 文件夹是否存在
 *
 * @param folderPath 文件夹路径
 * @return BOOL
 */
+ (BOOL)folderExistAtPath:(NSString *)folderPath;

/**
 * 获取目标VC的顶层VC
 *
 * @param  targetVC 目标VC
 * @return UIViewController
 */
+ (UIViewController *)topViewControllerOfTargetViewController:(UIViewController*)targetVC;

/**
 * 注册字体文件
 *
 * @param fontNameArray 字体文件名数组
 * @param directory 存放字体文件的目录，假如不传则默认为document
 */
+ (void)registerFontFamilies:(NSArray *)fontNameArray inDirectory:(NSString *)directory;

/**
 * 注册字体文件
 *
 * @param fontFamilyName 字体文件名称
 * @param directory 存放字体文件的目录，假如不传则默认为document
 */
+ (void)registerFontFamilyWithName:(NSString *)fontFamilyName inDirectory:(NSString *)directory;

/**
 * 生成文件MD5值
 *
 * @param filePath 文件路径
 */
+ (NSString*)generateMD5ForFileAtPath:(NSString*)filePath;


@end
