//
//  NSFileManager+SW.h
//  HYChatProject
//
//  Created by erpapa on 16/4/24.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (SW)
- (BOOL)createFileAtPath:(NSString *)path contents:(NSData *)contents;
- (BOOL)createFolderAtPath:(NSString *)path;

- (NSString *)documentsDirectory;
- (NSString *)localPath:(NSString *)key;
- (NSString *)bundlePath:(NSString *)fileName;

- (void)checkDir:(NSString *)path;
- (void)deleteFolder:(NSString *)dir;
- (NSArray *)allFilesAtDirectory:(NSString *)directory;
@end
