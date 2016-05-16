//
//  HYUserInfo.m
//  HYChatProject
//
//  Created by erpapa on 16/4/20.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYLoginInfo.h"

#define kUser @"user"
#define kPassword @"password"
#define kHostName @"hostName"
#define kHostPort @"hostPort"
#define kLogon @"logon"
#define kDomain @"erpapa.cn" // 域名
#define kPort 5222          // 端口
#define kResource @"iPhone" //resource

@implementation HYLoginInfo

static HYLoginInfo *instance;

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
        [instance loadUserInfoFromSanbox];
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
    self.hostName = hostName.length ? hostName : kDomain;
    self.hostPort = hostPort ? hostPort : kPort;
}

- (XMPPJID *)jid
{
    return [XMPPJID jidWithUser:_user domain:_hostName resource:kResource];
}

- (void)saveNickNameDictToSanbox
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:_nickNameDict forKey:@"nickNameDict"];
    [defaults synchronize];
}

- (NSMutableDictionary *)nickNameDict
{
    if (_nickNameDict == nil) {
        _nickNameDict = [[[NSUserDefaults standardUserDefaults] objectForKey:@"nickNameDict"] mutableCopy];
        if (_nickNameDict == nil) {
            _nickNameDict = [NSMutableDictionary dictionary];
        }
    }
    return _nickNameDict;
}

@end
