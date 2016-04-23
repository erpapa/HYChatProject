//
//  HYUserInfo.h
//  HYChatProject
//
//  Created by erpapa on 16/4/20.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPJID.h"

#define kUser @"user"
#define kPassword @"password"
#define kHostName @"hostName"
#define kHostPort @"hostPort"
#define kLogon @"logon"
/*
 JID一般由三部分构成：用户名，域名和资源名，格式为user@domain/resource，例如：admin@erpapa.cn/Anthony。对应于XMPPJID类中的三个属性user、domain、resource。
 
 如果没有设置主机名（HOST），则使用JID的域名（domain）作为主机名，而端口号是可选的，默认是5222，一般也没有必要改动它。
 */
static NSString *domain = @"erpapa.cn"; // 域名
static NSString *resource = @"iPhone"; //resource 标识用户登录的客户端 iphone android
static NSInteger hostPort = 5222;

@interface HYUserInfo : NSObject
@property (nonatomic, strong) NSString *user;//用户名
@property (nonatomic, copy) NSString *password;//密码
@property (nonatomic, copy) NSString *hostName;//服务器ip
@property (nonatomic, assign) NSInteger hostPort;//端口
@property (nonatomic, copy, readonly) XMPPJID *jid;//拼接得到jid
@property (nonatomic, assign) BOOL logon;// 未注销(在线)
@property (nonatomic, assign) BOOL registerMark;// 登录/注册
/**
 *  单例
 */
+ (instancetype)sharedUserInfo;
/**
 *  从沙盒里获取用户数据
 */
- (void)loadUserInfoFromSanbox;

/**
 *  保存用户数据到沙盒
 */
- (void)saveUserInfoToSanbox;
@end
