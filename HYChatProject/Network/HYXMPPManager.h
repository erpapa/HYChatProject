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
typedef void(^HYUpdatevCardSuccess)(BOOL success);//更新自己的名片成功/失败
typedef void(^HYSendTextSuccess)(BOOL success);//发送消息成功/失败

@interface HYXMPPManager : NSObject
@property (nonatomic, strong,readonly)XMPPStream *xmppStream; // xmpp基础服务类
@property (nonatomic, assign,readonly)HYXMPPConnectStatus status; // 连接状态
@property (nonatomic, assign) BOOL isBackGround; // 后台
@property (nonatomic, strong) XMPPJID *myJID;
@property (nonatomic, strong) XMPPJID *chatJID;


/********************* 单例 ********************************/
+ (instancetype)sharedInstance;
/**
 *  用户登录
 */
- (void)xmppUserLogin:(HYXMPPConnectStatusBlock)resultBlock;
/**
 *  用户注册（先建立匿名连接）
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
- (void)updateMyvCard:(XMPPvCardTemp *)myvCard successBlock:(HYUpdatevCardSuccess)successBlock;
/**
 *  获得好友名片
 */
- (void)getvCardFromJID:(XMPPJID *)jid vCardBlock:(HYvCardBlock)vCardBlock;
/**
 *  获得头像
 */
- (void)getAvatarFromJID:(XMPPJID *)jid avatarBlock:(HYAvatarBlock)avatarBlock;

/********************* 添加、删除好友 ********************************/

/**
 *  添加好友 -1 自己 0 已经是好友 1 发送成功
 */
- (int)addUser:(XMPPJID *)userID;
/**
 *  删除好友
 */
- (void)removeUser:(XMPPJID *)jid;
/**
 *  同意好友申请
 */
- (void)agreeUserRequest:(XMPPJID *)jid;
/**
 *  拒绝好友申请
 */
- (void)rejectUserRequest:(XMPPJID *)jid;
/**
 *  设置用户昵称
 */
- (void)setNickname:(NSString *)nickname forUser:(XMPPJID *)jid;

/********************* 发送聊天消息 ********************************/
- (BOOL)sendText:(NSString *)text;
- (BOOL)sendText:(NSString *)text toJid:(XMPPJID *)jid;

/********************* CoreData ********************************/

- (NSManagedObjectContext *)managedObjectContext_roster;
- (NSManagedObjectContext *)managedObjectContext_capabilities;
- (NSManagedObjectContext *)managedObjectContext_messageArchiving;
@end
