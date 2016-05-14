//
//  HYFileUploadManager.m
//  HYChatProject
//
//  Created by erpapa on 16/5/12.
//  Copyright © 2016年 erpapa. All rights reserved.
//


#import "HYFileUploadManager.h"
#import "AFHTTPRequestOperationManager.h"
#import "AFHTTPRequestOperation.h"
#import <AssetsLibrary/AssetsLibrary.h>

static NSString * HYFileUploadManagerQueue = @"HY.file_upload.queue";

static NSString * HYFileUploadManagerTaskPersistDir = @"HYFileUploadManagerTaskPersistDir";

static NSString * HYFileUploadManagerTaskPersistFile = @"HYFileUploadManagerTaskPersistFile";

static NSString * kFileUploadManagerCompletionBlockKey = @"kFileUploadManagerCompletionBlockKey";

static NSString * kFileUploadManagerProgressBlockKey = @"kFileUploadManagerProgressBlockKey";

static NSString * kFileUploadManagerFaildBlockKey = @"kFileUploadManagerFaildBlockKey";

static NSString * kFileUploadManagerObserverUniqueIdentifier = @"kFileUploadManagerObserverUniqueIdentifier";

static dispatch_queue_t _HYFileUploadManagerOperationQueue ;

@interface HYFileUploadManager ()

@property (nonatomic,strong)NSMutableDictionary *defaultRequestParmas;

@property (nonatomic,strong)NSMutableDictionary *defualtRequestHeader;

@property (nonatomic,strong)NSString     *defaultHostUrl;

@property (nonatomic,strong)NSString     *defaultPath;

@property (nonatomic,strong)NSMutableArray *taskArray;

@property (nonatomic,strong)NSMutableDictionary *observerActionDict;

@property (nonatomic,strong)AFHTTPRequestOperationManager *requestOperationManager;

/* 当前位于前台执行的观察者唯一标示 */
@property (nonatomic,strong)NSString *currentForegroundObserverUniqueIdenfier;

@end

@implementation HYFileUploadManager

+ (HYFileUploadManager*)shareUploadManager
{
    static HYFileUploadManager *_fileUploadManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _HYFileUploadManagerOperationQueue = dispatch_queue_create(HYFileUploadManagerQueue.UTF8String, NULL);
        _fileUploadManager = [[self alloc]init];
    });
    return _fileUploadManager;
}

- (instancetype)initWithOwner:(id)owner
{
    if (self = [super init]) {
        
        self.taskArray = [[NSMutableArray alloc]init];
        self.observerActionDict = [[NSMutableDictionary alloc]init];
        
        if (!_HYFileUploadManagerOperationQueue) {
            _HYFileUploadManagerOperationQueue = dispatch_queue_create(HYFileUploadManagerQueue.UTF8String, NULL);
        }
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:[self taskPersistFilePath]]) {
            [self createDefaultPersistFile];
        }
        
        if (owner) {
            self.currentForegroundObserverUniqueIdenfier = [HYFileUploadManager uniqueKeyForObserver:owner];
        }
    }
    return self;
}

- (id)init
{
    if (self = [super init]) {
        
        self.taskArray = [[NSMutableArray alloc]init];

        if (!_HYFileUploadManagerOperationQueue) {
            _HYFileUploadManagerOperationQueue = dispatch_queue_create(HYFileUploadManagerQueue.UTF8String, NULL);
        }
        
        self.observerActionDict = [[NSMutableDictionary alloc]init];
        [self setDefaultRequestHeader:[NSDictionary dictionary]];
        [self setDefaultRequestParams:[NSDictionary dictionary]];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:[self taskPersistFilePath]]) {
            [self createDefaultPersistFile];
        }
        
    }
    return self;
}

- (NSString*)taskPersistFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *lastPath = [paths lastObject];
    
    NSString *persistDir = [lastPath stringByAppendingPathComponent:HYFileUploadManagerTaskPersistDir];
    
    BOOL isDir = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:persistDir isDirectory:&isDir]) {
        [[NSFileManager defaultManager]createDirectoryAtPath:persistDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *persistFile = [persistDir stringByAppendingPathComponent:HYFileUploadManagerTaskPersistFile];
    
    return persistFile;
}

- (void)createDefaultPersistFile
{
    NSString *path = [self taskPersistFilePath];
    
    NSMutableArray *cacheArray = [NSMutableArray array];
    
    NSData *cacheData = [NSKeyedArchiver archivedDataWithRootObject:cacheArray];
    
    [cacheData writeToFile:path atomically:YES];
}


- (void)persistTask:(HYFileUploadTask *)aTask
{
    if (!aTask) {
        return;
    }
    dispatch_async(_HYFileUploadManagerOperationQueue, ^{
       
        NSData *existData = [NSData dataWithContentsOfFile:[self taskPersistFilePath]];
        NSMutableArray *cacheArray = [NSKeyedUnarchiver unarchiveObjectWithData:existData];
        [cacheArray addObject:aTask];
        
        NSData *cacheData = [NSKeyedArchiver archivedDataWithRootObject:cacheArray];
        [cacheData writeToFile:[self taskPersistFilePath] atomically:YES];
        
    });
}

#pragma mark - 设置信息
- (void)setCurrentObserver:(NSObject *)observer
{
    if (!observer) {
        return;
    }
    
    NSString *observerIdentifier = [HYFileUploadManager uniqueKeyForObserver:observer];
    
    if ([self.currentForegroundObserverUniqueIdenfier isEqualToString:observerIdentifier]) {
        return;
    }
    
    /* 清空原来前台观察者的观察 */
    [self clearCurrentObserveBlocks];
    self.currentForegroundObserverUniqueIdenfier = observerIdentifier;
}

- (void)setDefaultHostUrl:(NSString *)url
{
    _defaultHostUrl = url;
    [self initClient];
}

- (void)setDefaultUploadPath:(NSString *)path
{
    _defaultPath = path;
    [self initClient];

}

- (void)setDefaultRequestParams:(NSDictionary *)parma
{
    _defaultRequestParmas = [NSMutableDictionary dictionaryWithDictionary:parma];
    if (!_defaultRequestParmas) {
        _defaultRequestParmas = [NSMutableDictionary dictionary];
    }
    [self initClient];

}

- (void)setDefaultRequestHeader:(NSDictionary *)requestHeaders
{
    _defualtRequestHeader =  [NSMutableDictionary dictionaryWithDictionary:requestHeaders];
    if (!_defualtRequestHeader) {
        _defualtRequestHeader = [NSMutableDictionary dictionary];
    }
    [self initClient];

}

/*
 * 添加指定文件上传时候的默认HttpHeader
 */
- (void)addRequestHeader:(NSDictionary*)requestHeaders
{
    if (!requestHeaders) {
        return;
    }
    
    if (!_defualtRequestHeader) {
        _defualtRequestHeader = [NSMutableDictionary dictionaryWithDictionary:requestHeaders];
    }
    
    [_defualtRequestHeader addEntriesFromDictionary:requestHeaders];
}

/*
 * 添加文件上传时候的默认参数
 */
- (void)addRequestParams:(NSDictionary*)parmas
{
    if (!parmas) {
        return;
    }
    
    if (!_defaultRequestParmas) {
        _defaultRequestParmas = [NSMutableDictionary dictionaryWithDictionary:parmas];
    }
    
    [_defaultRequestParmas addEntriesFromDictionary:parmas];
}

- (void)initClient
{
    if (!self.defaultHostUrl) {
        NSLog(@"HYFileUpload 初始化 HttpClient 没有设置 Host Url");
        return;
    }
    
    if (self.requestOperationManager) {
        self.requestOperationManager = nil;
    }
    self.requestOperationManager = [[AFHTTPRequestOperationManager alloc]initWithBaseURL:[NSURL URLWithString:self.defaultHostUrl]];
    self.requestOperationManager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
    self.requestOperationManager.responseSerializer.stringEncoding = NSUTF8StringEncoding;
    self.requestOperationManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/json",@"text/javascript",@"application/json",@"text/html",@"application/xhtml+xml",@"*/*",@"application/xhtml+xml",@"image/webp", nil];
    
    
    [self.defualtRequestHeader enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        [self.requestOperationManager.requestSerializer setValue:obj forHTTPHeaderField:key];
        
    }];
}

- (void)constructingBodyWithTask:(HYFileUploadTask *)aTask formData:(id<AFMultipartFormData>)formData
{
    
    NSArray *fileModelArray = aTask.filesArray;
    
    for (HYUploadFileModel *aFile in fileModelArray) {
        
        if (![aFile isKindOfClass:[HYUploadFileModel class]]) {
            continue;
        }else{
            
            /* 如果没有文件二进制数据，那么去读取本地存储文件的路径，根据是否有归档属性去读取文件数据 */
            if (aFile.fileData) {
                
                NSLog(@"HYUploadManager 上传二进制数据包，文件大小:%dKB",aFile.fileData.length / 1024);
                
                [formData appendPartWithFileData:aFile.fileData name:aFile.formName fileName:aFile.fileName mimeType:aFile.mimeType];
                
            }else{
                
                /* 如果是Asset文件 */
                if (aFile.isUploadAsset) {
                    
                    ALAssetRepresentation *representation = [aFile.contentAsset defaultRepresentation];
                    UIImage *assetImage = [UIImage imageWithCGImage:[representation fullResolutionImage] scale:1.0 orientation:(UIImageOrientation)[representation orientation]];
                    /* 读取出大图来*/
                    //UIImage *originImage = HYFixOretationImage(assetImage);
                    NSData *imageData = UIImageJPEGRepresentation(assetImage, 0.7);
                    
                    NSLog(@"HYUploadManager 从Assets中上传图片:%@",aFile.contentAsset);
                    
                    [formData appendPartWithFileData:imageData name:aFile.formName fileName:aFile.fileName mimeType:aFile.mimeType];
                    
                    /*  如果是传图 */
                }else if (aFile.isUploadImage){
                    
                    /* 如果图片被归档了 */
                    if (aFile.isUploadImageHasBeenArchieved) {
                        
                        UIImage *archievedImage = [NSKeyedUnarchiver unarchiveObjectWithFile:aFile.localStorePath];
                        NSData *imageData = UIImageJPEGRepresentation(archievedImage, 0.7);
                        
                        NSLog(@"HYUploadManager 从已归档图片路径上传:%@",aFile.localStorePath);
                        
                        [formData appendPartWithFileData:imageData name:aFile.formName fileName:aFile.fileName mimeType:aFile.mimeType];
                        
                    }else{
                        
                        NSLog(@"HYUploadManager 从未归档图片路径上传:%@",aFile.localStorePath);
                        
                        NSData *imageData = [NSData dataWithContentsOfFile:aFile.localStorePath];
                        [formData appendPartWithFileData:imageData name:aFile.formName fileName:aFile.fileName mimeType:aFile.mimeType];
                    }
                    
                    /* 如果是传语音 */
                }else if (aFile.isUploadAudio){
                    
                    NSLog(@"HYUploadManager 从本地语音文件路径上传:%@",aFile.localStorePath);
                    
                    NSData *audioData = [NSData dataWithContentsOfFile:aFile.localStorePath];
                    
                    [formData appendPartWithFileData:audioData name:aFile.formName fileName:aFile.fileName mimeType:aFile.mimeType];
                    
                }else{
                    
                    NSLog(@"HYUploadManager 任意本地文件路径上传:%@",aFile.localStorePath);
                    
                    /* 都不是,默认传路径中的二进制数据 */
                    NSData *fileData = [NSData dataWithContentsOfFile:aFile.localStorePath];
                    if (fileData) {
                        
                        
                        
                        [formData appendPartWithFileData:fileData name:aFile.formName fileName:aFile.fileName mimeType:aFile.mimeType];
                    }
                }
                
            }
        }
    }
    
}

- (void)addTask:(HYFileUploadTask *)aTask
{
    /* 任务自检 */
    if (![aTask isValidateBeingForUpload] || !aTask) {
        NSLog(@"HYFileUploadManager 任务ID:%@ 待上传任务不合法,无法开始任务",aTask.uniqueIdentifier);
        return;
    }
    
    dispatch_async(_HYFileUploadManagerOperationQueue, ^{
       
        if (aTask.uploadState != GJFileUploadStateHadFaild && aTask.uploadState != GJFileUploadStateCancel) {
            [self.taskArray addObject:aTask];
        }
        
        //如果没有指定任务观察者，将任务观察者设定为当前任务观察者
        if (aTask.taskObservers == nil || aTask.taskObservers.count == 0) {
            [aTask addNewTaskObserverUniqueIdentifier:self.currentForegroundObserverUniqueIdenfier];
        }
        
        [self.defaultRequestParmas addEntriesFromDictionary:aTask.customRequestParams];
        
        
        [aTask.customRequestHeader enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            
            [self.requestOperationManager.requestSerializer setValue:obj forHTTPHeaderField:key];
            
        }];
        
        __weak typeof(HYFileUploadTask) * weakTask = aTask;
        
        AFHTTPRequestOperation *uploadOperation = [self.requestOperationManager POST:self.defaultPath parameters:self.defaultRequestParmas constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            
            [self constructingBodyWithTask:weakTask formData:formData]; // 使用task判断类型，得到对应的二进制数据
            
            
        } success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            dispatch_async(_HYFileUploadManagerOperationQueue, ^{
                
                HYFileUploadTask *task = [operation.userInfo objectForKey:@"task"];
                
                NSDictionary *resultJson = responseObject;
                
                NSDictionary *resultDict = @{@"result":resultJson};
                
                [self completionWithTask:task withResultDict:resultDict];
                
                /* 更新任务状态 */
                [self updateTask:task.uniqueIdentifier withState:GJFileUploadStateSuccess];
                
                [self.taskArray removeObject:aTask];
                
            });
            
            
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            dispatch_async(_HYFileUploadManagerOperationQueue, ^{
                
                HYFileUploadTask *task = [operation.userInfo objectForKey:@"task"];
                
                /* 更新任务状态 */
                [self updateTask:task.uniqueIdentifier withState:GJFileUploadStateHadFaild];
                
                [self faildWithTask:task withError:error];
                
            });
            
            
        }];
        
        
        uploadOperation.userInfo = @{@"task": aTask};
        
        __weak typeof (uploadOperation) weakOperation = uploadOperation;
        [uploadOperation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            
            dispatch_async(_HYFileUploadManagerOperationQueue, ^{
                
                HYFileUploadTask *task = [weakOperation.userInfo objectForKey:@"task"];
                
                CGFloat uploadKbSize = totalBytesWritten/1024.0f;
                CGFloat totoalSize = totalBytesExpectedToWrite/1024.0f;
                CGFloat uploadProgressValue = (uploadKbSize/1024.f)/(totoalSize/1024.f);
                
                [self progressWithTask:task withPercentValue:uploadProgressValue];
                
            });
            
        }];
        
        NSLog(@"HYUploadFile begin upload for task:%@ ....",aTask.uniqueIdentifier);
        
        /* 更新任务状态 */
        [self updateTask:aTask.uniqueIdentifier withState:GJFileUploadStateUploading];
        
    });
}

- (void)updateTask:(NSString*)aTaskIdentifier withState:(HYFileUploadState)uploadState
{
    for (int i = 0 ; i < self.taskArray.count ; i++) {
        
        HYFileUploadTask *task = [self.taskArray objectAtIndex:i];
        
        if ([task.uniqueIdentifier isEqual:aTaskIdentifier]) {
            
            task.uploadState = uploadState;
            
            [self.taskArray replaceObjectAtIndex:i withObject:task];
            
            break;
        }
        
    }
}

- (void)completionWithTask:(HYFileUploadTask *)aTask withResultDict:(NSDictionary*)resultDict
{
    /* 找到响应的block */
    if (aTask.taskObservers == nil || aTask.taskObservers.count == 0) {
        if (self.completionBlock) {
            self.completionBlock(aTask,resultDict);
        }
    }
    
    /* 是设定的前台响应的这个对象 */
    if ([aTask taskIsObservedByUniqueIdentifier:self.currentForegroundObserverUniqueIdenfier]) {
        if (self.completionBlock) {
            self.completionBlock(aTask,resultDict);
        }
    }
    
    for (NSString *taskObserverIdentifier in aTask.taskObservers) {
        
        NSMutableDictionary *existActionDict = [self.observerActionDict objectForKey:taskObserverIdentifier];
        
        if (existActionDict) {
            
            HYFileUploadManagerTaskCompletionBlock successBlock = [existActionDict objectForKey:kFileUploadManagerCompletionBlockKey];
            
            if (successBlock) {
                
                successBlock(aTask,resultDict);
                
            }
        }
        
    }
    
}

-(void)faildWithTask:(HYFileUploadTask *)aTask withError:(NSError *)error
{
    /* 找到响应的block */
    if (aTask.taskObservers == nil || aTask.taskObservers.count == 0) {
        if (self.faildBlock) {
            self.faildBlock(aTask,error);
        }
    }
    
    /* 是设定的前台响应的这个对象 */
    if ([aTask taskIsObservedByUniqueIdentifier:self.currentForegroundObserverUniqueIdenfier]) {
        if (self.faildBlock) {
            self.faildBlock(aTask,error);
        }
    }
    
    for (NSString *taskObserverIdentifier in aTask.taskObservers) {
        
        NSMutableDictionary *existActionDict = [self.observerActionDict objectForKey:taskObserverIdentifier];
        
        if (existActionDict) {
            
            HYFileUploadManagerTaskFaildBlock faildBlock = [existActionDict objectForKey:kFileUploadManagerFaildBlockKey];
            
            if (faildBlock) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    faildBlock(aTask,error);

                });
                
            }
            
        }
        
    }
    
}

- (void)progressWithTask:(HYFileUploadTask *)aTask withPercentValue:(CGFloat)percent
{
    /* 找到响应的block */
    if (aTask.taskObservers == nil || aTask.taskObservers.count == 0) {
        if (self.progressBlock) {
            self.progressBlock(aTask,percent);
        }
    }
    
    /* 是设定的前台响应的这个对象 */
    if ([aTask taskIsObservedByUniqueIdentifier: self.currentForegroundObserverUniqueIdenfier]) {
        if (self.progressBlock) {
            self.progressBlock(aTask,percent);
        }
    }
    
    for (NSString *taskObserverIdentifier in aTask.taskObservers) {
        
        NSMutableDictionary *existActionDict = [self.observerActionDict objectForKey:taskObserverIdentifier];
        
        if (existActionDict) {
            
            HYFileUploadManagerUpdateTaskProgressBlock progressBlock = [existActionDict objectForKey:kFileUploadManagerProgressBlockKey];
            
            if (progressBlock) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    progressBlock(aTask,percent);

                });
            }
            
        }
        
    }
}

- (void)cancelTaskOnly:(NSString *)aTaskIdentifier
{
    [self cancelTask:aTaskIdentifier shouldRemove:NO];
}

- (void)cancelTaskAndRemove:(NSString *)aTaskIdentifier
{
    [self cancelTask:aTaskIdentifier shouldRemove:YES];
}

- (void)cancelTask:(NSString *)aTaskIdentifier shouldRemove:(BOOL)remove
{
    
    dispatch_async(_HYFileUploadManagerOperationQueue, ^{
        
        /* 推出请求 */
        [self.requestOperationManager.operationQueue.operations enumerateObjectsUsingBlock:^(AFHTTPRequestOperation *operation, NSUInteger idx, BOOL *stop) {
            
            HYFileUploadTask *destTask = [operation.userInfo objectForKey:@"task"];
            
            if ([destTask.uniqueIdentifier isEqualToString:aTaskIdentifier]) {
                
                [operation cancel];
                
                *stop = YES;
            }
            
        }];
        
        /* 更新任务状态 */
        [self updateTask:aTaskIdentifier withState:GJFileUploadStateCancel];
        
        if (remove) {
            
            /* 移除任务 */
            for (HYFileUploadTask *task in self.taskArray) {
                
                if ([task.uniqueIdentifier isEqual:aTaskIdentifier]) {
                    
                    [self.taskArray removeObject:task];
                    
                    break;
                }
            }
            
        }
        
    });
    
}

- (void)removeTask:(HYFileUploadTask *)aTask
{
    [self cancelTaskAndRemove:aTask.uniqueIdentifier];
}

- (void)cancelAllExcutingTask
{
    [self.taskArray enumerateObjectsUsingBlock:^(HYFileUploadTask *task, NSUInteger idx, BOOL *stop) {
        
        if (task.uploadState == GJFileUploadStateUploading) {
            
            [self cancelTaskOnly:task.uniqueIdentifier];
            
            *stop = YES;
        }
    }];
}

- (void)removeAllTask
{
    [self.taskArray enumerateObjectsUsingBlock:^(HYFileUploadTask *task, NSUInteger idx, BOOL *stop) {
        
        [self cancelTaskAndRemove:task.uniqueIdentifier];
        
    }];
}

- (void)removeAllFaildTask
{
    [self.taskArray enumerateObjectsUsingBlock:^(HYFileUploadTask *task, NSUInteger idx, BOOL *stop) {
        
        if (task.uploadState == GJFileUploadStateHadFaild) {
            
            [self cancelTaskAndRemove:task.uniqueIdentifier];
            
        }
        
    }];
}

- (void)tryDoTaskByUniqueIdentifier:(NSString*)uniqueIdentifier
{
    [self.taskArray enumerateObjectsUsingBlock:^(HYFileUploadTask *task, NSUInteger idx, BOOL *stop) {
        
        if (task.uploadState == GJFileUploadStateHadFaild && [task.uniqueIdentifier isEqualToString:uniqueIdentifier]) {
            
            [self addTask:task];
        }
        
    }];
}

- (void)tryDoAllUnSuccessTask
{
    [self.taskArray enumerateObjectsUsingBlock:^(HYFileUploadTask *task, NSUInteger idx, BOOL *stop) {
        
        if (task.uploadState == GJFileUploadStateHadFaild) {
            
            [self addTask:task];
        }
    }];
}

- (void)persistAllFaildAndCanceledTask
{
    [self.taskArray enumerateObjectsUsingBlock:^(HYFileUploadTask *task, NSUInteger idx, BOOL *stop) {
        
        if (task.uploadState == GJFileUploadStateCancel || task.uploadState == GJFileUploadStateHadFaild) {
            
            [self persistTask:task];
        }
        
    }];
}

#pragma mark - 观察者调用
+ (NSString*)uniqueKeyForObserver:(NSObject*)observer
{
    return [NSString stringWithFormat:@"%@_%d",kFileUploadManagerObserverUniqueIdentifier,[observer hash]];
}

/* 为某个观察对象建立成功观察状态block */
- (void)setCompletionBlock:(HYFileUploadManagerTaskCompletionBlock)completionBlock forObserver:(NSObject*)observer
{
    if (!observer) {
        return;
    }
    
    NSString *observerActionInfoKey = [HYFileUploadManager uniqueKeyForObserver:observer];
    
    if (![self.observerActionDict objectForKey:observerActionInfoKey]) {
        
        NSMutableDictionary *observerInfo = [NSMutableDictionary dictionary];
        [observerInfo setObject:completionBlock forKey:kFileUploadManagerCompletionBlockKey];
        
        [self.observerActionDict setObject:observerInfo forKey:observerActionInfoKey];
        return;
    }
    
    NSMutableDictionary *existActionDict = [self.observerActionDict objectForKey:observerActionInfoKey];
    [existActionDict setObject:completionBlock forKey:kFileUploadManagerCompletionBlockKey];
    
}

/* 为某个观察对象建立进度观察状态block */
- (void)setProgressBlock:(HYFileUploadManagerUpdateTaskProgressBlock)progressBlock forObserver:(NSObject*)observer
{
    if (!observer) {
        return;
    }
    
    NSString *observerActionInfoKey = [HYFileUploadManager uniqueKeyForObserver:observer];
    
    if (![self.observerActionDict objectForKey:observerActionInfoKey]) {
        
        NSMutableDictionary *observerInfo = [NSMutableDictionary dictionary];
        [observerInfo setObject:progressBlock forKey:kFileUploadManagerProgressBlockKey];
        
        [self.observerActionDict setObject:observerInfo forKey:observerActionInfoKey];
        return;
    }
    
    NSMutableDictionary *existActionDict = [self.observerActionDict objectForKey:observerActionInfoKey];
    [existActionDict setObject:progressBlock forKey:kFileUploadManagerProgressBlockKey];
}

/* 为某个观察对象建立失败观察状态block */
- (void)setFaildBlock:(HYFileUploadManagerTaskFaildBlock)faildBlock forObserver:(NSObject*)observer
{
    if (!observer) {
        return;
    }
    
    NSString *observerActionInfoKey = [HYFileUploadManager uniqueKeyForObserver:observer];
    
    if (![self.observerActionDict objectForKey:observerActionInfoKey]) {
        
        NSMutableDictionary *observerInfo = [NSMutableDictionary dictionary];
        [observerInfo setObject:faildBlock forKey:kFileUploadManagerFaildBlockKey];
        
        [self.observerActionDict setObject:observerInfo forKey:observerActionInfoKey];
        return;
    }
    
    NSMutableDictionary *existActionDict = [self.observerActionDict objectForKey:observerActionInfoKey];
    [existActionDict setObject:faildBlock forKey:kFileUploadManagerFaildBlockKey];
}

- (void)clearCurrentObserveBlocks
{
    /* 将前台设定的block清除 */
    self.completionBlock = nil;
    self.faildBlock = nil;
    self.progressBlock = nil;
    
    if (self.currentForegroundObserverUniqueIdenfier) {
        [self.observerActionDict removeObjectForKey:self.currentForegroundObserverUniqueIdenfier];
    }
    
}

/* 清除某个观察者的block引用 */
- (void)clearBlockForObserver:(NSObject*)observer
{
    if (self.currentForegroundObserverUniqueIdenfier) {
        /* 将前台设定的block清除 */
        self.completionBlock = nil;
        self.faildBlock = nil;
        self.progressBlock = nil;
    }
    
    if (!observer) {
        return;
    }
    
    NSString *observerActionInfoKey = [HYFileUploadManager uniqueKeyForObserver:observer];
    if (observerActionInfoKey) {
        [self.observerActionDict removeObjectForKey:observerActionInfoKey];
    }
    
}

@end
