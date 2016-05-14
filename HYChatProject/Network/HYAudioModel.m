//
//  HYAudioModel.m
//  GJCommonFoundation
//
//  Created by ZYVincent QQ:1003081775 on 14-9-16.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import "HYAudioModel.h"
#import "HYUtils.h"
#import "HYQNAuthPolicy.h"

@implementation HYAudioModel

- (id)init
{
    if (self = [super init]) {
        
        _uniqueIdentifier = [self currentTimeStamp];
        self.isDeleteWhileFinishConvertToLocalFormate = NO;
        self.isDeleteWhileUploadFinish = NO;
        self.shouldPlayWhileFinishDownload = NO;
        /* 设定默认文件后缀 */
        self.extensionName = @"wav";
        self.tempEncodeFileExtensionName = @"amr";
        
        self.mimeType = @"application/octet-stream";
    }
    return self;
}

- (NSString *)remotePath
{
    if (self.fileName.length) {
        NSString *remoteName = [self.fileName stringByAppendingPathExtension:self.tempEncodeFileExtensionName];
        return QN_FullURL(remoteName);
    }
    return _remotePath;
}

- (NSString *)localStorePath
{
    if (self.fileName.length) {
        NSString *wavName = [self.fileName stringByAppendingPathExtension:self.extensionName];
        return [HYUtils audioTempEncodeFilePath:wavName];
    }
    return _localStorePath;
}

- (NSString *)tempEncodeFilePath{
    if (self.fileName.length) {
        NSString *amrName = [self.fileName stringByAppendingPathExtension:self.tempEncodeFileExtensionName];
        return [HYUtils audioTempEncodeFilePath:amrName];
    }
    return _tempEncodeFilePath;
}

- (NSString *)currentTimeStamp
{
    NSDate *now = [NSDate date];
    NSTimeInterval timeInterval = [now timeIntervalSinceReferenceDate];
    
    NSString *timeString = [NSString stringWithFormat:@"%lf",timeInterval];
    
    return timeString;
}


/* 删除临时编码文件 */
- (void)deleteTempEncodeFile
{
    if (self.tempEncodeFilePath && ![self.localStorePath isEqualToString:@""]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.tempEncodeFilePath error:nil];
    }
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"文件Wav路径:%@ 远程路径:%@ 临时转码文件路径:%@",self.localStorePath,self.remotePath,self.tempEncodeFilePath];
}

/* 删除本地wav格式文件 */
- (void)deleteWavFile
{
    if (self.localStorePath && ![self.localStorePath isEqualToString:@""]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.localStorePath error:nil];
    }
}


@end
