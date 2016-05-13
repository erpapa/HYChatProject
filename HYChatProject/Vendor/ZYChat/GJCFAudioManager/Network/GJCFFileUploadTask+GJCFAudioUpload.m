//
//  GJCFFileUploadTask+GJCFAudioUpload.m
//  GJCommonFoundation
//
//  Created by ZYVincent QQ:1003081775 on 14-9-18.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import "GJCFFileUploadTask+GJCFAudioUpload.h"
#import "GJCFAudioFileUitil.h"
#import "GJCFUploadFileModel.h"

@implementation GJCFFileUploadTask (GJCFAudioUpload)

+ (GJCFFileUploadTask *)taskWithAudioFile:(GJCFAudioModel*)audioFile withObserver:(NSObject*)observer withTaskIdentifier:(NSString *__autoreleasing *)taskIdentifier
{
    GJCFFileUploadTask *task = [GJCFFileUploadTask taskWithFilePath:audioFile.tempEncodeFilePath withFileName:@"?" withFormName:@"file" taskObserver:nil getTaskUniqueIdentifier:taskIdentifier];
    
    //自定义请求的Header
//    NSString *tokenUp = [HYQNAuthPolicy defaultToken];
//    NSString *UpToken = [NSString stringWithFormat:@"UpToken %@",tokenUp];
//     NSDictionary *customRequestHeader = @{@"Content-Type" : @"multipart/form-data", @"Authorization" : UpToken};
//    task.customRequestHeader = customRequestHeader;
    
    //自定义请求参数(没有该参数，七牛云将会自动命名)
    [GJCFAudioFileUitil setupAudioFileRemoteUrl:audioFile]; // 设置远程地址
    NSString *fileName = [audioFile.remotePath lastPathComponent];
    task.customRequestParams = @{@"key": fileName};
    
    //设置原始的文件对象
    task.userInfo = @{@"audioFile": audioFile};
    GJCFUploadFileModel *uploadFileModel = [GJCFUploadFileModel fileModelWithFileName:fileName withFilePath:audioFile.tempEncodeFilePath withFormName:@"file" withMimeType:@"application/octet-stream"];
    [task.filesArray removeAllObjects];
    [task.filesArray addObject:uploadFileModel];

    return task;
}

@end
