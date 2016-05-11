//
//  HYXMPPRoomManager.h
//  HYChatProject
//
//  Created by erpapa on 16/5/2.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPP.h"

typedef void (^HYBookmarkedRoomsBlock)(NSArray *bookmarkedRooms); // 房间标签
typedef void (^HYSearchRoomsBlock)(NSArray *searchRooms); // 搜索房间数组
typedef void (^HYRoomInfoBlock)(NSDictionary *roomInfo); // 房间信息字典
typedef void (^HYRoomOwnersBlock)(NSArray *roomOwners); // 房间创建者
typedef void (^HYRoomAdminsBlock)(NSArray *roomAdmins); // 房间管理员
typedef void (^HYRoomMembersBlock)(NSArray *roomMembers); // 房间普通成员
typedef void (^HYJoinRoomBlock)(BOOL success);     // 加入房间成功/失败
typedef void (^HYCreateRoomBlock)(BOOL success);   // 创建room成功/失败


@class XMPPRoom;
@interface HYXMPPRoomManager : NSObject
@property (nonatomic, strong) XMPPStream *xmppStream; // 流
@property (nonatomic, strong) NSMutableArray *bookmarkedRooms; // 已加入的room
/**
 *  单例
 */
+ (instancetype)sharedInstance;

// 创建房间
- (void)createRoomWithRoomName:(NSString *)roomName success:(HYCreateRoomBlock)successBlock;
// 加入房间
- (void)joinRoomWithRoomJID:(XMPPJID *)roomJid withNickName:(NSString *)nickName success:(HYJoinRoomBlock)successBlock;
- (void)joinRoomWithRoomJID:(XMPPJID *)roomJid withNickName:(NSString *)nickName password:(NSString *)password success:(HYJoinRoomBlock)successBlock;
// 注册房间
- (void)registerRoomWithRoomJID:(XMPPJID *)roomJid;
// 离开房间
- (void)leaveRoomWithRoomJID:(XMPPJID *)roomJid;
// 销毁房间
- (void)destoryRoomWithRoomJID:(XMPPJID *)roomJid;
// 邀请好友加入房间
- (void)inviteUser:(XMPPJID *)userJid toRoom:(XMPPJID *)roomJid reason:(NSString *)reason;
// 配置房间信息
- (void)configXmppRoom:(XMPPJID *)roomJID;
// 提交注册表单
- (void)commitRegisterFormToRoom:(XMPPJID *)roomJid withNickname:(NSString *)nickname;
// 向房间申请发言权
- (void)applyVoiceFromRoom:(XMPPJID *)roomJid;
// 接受房间邀请
- (void)acceptInviteRoom:(XMPPJID *)roomJid;
// 拒绝房间邀请
- (void)rejectInviteRoom:(XMPPJID *)roomjid withReason:(NSString *)reason;

// 搜索聊天室列表
- (void)searchRooms:(NSString *)searchTerm result:(HYSearchRoomsBlock)searchRooms;
// 获取room信息
- (void)fetchRoom:(XMPPJID *)roomJid info:(HYRoomInfoBlock)roomInfo;
// 获取群成员
- (void)fetchRoom:(XMPPJID *)roomJid members:(HYRoomMembersBlock)members;
- (void)fetchRoom:(XMPPJID *)roomJid owners:(HYRoomOwnersBlock)owners;
- (void)fetchRoom:(XMPPJID *)roomJid admins:(HYRoomAdminsBlock)admins;
// 获取带标签room（默认自动加入所有带标签room）
- (void)fetchBookmarkedRooms:(HYBookmarkedRoomsBlock)bookmarkedRooms;

/**
 *  在聊天室内发送消息
 */
- (void)sendText:(NSString *)text toRoomJid:(XMPPJID *)roomJid;
/**
 *  通过jid获得room
 */
- (XMPPRoom *)roomFromJid:(XMPPJID *)roomJid;

/**
 *  判断owner
 */
- (BOOL)isRoomOwner:(XMPPJID *)userJid;
/**
 *  判断Admin
 */
- (BOOL)isRoomAdmin:(XMPPJID *)userJid;

/**
 *  context
 */
- (NSManagedObjectContext *)managedObjectContext_room;

@end
