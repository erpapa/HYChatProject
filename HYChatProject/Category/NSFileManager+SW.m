//
//  NSFileManager+SW.m
//  HYChatProject
//
//  Created by erpapa on 16/4/24.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "NSFileManager+SW.h"

@implementation NSFileManager(SW)

- (BOOL)createFileAtPath:(NSString *)path contents:(NSData *)contents
{
    NSString* dir = [path stringByDeletingLastPathComponent];
    if(![self createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil])
    {
        return NO;
    }
    
    return [self createFileAtPath:path contents:contents attributes:nil];
}
- (BOOL)createFolderAtPath:(NSString *)path
{
    return ![self createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
}

- (NSString *)documentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];

    return documentsDirectory;
}

- (NSString *)localPath:(NSString *)key
{
    NSString *documentsDirectory = [self documentsDirectory];
    NSString *localPath = [documentsDirectory stringByAppendingPathComponent:key];
    return localPath;
}

- (NSString *)bundlePath:(NSString *)fileName
{
    return [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
}

- (void)checkDir:(NSString *)path
{
    BOOL dir = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
}
- (void)deleteFolder:(NSString *)dir
{
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:NULL];
    NSEnumerator *enumerator = [contents objectEnumerator];
    NSString *filename;
    while ((filename = [enumerator nextObject])) {
        [[NSFileManager defaultManager] removeItemAtPath:[dir stringByAppendingPathComponent:filename] error:NULL];
    }
}

- (NSArray *)allFilesAtDirectory:(NSString *)directory;
{
    NSMutableArray* array = [NSMutableArray array];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray* tempArray = [fileManager contentsOfDirectoryAtPath:directory error:nil];
    
    for (NSString *fileName in tempArray) {
        BOOL flag = YES;
        NSString *fullPath = [directory stringByAppendingPathComponent:fileName];
        
        if ([fileManager fileExistsAtPath:fullPath isDirectory:&flag]) {
            if (!flag) {
                [array addObject:fullPath];
            } else {
                [array addObjectsFromArray:[self allFilesAtDirectory:fullPath]];
            }
        }
        
    }
    
    return array;
}

@end
