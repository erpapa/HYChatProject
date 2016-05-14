//
//  HYFileDownloadManager
//  HYChatProject
//
//  Created by erpapa on 16/5/12.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HYFileDownloadTask.h"

@class HYFileDownloadTask;

typedef void (^HYFileDownloadManagerCompletionBlock) (HYFileDownloadTask *task,NSData *fileData,BOOL isFinishCache);

typedef void (^HYFileDownloadManagerProgressBlock) (HYFileDownloadTask *task,CGFloat progress);

typedef void (^HYFileDownloadManagerFaildBlock) (HYFileDownloadTask *task,NSError *error);

@interface HYFileDownloadManager : NSObject


+ (HYFileDownloadManager *)shareDownloadManager;


/* 设置下载服务器地址，不是必须的，是为了用来当没有主机地址的时候，可以用来补全 */
- (void)setDefaultDownloadHost:(NSString *)host;


/* 添加一个下载任务 */
- (void)addTask:(HYFileDownloadTask *)task;

/*
 * 观察者唯一标识生成方法
 */
+ (NSString*)uniqueKeyForObserver:(NSObject*)observer;

/* 
 * 设定观察者完成方法
 */
- (void)setDownloadCompletionBlock:(HYFileDownloadManagerCompletionBlock)completionBlock forObserver:(NSObject*)observer;

/*
 * 设定观察者进度方法
 */
- (void)setDownloadProgressBlock:(HYFileDownloadManagerProgressBlock)progressBlock forObserver:(NSObject*)observer;

/*
 * 设定观察者失败方法
 */
- (void)setDownloadFaildBlock:(HYFileDownloadManagerFaildBlock)faildBlock forObserver:(NSObject*)observer;

/*
 * 将观察者的block全部清除
 */
- (void)clearTaskBlockForObserver:(NSObject *)observer;

/**
 *  退出指定下载任务
 *
 *  @param taskUniqueIdentifier 下载任务标示
 */
- (void)cancelTask:(NSString *)taskUniqueIdentifier;

/**
 *  退出有相同标示的下载任务组
 *
 *  @param groupTaskUniqueIdentifier
 */
- (void)cancelGroupTask:(NSString *)groupTaskUniqueIdentifier;

@end
