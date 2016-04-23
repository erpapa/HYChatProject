//
//  HYUserInfo.m
//  HYChatProject
//
//  Created by erpapa on 16/4/20.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYUserInfo.h"

@implementation HYUserInfo

static HYUserInfo *instance;

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
+ (instancetype)sharedUserInfo
{
    if (instance == nil) {
        instance = [[self alloc] init];
        instance.user = @"";
        instance.password = @"";
        instance.hostName = domain;
        instance.hostPort = hostPort;
        instance.logon = NO;
        instance.registerMark = NO;
    }
    return instance;
}

/**
 *  保存用户数据
 */
- (void)saveUserInfoToSanbox{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:_user forKey:kUser];
    [defaults setObject:_password forKey:kPassword];
    [defaults setObject:_hostName forKey:kHostName];
    [defaults setInteger:_hostPort forKey:kHostPort];
    [defaults setBool:_logon forKey:kLogon];
    [defaults synchronize];
}

/**
 *  获取用户数据
 */
- (void)loadUserInfoFromSanbox{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.user = [defaults objectForKey:kUser];
    self.password = [defaults objectForKey:kPassword];
    self.logon = [defaults boolForKey:kLogon];
    NSString *hostName = [defaults objectForKey:kHostName];
    NSInteger hostPort = [defaults integerForKey:kHostPort];
    if (hostName.length) {
        self.hostName = hostName;
    }
    if (hostPort) {
        self.hostPort = hostPort;
    }
}

- (XMPPJID *)jid{
    return [XMPPJID jidWithUser:_user domain:domain resource:resource];
}
@end
