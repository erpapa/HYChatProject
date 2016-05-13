//
//  HYPhotoNetwork.m
//  HYChatProject
//
//  Created by erpapa on 16/5/12.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYUploadNetwork.h"
#import "GJCFFileUploadManager.h"
#import "GJCFFileDownloadManager.h"

@interface HYUploadNetwork()
@property (nonatomic, strong) NSMutableDictionary *uploadBlockDict;
@property (nonatomic, strong) NSMutableDictionary *downloadBlockDict;
@property (nonatomic, strong) GJCFFileUploadManager *uploadManager;
@property (nonatomic, strong) GJCFFileDownloadManager *downloadManager;
@end

@implementation HYUploadNetwork

/**
 *  单例
 */
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    // dispatch_once宏可以保证块代码中的指令只被执行一次
    static HYUploadNetwork *instance;
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
        [self setImageUploadManager];
    }
    return self;
}

#pragma mark - 上传任务观察
- (void)setImageUploadManager
{
    if (self.uploadManager) {
        self.uploadManager = nil;
    }
    self.uploadManager = [[GJCFFileUploadManager alloc]init];
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
    self.downloadManager = [[GJCFFileDownloadManager alloc] init];
    /* 设定任务观察 */
    [self observeDownloadTask];
}

- (void)observeUploadTask
{
    __weak typeof(self)weakSelf = self;
    
    [self.uploadManager setCompletionBlock:^(GJCFFileUploadTask *task, NSDictionary *resultDict) {
        HYLog(@"文件上传成功 %@",resultDict);
        HYPhotoNetworkDidUploadSuccessBlock block = [weakSelf.uploadBlockDict objectForKey:task.uniqueIdentifier];
        if (block) {
            block(YES);
            [weakSelf.uploadBlockDict removeObjectForKey:task.uniqueIdentifier];
        }
        
    }];
    [self.uploadManager setFaildBlock:^(GJCFFileUploadTask *task, NSError *error) {
        HYLog(@"文件上传失败 %@",error);
        HYPhotoNetworkDidUploadSuccessBlock block = [weakSelf.uploadBlockDict objectForKey:task.uniqueIdentifier];
        if (block) {
            block(NO);
            [weakSelf.uploadBlockDict removeObjectForKey:task.uniqueIdentifier];
        }
        
    }];
    
    [self.uploadManager setProgressBlock:^(GJCFFileUploadTask *updateTask, CGFloat progressValue) {
        
        HYLog(@"文件上传 %.2f%%",progressValue * 100);
    }];
    
    
}

- (void)observeDownloadTask
{
    __weak typeof(self)weakSelf = self;
    [self.downloadManager setDownloadCompletionBlock:^(GJCFFileDownloadTask *task, NSData *fileData, BOOL isFinishCache) {
        HYLog(@"文件下载成功 %.2fKB",fileData.length/1024.0);
        HYPhotoNetworkDidUploadSuccessBlock block = [weakSelf.downloadBlockDict objectForKey:task.taskUniqueIdentifier];
        if (block) {
            block(YES);
            [weakSelf.uploadBlockDict removeObjectForKey:task.taskUniqueIdentifier];
        }
        
    } forObserver:self];
    
    [self.downloadManager setDownloadFaildBlock:^(GJCFFileDownloadTask *task, NSError *error) {
        HYLog(@"文件下载失败 %@",error);
        
        HYPhotoNetworkDidUploadSuccessBlock block = [weakSelf.downloadBlockDict objectForKey:task.taskUniqueIdentifier];
        if (block) {
            block(NO);
            [weakSelf.uploadBlockDict removeObjectForKey:task.taskUniqueIdentifier];
        }
        
    } forObserver:self];
    
    [self.downloadManager setDownloadProgressBlock:^(GJCFFileDownloadTask *task, CGFloat progress) {
        HYLog(@"文件下载进度 %.2f%%",progress * 100);
    } forObserver:self];
}

- (void)startUploadImage:(UIImage *)image imageName:(NSString *)imageName successBlock:(HYPhotoNetworkDidUploadSuccessBlock)successBlock
{
    NSString *taskIdentifier = nil;
    GJCFFileUploadTask *task = [GJCFFileUploadTask taskWithFileData:UIImageJPEGRepresentation(image, 0.6) withFileName:@"?" withFormName:@"file" taskObserver:nil getTaskUniqueIdentifier:&taskIdentifier];
    task.customRequestParams = @{@"key": imageName};
    
    [self.uploadBlockDict setObject:[successBlock copy] forKey:task.uniqueIdentifier];
    if (self.uploadManager) {
        [self.uploadManager addTask:task];
        NSLog(@"HYPhotoNetwork task:%@ begin upload .... ",taskIdentifier);
    }
}

- (void)startUploadVideo:(NSString *)filePath videoName:(NSString *)videoName successBlock:(HYPhotoNetworkDidUploadSuccessBlock)successBlock;
{
    NSString *taskIdentifier = nil;
    GJCFFileUploadTask *task = [GJCFFileUploadTask taskWithFilePath:filePath withFileName:@"?" withFormName:@"file" taskObserver:nil getTaskUniqueIdentifier:&taskIdentifier];
    task.customRequestParams = @{@"key": videoName};
    [self.uploadBlockDict setObject:[successBlock copy] forKey:task.uniqueIdentifier];
    if (self.uploadManager) {
        [self.uploadManager addTask:task];
        NSLog(@"HYPhotoNetwork task:%@ begin upload .... ",taskIdentifier);
    }
}

- (void)startDownloadVideoUrl:(NSString *)videoUrl successBlock:(HYPhotoNetworkDidDownloadSuccessBlock)successBlock
{
    NSString *document = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *dirPath = [NSString stringWithFormat:@"%@/videoCache",document];
    BOOL isDir = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&isDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *filePath = [dirPath stringByAppendingPathComponent:videoUrl.lastPathComponent];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) { // 如果文件已下载
        successBlock(YES);
        return;
    }
    
    NSString *taskIdentifier = nil;
    GJCFFileDownloadTask *task = [GJCFFileDownloadTask taskWithDownloadUrl:videoUrl withCachePath:filePath withObserver:nil getTaskIdentifer:&taskIdentifier];
    [self.downloadBlockDict setObject:[successBlock copy] forKey:task.taskUniqueIdentifier];
    [self.downloadManager addTask:task];
}

@end
