//
//  HYDatabaseHandler.m
//  HYChatProject
//
//  Created by erpapa on 16/4/23.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYDatabaseHandler+HY.h"
#import "HYUtils.h"

static NSString* const kDatabaseName = @"chat.sqlite";
@implementation HYDatabaseHandler

static HYDatabaseHandler *instance;

/**
 *  单例
 */
+ (instancetype)sharedInstance
{
    // dispatch_once是线程安全的，onceToken默认为0
    static dispatch_once_t onceToken;
    // dispatch_once宏可以保证块代码中的指令只被执行一次
    dispatch_once(&onceToken, ^{
        // 在多线程环境下，永远只会被执行一次，instance只会被实例化一次
        instance = [[self alloc] init];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        // 1.sqlite路径
        NSString *databasePath = [HYUtils localPath:kDatabaseName];
        // 2.创建队列
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:databasePath];
        // 3.创表
        [_dbQueue inDatabase:^(FMDatabase *db) {
            [db createRecentChatTable]; // 创建最近联系人列表
            [db createRoomTable];
            [db createNewFriendTable];
            [db createSingleChatTable];
            [db createGroupChatTable];
        }];
    }
    return self;
}

@end

