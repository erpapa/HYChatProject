//
//  HYFileDownloadTask.h
//  HYChatProject
//
//  Created by erpapa on 16/5/12.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYFileDownloadTask.h"
#import "HYFileDownloadManager.h"

@interface HYFileDownloadTask ()

@property (nonatomic,strong)NSMutableArray *innerTaskObserverArray;

@property (nonatomic,strong)NSMutableArray *innerTaskCachePathArray;

@end

@implementation HYFileDownloadTask

- (id)init
{
    if (self = [super init]) {
        
        self.taskState = HYFileDownloadStateNeverBegin;
        self.innerTaskObserverArray = [[NSMutableArray alloc]init];
        self.innerTaskCachePathArray = [[NSMutableArray alloc]init];
        self.useDowloadManagerHost = NO;
        _taskUniqueIdentifier = [HYFileDownloadTask currentTimeStamp];
    }
    return self;
}


+ (HYFileDownloadTask *)taskWithDownloadUrl:(NSString *)downloadUrl withCachePath:(NSString*)cachePath withObserver:(NSObject*)observer getTaskIdentifer:(NSString *__autoreleasing *)taskIdentifier
{
    HYFileDownloadTask *task = [[self alloc]init];
    task.downloadUrl = downloadUrl;
    task.cachePath = cachePath;
    if(taskIdentifier){
        *taskIdentifier = task.taskUniqueIdentifier;
    }
    [task addTaskObserver:observer];
    
    return task;
}

+ (NSString *)currentTimeStamp
{
    NSDate *now = [NSDate date];
    NSTimeInterval timeInterval = [now timeIntervalSinceReferenceDate];
    
    NSString *timeString = [NSString stringWithFormat:@"%lf",timeInterval];
    timeString = [timeString stringByReplacingOccurrencesOfString:@"." withString:@"_"];

    return timeString;
}

- (NSArray*)taskObservers
{
    return self.innerTaskObserverArray;
}

#pragma mark - 公开方法

- (void)addTaskObserver:(NSObject*)observer
{
    if (!observer) {
        return;
    }
    NSString *observerUniqueIdentifier = [HYFileDownloadManager uniqueKeyForObserver:observer];
    
    [self.innerTaskObserverArray addObject:observerUniqueIdentifier];
}

- (void)addTaskObserverFromOtherTask:(NSString *)observeIdentifier
{
    [self.innerTaskObserverArray addObject:observeIdentifier];
}

- (void)addTaskCachePath:(NSString *)cachePath
{
    if (cachePath.length == 0) {
        return;
    }
    
    for (NSString *existCachePath in self.innerTaskCachePathArray) {
        
        if ([existCachePath isEqualToString:cachePath]) {
            
            return;
        }
    }
    
    [self.innerTaskCachePathArray addObject:cachePath];
}

- (NSArray *)cacheToPaths
{
    return self.innerTaskCachePathArray;
}

- (void)removeTaskObserver:(NSObject*)observer
{
    if (!observer) {
        return;
    }
    NSString *observerUniqueIdentifier = [HYFileDownloadManager uniqueKeyForObserver:observer];

    [self.innerTaskObserverArray removeObject:observerUniqueIdentifier];
}

/* 任务自检是否能下载 */
- (BOOL)isValidateForDownload
{
    if (!self.downloadUrl) {
        
        return NO;
        
    }else{
        
        return YES;
    }
}

- (BOOL)isEqualToTask:(HYFileDownloadTask *)task
{
    if (!task) {
        return NO;
    }
    
    if ([task.downloadUrl isEqualToString:self.downloadUrl]) {
        
        return YES;
        
    }
    
     return NO;
    
}


@end
