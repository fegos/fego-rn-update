//
//  NIPRnHotReloadHelper.m
//  hotUpdate
//
//  Created by zramals on 2017/12/22.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "NIPRnHotReloadHelper.h"
#import <CoreText/CoreText.h>
#import <CommonCrypto/CommonDigest.h>

#define FileHashDefaultChunkSizeForReadingData 1024*8

@interface NIPRnHotReloadHelper()

@end


@implementation NIPRnHotReloadHelper

static NSFileManager *fileManager;

+ (NSFileManager *)fileManager {
    if (!fileManager) {
        fileManager = [NSFileManager defaultManager];
    }
    return fileManager;
}

/**
 * 文件系统私有方法，获取bundle文件
 *
 * @param filetype 文件类型
 * @param directory 文件路径
 * @return NSArray
 */
+ (NSArray *)filenameArrayOfType:(NSString *)filetype inDirectory:(NSString *)directory {
    NSMutableArray *filenameArray = [NSMutableArray arrayWithCapacity:10];
    NSArray *fullFileArray = [[self fileManager] contentsOfDirectoryAtPath:directory error:nil];
    for (NSString *fullFilename in fullFileArray) {
        if ([fullFilename.pathExtension isEqualToString:filetype]) {
            [filenameArray addObject:[fullFilename stringByDeletingPathExtension]];
        }
    }
    return filenameArray;
}

/**
 * 拷贝文件到某个路径
 *
 * @param srcPath 源文件路径
 * @param dstPath 目标文件路径
 * @return BOOL
 */
+ (BOOL)copyFileAtPath:(NSString *)srcPath toPath:(NSString *)dstPath {
    BOOL isDir = NO;
    NSFileManager *fileManager = [self fileManager];
    BOOL fileExisted = [fileManager fileExistsAtPath:srcPath isDirectory:&isDir];
    if (fileExisted && !isDir) {
        NSString *toDirectory = [dstPath stringByDeletingLastPathComponent];
        NSError *err = nil;
        BOOL dirExist = [fileManager fileExistsAtPath:toDirectory isDirectory:&isDir];
        if (dirExist) {
            if (!isDir) {
                NSLog(@"\n##NIPRnHotReloadHelper**目标路径不存在。");
                return NO;
            }
        } else {
            [fileManager createDirectoryAtPath:toDirectory
                   withIntermediateDirectories:YES
                                    attributes:nil
                                         error:&err];
        }
        if (err) {
            NSLog(@"\n##NIPRnHotReloadHelper**创建目标路径失败：%@", toDirectory);
            return NO;
        }
        
        BOOL isSuccess = NO;
        // 目标文件已存在要先删除，否则会导致拷贝失败
        if ([fileManager fileExistsAtPath:dstPath isDirectory:&isDir]) {
            isSuccess = [self removeFileAtPath:dstPath];
            if (!isSuccess) {
                return NO;
            }
        }
        [fileManager copyItemAtPath:srcPath
                             toPath:dstPath
                              error:&err];
        if (!err) {
            return YES;
        }
    }
    return NO;
}

/**
 * 拷贝文件夹至某个路径
 *
 * @param srcPath 源路径
 * @param dstPath 目标路径
 * @return BOOL
 */
+ (BOOL)copyFolderAtPath:(NSString *)srcPath toPath:(NSString *)dstPath {
    if (![self folderExistAtPath:srcPath]) {
        return NO;
    }
    // 目标文件夹存在要先删除，否则会导致拷贝失败
    if ([self folderExistAtPath:dstPath]) {
        if (![self removeFolderAtPath:dstPath]) {
            return NO;
        }
    }
    NSString *dstPathParentDir = [dstPath stringByDeletingLastPathComponent];
    NSFileManager *fileManager = [self fileManager];
    NSError *err = nil;
    if (![self folderExistAtPath:dstPathParentDir]) {
        [fileManager createDirectoryAtPath:dstPathParentDir
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&err];
    }
    if(!err) {
        [fileManager copyItemAtPath:srcPath
                             toPath:dstPath
                              error:&err];
        if (!err) {
            return YES;
        }
    }
    return NO;
}

/**
 * 移除文件
 *
 * @param filePath 需要删除的文件路径
 * @return BOOL
 */
+ (BOOL)removeFileAtPath:(NSString *)filePath {
    if (![self fileExistAtPath:filePath]) {
        return YES;
    }
    NSError *err = nil;
    [[self fileManager] removeItemAtPath:filePath error:&err];
    if (!err) {
        return YES;
    }
    return NO;
}

/**
 * 移除文件夹
 *
 * @param folderPath 文件夹路径
 * @return BOOL
 */
+ (BOOL)removeFolderAtPath:(NSString *)folderPath {
    if (![self folderExistAtPath:folderPath]) {
        return YES;
    }
    NSError *err;
    [[self fileManager] removeItemAtPath:folderPath error:&err];
    if (!err) {
        return YES;
    }
    return NO;
}

/**
 * 文件是否存在
 *
 * @param filePath 文件路径
 * @return BOOL
 */
+ (BOOL)fileExistAtPath:(NSString *)filePath {
    BOOL isDir = NO;
    BOOL existed = [[self fileManager] fileExistsAtPath:filePath isDirectory:&isDir];
    return existed && !isDir;
}

/**
 * 文件夹是否存在
 *
 * @param folderPath 文件夹路径
 * @return BOOL
 */
+ (BOOL)folderExistAtPath:(NSString *)folderPath {
    BOOL isDir = NO;
    BOOL existed = [[self fileManager] fileExistsAtPath:folderPath isDirectory:&isDir];
    return existed && isDir;
}

/**
 * 获取目标VC的顶层VC
 *
 * @param  targetVC 目标VC
 * @return UIViewController
 */
+ (UIViewController *)topViewControllerOfTargetViewController:(UIViewController*)targetVC {
    if ([targetVC isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)targetVC;
        return [self topViewControllerOfTargetViewController:tabBarController.selectedViewController];
    } else if ([targetVC isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController*)targetVC;
        return [self topViewControllerOfTargetViewController:navigationController.visibleViewController];
    } else if (targetVC.presentedViewController) {
        UIViewController* presentedViewController = targetVC.presentedViewController;
        return [self topViewControllerOfTargetViewController:presentedViewController];
    } else {
        return targetVC;
    }
}

/**
 * 注册字体文件
 *
 * @param fontNameArray 字体文件名数组
 * @param directory 存放字体文件的目录
 */
+ (void)registerFontFamilies:(NSArray *)fontNameArray inDirectory:(NSString *)directory {
    if (!directory) {
        NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        directory = [docPaths objectAtIndex:0];
    }
    for (NSString *fontName in fontNameArray) {
        NSString *fullName = [NSString stringWithFormat:@"%@.ttf", fontName];
        NSString *fontFilePath = [directory stringByAppendingPathComponent:fullName];
        if (![self fileExistAtPath:fontFilePath]) {
            NSString *srcFontFilePath = [[NSBundle mainBundle] pathForResource:fontName ofType:@"ttf"];
            [self copyFileAtPath:srcFontFilePath toPath:fontFilePath];
        }
        [self registerFontFamilyWithName:fontName inDirectory:directory];
    }
}

/**
 * 注册字体文件
 *
 * @param fontFamilyName 字体文件名称
 * @param directory 存放字体文件的目录
 */
+ (void)registerFontFamilyWithName:(NSString *)fontFamilyName inDirectory:(NSString *)directory {
    if (!directory) {
        NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        directory = [docPaths objectAtIndex:0];
    }
    NSString *fullName = [NSString stringWithFormat:@"%@.ttf", fontFamilyName];
    NSString *fontFilePath = [directory stringByAppendingPathComponent:fullName];
    if ([self fileExistAtPath:fontFilePath]) {
        NSData *fontData = [NSData dataWithContentsOfFile:fontFilePath];
        CGDataProviderRef fontDataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef)fontData);
        CGFontRef newFont = CGFontCreateWithDataProvider(fontDataProvider);
        CGDataProviderRelease(fontDataProvider);
        CTFontManagerRegisterGraphicsFont(newFont, nil);
        CGFontRelease(newFont);
    } else {
        NSLog(@"\n##NIPRnHotReloadHelper**不存在fontFamily,font name: %@  目录：%@", fontFamilyName, fontFilePath);
    }
}

/**
 * 生成文件MD5值
 *
 * @param filePath 文件路径
 */
+ (NSString*)generateMD5ForFileAtPath:(NSString*)filePath {
    return (__bridge_transfer NSString *)FileMD5HashCreateWithPath((__bridge CFStringRef)filePath, FileHashDefaultChunkSizeForReadingData);
}


CFStringRef FileMD5HashCreateWithPath(CFStringRef filePath,size_t chunkSizeForReadingData) {
    // Declare needed variables
    CFStringRef result = NULL;
    CFReadStreamRef readStream = NULL;
    // Get the file URL
    CFURLRef fileURL =
    CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                  (CFStringRef)filePath,
                                  kCFURLPOSIXPathStyle,
                                  (Boolean)false);
    if (!fileURL) goto done;
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
                                            (CFURLRef)fileURL);
    if (!readStream) goto done;
    bool didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed) goto done;
    // Initialize the hash object
    CC_MD5_CTX hashObject;
    CC_MD5_Init(&hashObject);
    // Make sure chunkSizeForReadingData is valid
    if (!chunkSizeForReadingData) {
        chunkSizeForReadingData = FileHashDefaultChunkSizeForReadingData;
    }
    // Feed the data to the hash object
    bool hasMoreData = true;
    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,(UInt8 *)buffer,(CFIndex)sizeof(buffer));
        if (readBytesCount == -1) break;
        if (readBytesCount == 0) {
            hasMoreData = false;
            continue;
        }
        CC_MD5_Update(&hashObject,(const void *)buffer,(CC_LONG)readBytesCount);
    }
    // Check if the read operation succeeded
    didSucceed = !hasMoreData;
    // Compute the hash digest
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &hashObject);
    // Abort if the read operation failed
    if (!didSucceed) goto done;
    // Compute the string result
    char hash[2 * sizeof(digest) + 1];
    for (size_t i = 0; i < sizeof(digest); ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }
    result = CFStringCreateWithCString(kCFAllocatorDefault,(const char *)hash,kCFStringEncodingUTF8);
    
done:
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    return result;
}

@end

