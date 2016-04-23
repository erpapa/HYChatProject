//
//  HYUserInfo.h
//  HYChatProject
//
//  Created by erpapa on 16/4/20.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kUser @"user"
#define kPassword @"password"
#define kHostName @"hostName"
#define kHostPort @"hostPort"
#define kLogon @"logon"

@interface HYLoginInfo : NSObject
@property (nonatomic, strong) NSString *user;//用户名
@property (nonatomic, copy) NSString *password;//密码
@property (nonatomic, copy) NSString *hostName;//服务器ip
@property (nonatomic, assign) NSInteger hostPort;//端口
@property (nonatomic, assign) BOOL logon;// 未注销(在线)
/**
 *  单例
 */
+ (instancetype)sharedInstance;
/**
 *  从沙盒里获取用户数据
 */
- (void)loadUserInfoFromSanbox;

/**
 *  保存用户数据到沙盒
 */
- (void)saveUserInfoToSanbox;
@end
