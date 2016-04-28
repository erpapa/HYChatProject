//
//  HYXMPPManager.h
//  HYChatProject
//
//  Created by erpapa on 16/4/20.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPFramework.h"
typedef NS_ENUM(NSInteger, HYXMPPConnectStatus) {
    HYXMPPConnectStatusConnecting,//正在连接...
    HYXMPPConnectStatusTimeOut,//连接超时
    HYXMPPConnectStatusDidConnect,//连接成功
    HYXMPPConnectStatusDisConnect,//断开连接
    HYXMPPConnectStatusAuthSuccess,//授权成功
    HYXMPPConnectStatusAuthFailure,//授权失败
    HYXMPPConnectStatusRegisterSuccess,//注册成功
    HYXMPPConnectStatusRegisterFailure//注册失败
};
extern NSString *const HYConnectStatusDidChangeNotification;
typedef void (^HYXMPPConnectStatusBlock)(HYXMPPConnectStatus status);// XMPP登录请求结果的block
typedef void(^HYvCardBlock)(XMPPvCardTemp *vCardTemp);//返回名片信息
typedef void(^HYAvatarBlock)(NSData *avatar);//返回头像信息
typedef void(^HYSuccessBlock)(BOOL success);//操作成功/失败

@interface HYXMPPManager : NSObject
@property (nonatomic, strong,readonly)XMPPStream *xmppStream; // xmpp基础服务类
@property (nonatomic, assign,readonly)HYXMPPConnectStatus status; // 连接状态


/********************* 单例 ********************************/
+ (instancetype)sharedInstance;
/**
 *  用户登录
 */
- (void)xmppUserLogin:(HYXMPPConnectStatusBlock)resultBlock;
/**
 *  用户注册
 */
- (void)xmppUserRegister:(HYXMPPConnectStatusBlock)resultBlock;
/**
 *  用户注销
 */
- (void)xmppUserlogout;
/**
 *  更改密码
 */
- (void)xmppUserChangePassword:(NSString *)password;

/********************* 个人中心 ********************************/

/**
 *  获得我的名片
 */
- (void)getMyvCard:(HYvCardBlock)myvCardBlock;
/**
 *  更新我的名片
 */
- (void)updateMyvCard:(XMPPvCardTemp *)myvCard successBlock:(HYSuccessBlock)successBlock;
/**
 *  获得好友名片
 */
- (void)getvCardFromJID:(XMPPJID *)jid shouldRefresh:(BOOL)shouldRefresh vCardBlock:(HYvCardBlock)vCardBlock;
/**
 *  CoreData
 */
- (NSManagedObjectContext *)managedObjectContext_roster;
- (NSManagedObjectContext *)managedObjectContext_capabilities;
- (NSManagedObjectContext *)managedObjectContext_messageArchiving;
- (NSManagedObjectContext *)managedObjectContext_room;
@end
