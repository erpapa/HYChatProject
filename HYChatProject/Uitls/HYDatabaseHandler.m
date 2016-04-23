//
//  HYDatabaseHandler.m
//  HYChatProject
//
//  Created by erpapa on 16/4/23.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYDatabaseHandler.h"

@implementation HYDatabaseHandler

static HYDatabaseHandler *instance;

+ (id)allocWithZone:(struct _NSZone *)zone
{
    // dispatch_once是线程安全的，onceToken默认为0
    static dispatch_once_t onceToken;
    // dispatch_once宏可以保证块代码中的指令只被执行一次
    dispatch_once(&onceToken, ^{
        // 在多线程环境下，永远只会被执行一次，instance只会被实例化一次
        instance = [super allocWithZone:zone];
    });
    
    return instance;
}

/**
 *  单例
 */
+ (instancetype)sharedInstance
{
    if (instance == nil) {
        instance = [[self alloc] init];
    }
    return instance;
}

@end
