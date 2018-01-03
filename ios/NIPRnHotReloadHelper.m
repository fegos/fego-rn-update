//
//  NIPRnHotReloadHelper.m
//  hotUpdate
//
//  Created by zramals on 2017/12/22.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "NIPRnHotReloadHelper.h"
#import <CoreText/CoreText.h>

@interface NIPRnHotReloadHelper()

@end

@implementation NIPRnHotReloadHelper

/**
 文件系统私有方法，获取bundle文件
 
 @param type 文件类型
 @param dirPath 文件路径
 @return NSArray
 */
+ (NSArray *)fileNameListOfType:(NSString *)type fromDirPath:(NSString *)dirPath
{
  NSMutableArray *filenamelist = [NSMutableArray arrayWithCapacity:10];
  NSArray *tmplist = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:nil];
  NSRange range;
  range.location = 0;
  NSInteger typeLength = [type length] + 1;
  for (NSString *filename in tmplist) {
    if ([[filename pathExtension] isEqualToString:type]) {
      range.length = filename.length - typeLength;
      NSString *nameWithoutExtension = [filename substringWithRange:range];
      [filenamelist addObject:nameWithoutExtension];
    }
  }
  return filenamelist;
}

/**
 拷贝文件到某个路径
 
 @param filePath 文件路径
 @param toPath 目标路径
 @return BOOL
 */
+ (BOOL)copyFile:(NSString *)filePath toPath:(NSString *)toPath
{
  BOOL isDir = NO;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  BOOL existed = [fileManager fileExistsAtPath:filePath isDirectory:&isDir];
  if (existed && !isDir) {
    NSString *toFolderPath = [toPath stringByDeletingLastPathComponent];
    NSError *error = nil;
    existed = [fileManager fileExistsAtPath:toFolderPath isDirectory:&isDir];
    if (existed) {
      if (!isDir) {
        return NO;
      }
    } else {
      [fileManager createDirectoryAtPath:toFolderPath withIntermediateDirectories:YES attributes:nil error:&error];
    }
    if (error) {
      return NO;
    }
    
    BOOL isSuccess = NO;
    // 目标文件已存在要先删除，否则会导致拷贝失败
    if ([fileManager fileExistsAtPath:toPath isDirectory:&isDir]) {
      isSuccess = [NIPRnHotReloadHelper removeFileAtPath:toPath];
      if (!isSuccess) {
        return NO;
      }
    }
    isSuccess = [fileManager copyItemAtPath:filePath toPath:toPath error:&error];
    if (isSuccess && !error) {
      return YES;
    }
  }
  return NO;
}

/**
 拷贝文件夹至某个路径
 
 @param sourcePath 原文件夹路径
 @param destinationPath 目标路径
 @return BOOL
 */
+ (BOOL)copyFolderFrom:(NSString *)sourcePath to:(NSString *)destinationPath
{
  if (![self folderExistAtPath:sourcePath]) {
    return NO;
  }
  
  // 目标文件夹存在要先删除，否则会导致拷贝失败
  if ([self folderExistAtPath:destinationPath]) {
    BOOL hasRemoved = YES;
    hasRemoved = [self removeFolder:destinationPath];
    if (!hasRemoved) {
      return NO;
    }
  }
  
  NSFileManager *fm = [NSFileManager defaultManager];
  NSError *error = nil;
  BOOL isSuccess = [fm copyItemAtPath:sourcePath toPath:destinationPath error:&error];
  
  if (isSuccess && !error) {
    return YES;
  }
  return NO;
}

/**
 移除文件
 
 @param filePath 目标文件路径
 @return BOOL
 */
+ (BOOL)removeFileAtPath:(NSString *)filePath
{
  BOOL res;
  if ([self fileExistAtPath:filePath] == NO) {
    return YES;
  }
  
  NSError *error = nil;
  res = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
  
  if (!error && res) {
    return YES;
  }
  return NO;
}

/**
 移除文件夹
 
 @param folderPath 文件夹路径
 @return BOOL
 */
+ (BOOL)removeFolder:(NSString *)folderPath
{
  BOOL isDir = NO;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  BOOL existed = [fileManager fileExistsAtPath:folderPath isDirectory:&isDir];
  if (existed && isDir) {
    BOOL retVal = [fileManager removeItemAtPath:folderPath error:NULL];
    if (retVal) {
      return YES;
    }
  }
  return NO;
}

/**
 文件是否存在
 
 @param filePath 文件路径
 @return BOOL
 */
+ (BOOL)fileExistAtPath:(NSString *)filePath
{
  BOOL isDir = NO;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  BOOL existed = [fileManager fileExistsAtPath:filePath isDirectory:&isDir];
  return existed && !isDir;
}

/**
 目录是否存在
 
 @param folderPath 目录的路径
 @return BOOL
 */
+ (BOOL)folderExistAtPath:(NSString *)folderPath
{
  BOOL isDir = NO;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  BOOL existed = [fileManager fileExistsAtPath:folderPath isDirectory:&isDir];
  return existed && isDir;
}

/**
 获取当前VC
 
 @param rootViewController 当前的rootViewController
 @return UIViewController
 */
- (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController {
  if ([rootViewController isKindOfClass:[UITabBarController class]]) {
    UITabBarController* tabBarController = (UITabBarController*)rootViewController;
    return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
  } else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
    UINavigationController* navigationController = (UINavigationController*)rootViewController;
    return [self topViewControllerWithRootViewController:navigationController.visibleViewController];
  } else if (rootViewController.presentedViewController) {
    UIViewController* presentedViewController = rootViewController.presentedViewController;
    return [self topViewControllerWithRootViewController:presentedViewController];
  } else {
    return rootViewController;
  }
}

/**
 注册字体文件
 
 @param names 字体文件名数组
 */
+ (void)registerIconFontsByNames:(NSArray *)names{
  NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *document = [docPaths objectAtIndex:0];

  NSArray *files = [NIPRnHotReloadHelper fileNameListOfType:@"ttf" fromDirPath:document];
  NSString *filePath = nil;
  for (NSString *file in files) {
    filePath = [document stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.ttf", file]];
    NSAssert([[NSFileManager defaultManager] fileExistsAtPath:filePath], @"Font file doesn't exist");
    NSData *fontData = [NSData dataWithContentsOfFile:filePath];
    CGDataProviderRef fontDataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef)fontData);
    CGFontRef newFont = CGFontCreateWithDataProvider(fontDataProvider);
    CGDataProviderRelease(fontDataProvider);
    CTFontManagerRegisterGraphicsFont(newFont, nil);
    CGFontRelease(newFont);
  }
  if (!filePath) {
    NSString *wholeName = nil;
    for (NSString *name in names) {
      wholeName = [NSString stringWithFormat:@"%@.ttf", name];
      filePath = [document stringByAppendingPathComponent:wholeName];
      
      NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
      NSString *document = [docPaths objectAtIndex:0];
      NSString *realPath =  [document stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.ttf", name]];
      [NIPRnHotReloadHelper copyFile:[[NSBundle mainBundle] pathForResource:name ofType:@"ttf"] toPath:realPath];
                                                                      
      NSAssert([[NSFileManager defaultManager] fileExistsAtPath:filePath], @"Font file doesn't exist");
      NSData *fontData = [NSData dataWithContentsOfFile:filePath];
      CGDataProviderRef fontDataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef)fontData);
      CGFontRef newFont = CGFontCreateWithDataProvider(fontDataProvider);
      CGDataProviderRelease(fontDataProvider);
      CTFontManagerRegisterGraphicsFont(newFont, nil);
      CGFontRelease(newFont);
    }
  }
}


@end
