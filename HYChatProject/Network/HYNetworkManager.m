//
//  HYPhotoNetwork.m
//  HYChatProject
//
//  Created by erpapa on 16/5/12.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYNetworkManager.h"
#import "HYFileUploadManager.h"
#import "HYFileDownloadManager.h"
#import "HYEncodeAndDecode.h"
#import "HYUtils.h"

@interface HYNetworkManager()
@property (nonatomic, strong) NSMutableDictionary *uploadBlockDict;
@property (nonatomic, strong) NSMutableDictionary *downloadBlockDict;
@property (nonatomic, strong) HYFileUploadManager *uploadManager;
@property (nonatomic, strong) HYFileDownloadManager *downloadManager;
@end

@implementation HYNetworkManager

/**
 *  单例
 */
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    // dispatch_once宏可以保证块代码中的指令只被执行一次
    static HYNetworkManager *instance;
    dispatch_once(&onceToken, ^{
        instance = [[super alloc] init];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.uploadBlockDict = [NSMutableDictionary dictionary];
        self.downloadBlockDict = [NSMutableDictionary dictionary];
        [self setupManager];
    }
    return self;
}

#pragma mark - 初始化
- (void)setupManager
{
    if (self.uploadManager) {
        self.uploadManager = nil;
    }
    self.uploadManager = [[HYFileUploadManager alloc]init];
    /** 对音频上传进行配置 */
    [self.uploadManager setDefaultHostUrl:QN_UploadHost];
    [self.uploadManager setDefaultUploadPath:QN_UploadHost];
    [self.uploadManager setDefaultRequestHeader:@{@"Content-Type" : @"multipart/form-data"}];
    [self.uploadManager setDefaultRequestParams:@{@"token" : [HYQNAuthPolicy defaultToken]}];
    /* 设定任务观察 */
    [self observeUploadTask];
    
    if (self.downloadManager) {
        self.downloadManager = nil;
    }
    self.downloadManager = [[HYFileDownloadManager alloc] init];
    /* 设定任务观察 */
    [self observeDownloadTask];
}

- (void)observeUploadTask
{
    __weak typeof(self)weakSelf = self;
    
    [self.uploadManager setCompletionBlock:^(HYFileUploadTask *task, NSDictionary *resultDict) {
        HYLog(@"文件上传成功 %@",resultDict);
        HYPhotoNetworkDidUploadSuccessBlock block = [weakSelf.uploadBlockDict objectForKey:task.uniqueIdentifier];
        if (block) {
            block(YES);
            [weakSelf.uploadBlockDict removeObjectForKey:task.uniqueIdentifier];
        }
        
    }];
    [self.uploadManager setFaildBlock:^(HYFileUploadTask *task, NSError *error) {
        HYLog(@"文件上传失败 %@",error);
        HYPhotoNetworkDidUploadSuccessBlock block = [weakSelf.uploadBlockDict objectForKey:task.uniqueIdentifier];
        if (block) {
            block(NO);
            [weakSelf.uploadBlockDict removeObjectForKey:task.uniqueIdentifier];
        }
        
    }];
    
    [self.uploadManager setProgressBlock:^(HYFileUploadTask *updateTask, CGFloat progressValue) {
        
        HYLog(@"文件上传 %.2f%%",progressValue * 100);
    }];
    
    
}

- (void)observeDownloadTask
{
    __weak typeof(self)weakSelf = self;
    [self.downloadManager setDownloadCompletionBlock:^(HYFileDownloadTask *task, NSData *fileData, BOOL isFinishCache) {
        HYLog(@"文件下载成功 %.2fKB",fileData.length/1024.0);
        HYAudioModel *audioModel = [task.userInfo objectForKey:@"audioModel"];
        if (audioModel) { // 转换amr至wav
            [HYEncodeAndDecode convertAudioFileToWAV:audioModel];
        }
        HYPhotoNetworkDidUploadSuccessBlock block = [weakSelf.downloadBlockDict objectForKey:task.taskUniqueIdentifier];
        if (block) {
            block(YES);
            [weakSelf.uploadBlockDict removeObjectForKey:task.taskUniqueIdentifier];
        }
        
    } forObserver:self];
    
    [self.downloadManager setDownloadFaildBlock:^(HYFileDownloadTask *task, NSError *error) {
        HYLog(@"文件下载失败 %@",error);
        
        HYPhotoNetworkDidUploadSuccessBlock block = [weakSelf.downloadBlockDict objectForKey:task.taskUniqueIdentifier];
        if (block) {
            block(NO);
            [weakSelf.uploadBlockDict removeObjectForKey:task.taskUniqueIdentifier];
        }
        
    } forObserver:self];
    
    [self.downloadManager setDownloadProgressBlock:^(HYFileDownloadTask *task, CGFloat progress) {
        HYLog(@"文件下载进度 %.2f%%",progress * 100);
    } forObserver:self];
}

- (void)uploadImage:(NSData *)imageData imageName:(NSString *)imageName successBlock:(HYPhotoNetworkDidUploadSuccessBlock)successBlock
{
    NSString *taskIdentifier = nil;
    HYFileUploadTask *task = [HYFileUploadTask taskWithFileData:imageData withFileName:@"?" withFormName:@"file" taskObserver:nil getTaskUniqueIdentifier:&taskIdentifier];
    task.customRequestParams = @{@"key": imageName};
    
    [self.uploadBlockDict setObject:[successBlock copy] forKey:task.uniqueIdentifier];
    if (self.uploadManager) {
        [self.uploadManager addTask:task];
        NSLog(@"HYPhotoNetwork task:%@ begin upload .... ",taskIdentifier);
    }
}

- (void)uploadFilePath:(NSString *)filePath fileName:(NSString *)fileName successBlock:(HYPhotoNetworkDidUploadSuccessBlock)successBlock;
{
    if (!fileName) {
        fileName = [filePath lastPathComponent];
    }
    NSString *taskIdentifier = nil;
    HYFileUploadTask *task = [HYFileUploadTask taskWithFilePath:filePath withFileName:@"?" withFormName:@"file" taskObserver:nil getTaskUniqueIdentifier:&taskIdentifier];
    task.customRequestParams = @{@"key": fileName};
    [self.uploadBlockDict setObject:[successBlock copy] forKey:task.uniqueIdentifier];
    if (self.uploadManager) {
        [self.uploadManager addTask:task];
        NSLog(@"HYPhotoNetwork task:%@ begin upload .... ",taskIdentifier);
    }
}

/**
 *  下载任务需要设置观察者
 */

- (void)downloadVideoUrl:(NSString *)videoUrl successBlock:(HYPhotoNetworkDidDownloadSuccessBlock)successBlock
{
    NSString *filePath = [HYUtils videoCachePath:videoUrl.lastPathComponent];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) { // 如果文件已下载
        successBlock(YES);
        return;
    }
    
    NSString *taskIdentifier = nil;
    HYFileDownloadTask *task = [HYFileDownloadTask taskWithDownloadUrl:videoUrl withCachePath:filePath withObserver:self getTaskIdentifer:&taskIdentifier];
    [self.downloadBlockDict setObject:[successBlock copy] forKey:task.taskUniqueIdentifier];
    [self.downloadManager addTask:task];
}

- (void)downloadAudioModel:(HYAudioModel *)audioModel successBlock:(HYPhotoNetworkDidDownloadSuccessBlock)successBlock
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:audioModel.localStorePath]) {
        successBlock(YES);
        return;
    }
    
    NSString *taskIdentifier = nil;
    HYFileDownloadTask *task = [HYFileDownloadTask taskWithDownloadUrl:audioModel.remotePath withCachePath:audioModel.tempEncodeFilePath withObserver:self getTaskIdentifer:&taskIdentifier];
    task.userInfo = @{@"audioModel":audioModel};
    [self.downloadBlockDict setObject:[successBlock copy] forKey:task.taskUniqueIdentifier];
    [self.downloadManager addTask:task];
}
@end
