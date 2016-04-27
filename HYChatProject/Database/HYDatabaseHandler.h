//
//  HYDatabaseHandler.h
//  HYChatProject
//
//  Created by erpapa on 16/4/23.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"

@interface HYDatabaseHandler : NSObject
{
    FMDatabaseQueue *_dbQueue;
    NSLock *_userLocker;
    NSMutableArray *_usersCache;
}
/**
 *  单例
 */
+ (instancetype)sharedInstance;
- (void)refreshUsersCache;
- (NSArray *)usersCache;
@end

@interface FMDatabase(HY)

@end