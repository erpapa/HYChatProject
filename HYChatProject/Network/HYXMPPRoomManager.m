//
//  HYXMPPRoomManager.m
//  HYChatProject
//
//  Created by erpapa on 16/5/2.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYXMPPRoomManager.h"
#import "XMPPMUC.h"
#import "XMPPRoomMemoryStorage.h"
#import "XMPPRoomCoreDataStorage.h"
#import "HYXMPPManager.h"
#import "HYChatMessage.h"
#import "XMPP+IM.h"
#import "HYUtils.h"
#import "HYLoginInfo.h"
#import "HYRecentChatModel.h"
#import "HYDatabaseHandler+HY.h"

@interface HYXMPPRoomManager()<XMPPStreamDelegate, XMPPRoomDelegate, XMPPMUCDelegate>

@property (nonatomic, copy) NSString *filterString; // 搜索
@property (nonatomic, copy) HYJoinRoomBlock joinRoomBlock; // 加入房间成功/失败
@property (nonatomic, copy) HYCreateRoomBlock createRoomBlock;//创建房间成功/失败
@property (nonatomic, strong) XMPPJID *registerRoomJID; // 注册房间jid
@property (nonatomic, strong) XMPPMUC *xmppMUC;
@property (nonatomic, strong) XMPPRoomCoreDataStorage *xmppRoomStorage; // 房间CoreData;
@property (nonatomic, strong) NSMutableArray *roomOwners;
@property (nonatomic, strong) NSMutableArray *roomAdmins;
@property (nonatomic, strong) NSMutableArray *roomMembers;
@property (nonatomic, copy) HYBookmarkedRoomsBlock bookmarkedRoomsBlock;
@property (nonatomic, copy) HYSearchRoomsBlock searchRoomsBlock;
@property (nonatomic, copy) HYRoomInfoBlock roomInfo;
@property (nonatomic, copy) HYRoomOwnersBlock roomOwnersBlock;
@property (nonatomic, copy) HYRoomAdminsBlock roomAdminsBlock;
@property (nonatomic, copy) HYRoomMembersBlock roomMembersBlock;

@end

@implementation HYXMPPRoomManager

/**
 *  单例
 */
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    // dispatch_once宏可以保证块代码中的指令只被执行一次
    static HYXMPPRoomManager *instance;
    dispatch_once(&onceToken, ^{
        instance = [[super alloc] init];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _bookmarkedRooms = [NSMutableArray array];
        _xmppStream = [HYXMPPManager sharedInstance].xmppStream;
        [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        _xmppMUC = [[XMPPMUC alloc] initWithDispatchQueue:dispatch_get_main_queue()];
        [_xmppMUC activate:_xmppStream];
        [_xmppMUC addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        // 设置房间
        _xmppRoomStorage = [[XMPPRoomCoreDataStorage alloc] init];
        _xmppRoomStorage.autoRecreateDatabaseFile = NO;
        _xmppRoomStorage.autoRemovePreviousDatabaseFile = NO;
    }
    return self;
}

- (void)dealloc
{
    [_xmppStream removeDelegate:self];
    [self removeAllRooms];
    _xmppRoomStorage = nil;
}

/**
 *  通过jid得到room
 */
- (XMPPRoom *)roomFromJid:(XMPPJID *)roomJid
{
    for (NSInteger index = 0; index < self.bookmarkedRooms.count; index++) {
        XMPPRoom *room = [self.bookmarkedRooms objectAtIndex:index];
        if ([room.roomJID.bare isEqualToString:roomJid.bare]) {
            return room;
        }
    }
    return nil;
}

- (void)removeAllRooms
{
    NSInteger count = self.bookmarkedRooms.count;
    for (NSInteger index = count - 1; index >= 0; index--) {
        XMPPRoom *room = [self.bookmarkedRooms objectAtIndex:index];
        [room removeDelegate:self];
        [room leaveRoom];
        [room deactivate];
        [self.bookmarkedRooms removeObject:room];
        room = nil;
    }
}

#pragma mark - 创建房间
- (void)createRoomWithRoomName:(NSString *)roomName success:(HYCreateRoomBlock)successBlock;
{
    HYLog(@"创建群组:%@...", roomName);
    self.createRoomBlock = successBlock;
    NSString *xmppRoomJID = [NSString stringWithFormat:@"%@@conference.%@", roomName, _xmppStream.myJID.domain];
    XMPPJID *roomJID = [XMPPJID jidWithString:xmppRoomJID];
    XMPPRoom *xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:_xmppRoomStorage jid:roomJID dispatchQueue:dispatch_get_main_queue()];
    [xmppRoom activate:_xmppStream];
    [xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [xmppRoom joinRoomUsingNickname:[_xmppStream.myJID user] history:nil];
    [xmppRoom fetchConfigurationForm];
    // 为新房间创建标签
    [self addBookmarkForRoom:roomJID];
    [self.bookmarkedRooms addObject:xmppRoom];
}

#pragma mark - 加入房间
- (void)joinRoomWithRoomJID:(XMPPJID *)roomJid withNickName:(NSString *)nickName success:(HYJoinRoomBlock)successBlock
{
    [self joinRoomWithRoomJID:roomJid withNickName:nickName password:nil success:successBlock];
}

- (void)joinRoomWithRoomJID:(XMPPJID *)roomJid withNickName:(NSString *)nickName password:(NSString *)password success:(HYJoinRoomBlock)successBlock
{
    HYLog(@"加入群组:%@...", roomJid.bare);
    
    for (NSInteger index = 0; index < self.bookmarkedRooms.count; index++) {
        XMPPRoom *room = [self.bookmarkedRooms objectAtIndex:index];
        if ([room.roomJID.bare isEqualToString:roomJid.bare]) {
            successBlock(YES);
            return ;
        }
    }
    
    self.joinRoomBlock = successBlock;
    XMPPRoom *xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:_xmppRoomStorage jid:roomJid dispatchQueue:dispatch_get_main_queue()];
    [xmppRoom activate:_xmppStream];
    [xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSXMLElement *history = [NSXMLElement elementWithName:@"history"];
    [history addAttributeWithName:@"maxstanzas" stringValue:@"20"]; // 设置历史消息记录条数
    // [history addAttributeWithName:@"seconds" stringValue:@"10"]; // 设置最后10s消息
    [xmppRoom joinRoomUsingNickname:nickName history:history password:password]; // 密码设置为空
    //    [_xmppRoom configureRoomUsingOptions:nil]; // 默认设置
    [xmppRoom fetchConfigurationForm];
    // 为加入的房间创建标签
    [self addBookmarkForRoom:roomJid];
    [self.bookmarkedRooms addObject:xmppRoom];
}

#pragma mark - 请求注册到房间
- (void)registerRoomWithRoomJID:(XMPPJID *)roomJid
{
    // <iq type="get" from="mybareJID" to="roomJid" id="reg1">
    //   <query xmlns="jabber:iq:register"/>
    // </iq>
    HYLog(@"请求注册到群组:%@...", roomJid.bare);
    self.registerRoomJID = roomJid;
    NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:register"];
    
    NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
    [iq addAttributeWithName:@"type" stringValue:@"get"];
    [iq addAttributeWithName:@"from" stringValue:_xmppStream.myJID.full];
    [iq addAttributeWithName:@"to" stringValue:roomJid.bare];
    [iq addAttributeWithName:@"id" stringValue:[NSString stringWithFormat:@"RRTR%@", roomJid.bare]];
    [iq addChild:query];
    
    [_xmppStream sendElement:iq];
}

#pragma mark - 退出群组
- (void)leaveRoomWithRoomJID:(XMPPJID *)roomJid
{
    HYLog(@"退出群组:%@...", roomJid.bare);
    
    XMPPRoom *room = [self roomFromJid:roomJid];
    if (room == nil) return;
    [room removeDelegate:self];
    [room leaveRoom];
    [room deactivate];
    [self removeBookmarkForRoom:roomJid];
    [self.bookmarkedRooms removeObject:room];
    room = nil;
    
}
#pragma mark - 销毁房间
- (void)destoryRoomWithRoomJID:(XMPPJID *)roomJid
{
    HYLog(@"销毁房间%@...", roomJid);

    XMPPRoom *room = [self roomFromJid:roomJid];
    if (room == nil) return;
    [room removeDelegate:self];
    [room destroyRoom];
    [room deactivate];
    [self removeBookmarkForRoom:roomJid];
    [self.bookmarkedRooms removeObject:room];
    room = nil;
}

#pragma mark - 邀请好友加入房间
- (void)inviteUser:(XMPPJID *)userJid toRoom:(XMPPJID *)roomJid reason:(NSString *)reason
{
    XMPPRoom *room = [self roomFromJid:roomJid];
    if (room == nil) return;
    [room inviteUser:userJid withMessage:reason];
}


#pragma mark 对新创建的群组进行配置
- (void)configXmppRoom:(XMPPJID *)roomJid
{
    NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
    NSXMLElement *p;
    
    p = [NSXMLElement elementWithName:@"field"];
    [p addAttributeWithName:@"var" stringValue:@"muc#roomconfig_persistentroom"];   // 永久房间
    [p addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
    [x addChild:p];
    
    //    p = [NSXMLElement elementWithName:@"field"];
    //    [p addAttributeWithName:@"var" stringValue:@"muc#roomconfig_memberonly"];       // 仅对成员开放
    //    [p addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
    //    [x addChild:p];
    
    p = [NSXMLElement elementWithName:@"field"];
    [p addAttributeWithName:@"var" stringValue:@"muc#roomconfig_maxusers"];         // 群组最大用户
    [p addChild:[NSXMLElement elementWithName:@"value" stringValue:@"500"]];
    [x addChild:p];
    
    p = [NSXMLElement elementWithName:@"field"];
    [p addAttributeWithName:@"var" stringValue:@"muc#roomconfig_changesubject"];    // 允许改变主题
    [p addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
    [x addChild:p];
    
    p = [NSXMLElement elementWithName:@"field"];
    [p addAttributeWithName:@"var" stringValue:@"muc#roomconfig_publicroom"];       // 公共房间
    [p addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
    [x addChild:p];
    
    p = [NSXMLElement elementWithName:@"field"];
    [p addAttributeWithName:@"var" stringValue:@"muc#roomconfig_allowinvites"];     // 允许邀请
    [p addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
    [x addChild:p];
    
    p = [NSXMLElement elementWithName:@"field"];
    [p addAttributeWithName:@"var" stringValue:@"muc#roomconfig_enablelogging"];     // 允许登录房间对话
    [p addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
    [x addChild:p];
    
    p = [NSXMLElement elementWithName:@"field"];
    [p addAttributeWithName:@"var" stringValue:@"muc#roomconfig_getmemberlist"];     // 允许获取成员列表
    [p addChild:[NSXMLElement elementWithName:@"value" stringValue:@"moderator"]];
    [p addChild:[NSXMLElement elementWithName:@"value" stringValue:@"participant"]];
    [p addChild:[NSXMLElement elementWithName:@"value" xmlns:@"visitor"]];
    [x addChild:p];
    
    XMPPRoom *room = [self roomFromJid:roomJid];
    [room configureRoomUsingOptions:x];
}

#pragma mark - 提交注册表单
- (void)commitRegisterFormToRoom:(NSString *)roomJid withNickname:(NSString *)nickname
{
    NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
    [x addAttributeWithName:@"type" stringValue:@"submit"];
    
    NSXMLElement *field;
    
    field = [NSXMLElement elementWithName:@"field"];
    [field addAttributeWithName:@"var" stringValue:@"FORM_TYPE"];
    [field addChild:[NSXMLElement elementWithName:@"value" stringValue:@"http://jabber.org/protocol/muc#register"]];
    [x addChild:field];
    
    field = [NSXMLElement elementWithName:@"field"];
    [field addAttributeWithName:@"var" stringValue:@"muc#register_first"];                      // 注册房间first name
    [field addChild:[NSXMLElement elementWithName:@"value" stringValue:nickname]];
    [x addChild:field];
    
    field = [NSXMLElement elementWithName:@"field"];
    [field addAttributeWithName:@"var" stringValue:@"muc#register_last"];                       // 注册房间last name
    [field addChild:[NSXMLElement elementWithName:@"value" stringValue:nickname]];
    [x addChild:field];
    
    field = [NSXMLElement elementWithName:@"field"];
    [field addAttributeWithName:@"var" stringValue:@"muc#register_roomnick"];                   // 注册房间昵称
    [field addChild:[NSXMLElement elementWithName:@"value" stringValue:nickname]];
    [x addChild:field];
    
    field = [NSXMLElement elementWithName:@"field"];
    [field addAttributeWithName:@"var" stringValue:@"muc#register_url"];                        // 注册房间URL
    [field addChild:[NSXMLElement elementWithName:@"value" stringValue:[NSString stringWithFormat:@"http://%@/", nickname]]];
    [x addChild:field];
    
    field = [NSXMLElement elementWithName:@"field"];
    [field addAttributeWithName:@"var" stringValue:@"muc#register_email"];                      // 注册房间邮箱
    [field addChild:[NSXMLElement elementWithName:@"value" stringValue:nickname]];
    [x addChild:field];
    
    field = [NSXMLElement elementWithName:@"field"];
    [field addAttributeWithName:@"var" stringValue:@"muc#register_faqentry"];                   // 注册房间常用问题
    [field addChild:[NSXMLElement elementWithName:@"value" stringValue:nickname]];
    [x addChild:field];
    
    NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:register"];
    [query addChild:x];
    
    NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
    [iq addAttributeWithName:@"type" stringValue:@"set"];
    [iq addAttributeWithName:@"from" stringValue:_xmppStream.myJID.full];
    [iq addAttributeWithName:@"to" stringValue:roomJid];
    [iq addAttributeWithName:@"id" stringValue:[NSString stringWithFormat:@"CRFTR%@", roomJid]];
    [iq addChild:query];
    
    [_xmppStream sendElement:iq];
}


#pragma mark - 向房间申请发言权
- (void)applyVoiceFromRoom:(NSString *)roomJid
{
    NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
    [x addAttributeWithName:@"type" stringValue:@"submit"];
    
    NSXMLElement *field;
    
    field = [NSXMLElement elementWithName:@"field"];
    [field addAttributeWithName:@"var" stringValue:@"FORM_TYPE"];
    [field addChild:[NSXMLElement elementWithName:@"value" stringValue:@"http://jabber.org/protocol/muc#request"]];
    [x addChild:field];
    
    field = [NSXMLElement elementWithName:@"field"];
    [field addAttributeWithName:@"var" stringValue:@"muc#role"];
    [field addChild:[NSXMLElement elementWithName:@"value" stringValue:@"participant"]];
    [x addChild:field];
    
    XMPPMessage *message = [XMPPMessage message];
    [message addAttributeWithName:@"to" stringValue:roomJid];
    [message addAttributeWithName:@"from" stringValue:_xmppStream.myJID.full];
    [message addChild:x];
    
    [_xmppStream sendElement:message];
}


#pragma mark - 接受房间邀请
- (void)acceptInviteRoom:(XMPPJID *)roomJid
{
    
    NSXMLElement *invite = [NSXMLElement elementWithName:@"invite"];
    [invite addAttributeWithName:@"to" stringValue:[roomJid bare]];
    
    NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:XMPPMUCUserNamespace];
    [x addChild:invite];
    
    XMPPMessage *message = [XMPPMessage message];
    [message addAttributeWithName:@"to" stringValue:[roomJid bare]];
    [message addChild:x];
    
    [_xmppStream sendElement:message];
}


#pragma mark - 拒绝房间邀请
- (void)rejectInviteRoom:(XMPPJID *)jid withReason:(NSString *)reasonStr
{
    // <message to='darkcave@chat.shakespeare.lit'>
    //   <x xmlns='http://jabber.org/protocol/muc#user'>
    //     <decline to='hecate@shakespeare.lit'>
    //       <reason>
    //         Sorry, I'm too busy right now.
    //       </reason>
    //     </decline>
    //   </x>
    // </message>
    
    NSXMLElement *reason = [NSXMLElement elementWithName:@"reason"];
    [reason setStringValue:reasonStr];
    
    NSXMLElement *decline = [NSXMLElement elementWithName:@"decline"];
    [decline addAttributeWithName:@"to" stringValue:[jid bare]];
    [decline addChild:reason];
    
    NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:XMPPMUCUserNamespace];
    [x addChild:decline];
    
    XMPPMessage *message = [XMPPMessage message];
    [message addAttributeWithName:@"to" stringValue:[jid bare]];
    [message addChild:x];
    
    [_xmppStream sendElement:message];
}

// 发送消息
- (BOOL)sendText:(NSString *)text toRoomJid:(XMPPJID *)roomJid
{
    HYRecentChatModel *chatModel = [[HYRecentChatModel alloc] init];
    [[HYDatabaseHandler sharedInstance] recentChatModel:chatModel fromJid:roomJid];// 从数据库读取
    chatModel.jid = roomJid;
    chatModel.body = text;
    chatModel.time = [[NSDate date] timeIntervalSince1970];
    chatModel.isGroup = YES;
    chatModel.unreadCount = 0;
    MAIN(^{
        [HYNotification postNotificationName:HYChatDidReceiveMessage object:chatModel];
    });
    
    
    XMPPMessage *message = [XMPPMessage messageWithType:@"groupchat" to:roomJid];
    [message addBody:text];
    XMPPElementReceipt *receipt = [XMPPElementReceipt new];
    [_xmppStream sendElement:message andGetReceipt:&receipt];
    BOOL messageState =[receipt wait:-1];
    return messageState;
}

#pragma mark - 搜索群组
- (void)searchRooms:(NSString *)searchTerm result:(HYSearchRoomsBlock)searchRooms
{
    HYLog(@"搜索群组...");
    self.searchRoomsBlock = searchRooms;
    self.filterString = [NSString stringWithFormat:@"%@", searchTerm];
    
    XMPPJID *serverJID = [XMPPJID jidWithString:[NSString stringWithFormat:@"conference.%@", _xmppStream.myJID.domain]];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:serverJID];
    [iq addAttributeWithName:@"from" stringValue:_xmppStream.myJID.full];
    NSXMLElement *query = [NSXMLElement elementWithName:@"query"];
    [query addAttributeWithName:@"xmlns" stringValue:@"http://jabber.org/protocol/disco#items"];
    [iq addChild:query];
    [_xmppStream sendElement:iq];
}

#pragma mark - 获取指定群组详细信息
/*
 <feature var="http://jabber.org/protocol/disco#info"/>
 <x xmlns="jabber:x:data" type="result">
 <field var="FORM_TYPE" type="hidden">
 <value>http://jabber.org/protocol/muc#roominfo</value>
 </field>
 <field var="muc#roominfo_description" label="描述">
 <value>测试2</value>
 </field>
 <field var="muc#roominfo_subject" label="主题">
 <value></value>
 </field>
 <field var="muc#roominfo_occupants" label="占有者人数">
 <value>1</value>
 </field>
 <field var="x-muc#roominfo_creationdate" label="创建日期">
 <value>20131202T02:22:08</value>
 </field>
 </x>
 */

- (void)fetchRoom:(XMPPJID *)roomJid info:(HYRoomInfoBlock)roomInfo;
{
    HYLog(@"获取群组:%@信息...", roomJid);
    self.roomInfo = roomInfo;
    XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:roomJid];
    [iq addAttributeWithName:@"from" stringValue:_xmppStream.myJID.full];
    NSXMLElement *query = [NSXMLElement elementWithName:@"query"];
    [query addAttributeWithName:@"xmlns" stringValue:@"http://jabber.org/protocol/disco#info"];
    [iq addChild:query];
    [_xmppStream sendElement:iq];
}

#pragma mark - 获取带标签room
- (void)fetchBookmarkedRooms:(HYBookmarkedRoomsBlock)bookmarkedRooms
{
    self.bookmarkedRoomsBlock = bookmarkedRooms;
    NSXMLElement *storage = [NSXMLElement elementWithName:@"storage" xmlns:@"storage:bookmarks"];
    [self getPrivateStorateForElement:storage];
}


#pragma mark - 获取群成员
- (void)fetchRoom:(XMPPJID *)roomJid members:(HYRoomMembersBlock)members
{
    self.roomMembersBlock = members;
    XMPPRoom *room = [self roomFromJid:roomJid];
    [room fetchMembersList];       // 获取成员列表
}

- (void)fetchRoom:(XMPPJID *)roomJid owners:(HYRoomOwnersBlock)owners
{
    self.roomOwnersBlock = owners;
    [self fetchOwnersList:roomJid];     // 获取创建者列表
}
- (void)fetchRoom:(XMPPJID *)roomJid admins:(HYRoomAdminsBlock)admins
{
    self.roomAdminsBlock = admins;
    [self fetchAdminsList:roomJid];   // 获取管理员列表
}

#pragma mark 获取拥有者列表
- (void)fetchOwnersList:(XMPPJID *)roomJID
{
    // <iq type='get'
    //       id='member3'
    //       to='coven@chat.shakespeare.lit'>
    //   <query xmlns='http://jabber.org/protocol/muc#admin'>
    //     <item affiliation='owner'/>
    //   </query>
    // </iq>
    
    NSString *fetchID = [_xmppStream generateUUID];
    
    NSXMLElement *item = [NSXMLElement elementWithName:@"item"];
    [item addAttributeWithName:@"affiliation" stringValue:@"owner"];
    
    NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:XMPPMUCOwnerNamespace];
    [query addChild:item];
    
    XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:roomJID elementID:fetchID child:query];
    
    [_xmppStream sendElement:iq];
}

#pragma mark 获取管理员列表
- (void)fetchAdminsList:(XMPPJID *)roomJID
{
    
    // <iq type='get'
    //       id='member3'
    //       to='coven@chat.shakespeare.lit'>
    //   <query xmlns='http://jabber.org/protocol/muc#admin'>
    //     <item affiliation='admin'/>
    //   </query>
    // </iq>
    
    NSString *fetchID = [_xmppStream generateUUID];
    
    NSXMLElement *item = [NSXMLElement elementWithName:@"item"];
    [item addAttributeWithName:@"affiliation" stringValue:@"admin"];
    
    NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:XMPPMUCAdminNamespace];
    [query addChild:item];
    
    XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:roomJID elementID:fetchID child:query];
    
    [_xmppStream sendElement:iq];
}

#pragma mark 获取当前用户所有标签的房间
- (void)getBookmarkRooms
{
    NSXMLElement *storage = [NSXMLElement elementWithName:@"storage" xmlns:@"storage:bookmarks"];
    
    [self getPrivateStorateForElement:storage];
}

#pragma mark 为房间创建标签，用于只获取自身创建或加入的房间
- (void)addBookmarkForRoom:(XMPPJID *)roomJid
{
    HYLog(@"为房间%@创建标签...", roomJid);
    NSXMLElement *storage = [NSXMLElement elementWithName:@"storage"];
    [storage addAttributeWithName:@"xmlns" stringValue:@"storage:bookmarks"];
    
    NSXMLElement *conference;
    for (int i = 0; i < self.bookmarkedRooms.count; i++) {
        XMPPRoom *joinedRoom = [self.bookmarkedRooms objectAtIndex:i];
        if ([roomJid.bare isEqualToString:joinedRoom.roomJID.bare]) { // 如果已存在
            return;
        }
        conference = [NSXMLElement elementWithName:@"conference"];
        [conference addAttributeWithName:@"name" stringValue:joinedRoom.roomJID.user];
        [conference addAttributeWithName:@"jid" stringValue:joinedRoom.roomJID.bare];
        [conference addAttributeWithName:@"autojoin" stringValue:@"true"];
        [storage addChild:conference];
    }
    conference = [NSXMLElement elementWithName:@"conference"];
    [conference addAttributeWithName:@"name" stringValue:roomJid.user];
    [conference addAttributeWithName:@"jid" stringValue:roomJid.bare];
    [conference addAttributeWithName:@"autojoin" stringValue:@"true"];
    [storage addChild:conference];
    [self savePrivateStorageWithElement:storage];
}


#pragma mark 为房间删除标签，用于只获取自身创建或加入的房间
- (void)removeBookmarkForRoom:(XMPPJID *)roomJid
{
    HYLog(@"为房间%@删除标签...", roomJid);
    NSXMLElement *storage = [NSXMLElement elementWithName:@"storage"];
    [storage addAttributeWithName:@"xmlns" stringValue:@"storage:bookmarks"];
    
    NSXMLElement *conference;
    for (int i = 0; i < self.bookmarkedRooms.count; i++) {
        XMPPRoom *joinedRoom = [self.bookmarkedRooms objectAtIndex:i];
        if (![roomJid.bare isEqualToString:joinedRoom.roomJID.bare]) { // 不添加准备删除的节点
            conference = [NSXMLElement elementWithName:@"conference"];
            [conference addAttributeWithName:@"name" stringValue:joinedRoom.roomJID.user];
            [conference addAttributeWithName:@"jid" stringValue:joinedRoom.roomJID.bare];
            [conference addAttributeWithName:@"autojoin" stringValue:@"true"];
            [storage addChild:conference];
        }
    }
    [self savePrivateStorageWithElement:storage];
}

- (void)savePrivateStorageWithElement:(NSXMLElement *)element
{
    NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:private"];
    [query addChild:element];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"set" to:nil elementID:[_xmppStream generateUUID] child:query];
    
    [_xmppStream sendElement:iq];
}


- (void)getPrivateStorateForElement:(NSXMLElement *)element
{
    NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:private"];
    [query addChild:element];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:nil elementID:[_xmppStream generateUUID] child:query];
    
    [_xmppStream sendElement:iq];
}

#pragma mark - 判断是否是owner

- (BOOL)isRoomOwner:(XMPPJID *)userJid;
{
    for (NSString *owner in self.roomAdmins) {
        if ([owner isEqualToString:userJid.bare]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isRoomAdmin:(XMPPJID *)userJid
{
    for (NSString *admin in self.roomAdmins) {
        if ([admin isEqualToString:userJid.bare]) {
            return YES;
        }
    }
    return NO;
}


- (NSManagedObjectContext *)managedObjectContext_room
{
    return [_xmppRoomStorage mainThreadManagedObjectContext];
}

//////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStreamDelegate
//////////////////////////////////////////////////////////////////////////////////////

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    HYLog(@"HYXMPPRoomManager 接收到IQ包%@", iq);
    if ([iq isQueryError]) {
        HYLog(@"查询返回错误消息");
        if (self.roomInfo) {
            self.roomInfo(nil);
            self.roomInfo = nil;
        }
        if (self.joinRoomBlock) {
            self.joinRoomBlock(NO);
            self.joinRoomBlock = nil;
        }
        if (self.createRoomBlock) {
            self.createRoomBlock(NO);
            self.createRoomBlock = nil;
        }
    } else if ([iq isChatRoomItems]) {
        if (self.searchRoomsBlock) {
            NSXMLElement *element = iq.childElement;
            NSMutableArray *searchRooms = [[NSMutableArray alloc] init];
            for (NSXMLElement *item in element.children) {
                NSMutableDictionary *roomDic = [[NSMutableDictionary alloc] init];
                NSString *roomJid = item.attributesAsDictionary[@"jid"];
                NSString *roomName = item.attributesAsDictionary[@"name"];
                if ([roomName rangeOfString:self.filterString].location != NSNotFound) {
                    [roomDic addEntriesFromDictionary:@{@"roomJid":roomJid, @"name":roomName}];
                    [searchRooms addObject:roomDic];
                }
            }
            HYLog(@"搜索到的所有群组 = %@", searchRooms);
            if (self.searchRoomsBlock) {
                self.searchRoomsBlock(searchRooms);
                self.searchRoomsBlock = nil;
            }
        }
    } else if ([iq isChatRoomInfo]) {
        NSMutableDictionary *roomInfo = [[NSMutableDictionary alloc] init];
        for (NSXMLElement *element in iq.childElement.children) {
            if ([element.name isEqualToString:@"x"]) {
                for (NSXMLElement *field in element.children) {
                    if (field.childCount > 0) {
                        for (NSXMLElement *value in field.children) {
                            [roomInfo addEntriesFromDictionary:@{field.attributesAsDictionary[@"var"] : [value stringValue]}];
                        }
                    } else {
                        [roomInfo addEntriesFromDictionary:@{field.attributesAsDictionary[@"var"] : @""}];
                    }
                    
                }
            }
        }
        HYLog(@"room info = %@", roomInfo);
        if (self.roomInfo) {
            self.roomInfo(roomInfo);
            self.roomInfo = nil;
        }
        
    } else if ([iq isFetchMembersList]) {       // 获取群组成员列表
        if ([iq.attributesAsDictionary[@"type"] isEqualToString:@"result"]) {
            NSXMLElement *element = iq.childElement;
            self.roomOwners = [NSMutableArray array];
            self.roomAdmins = [NSMutableArray array];
            self.roomMembers = [NSMutableArray array];
            
            for (NSXMLElement *item in element.children) {
                NSString *userJidStr = item.attributesAsDictionary[@"jid"];
                XMPPJID *userJid = [XMPPJID jidWithString:userJidStr];
                NSString *userAffiliation = item.attributesAsDictionary[@"affiliation"];
                if ([userAffiliation isEqualToString:@"owner"]) {
                    [self.roomOwners addObject:userJid.bare];
                } else if ([userAffiliation isEqualToString:@"admin"]) {
                    [self.roomAdmins addObject:userJid.bare];
                } else if ([userAffiliation isEqualToString:@"member"]) {
                    [self.roomMembers addObject:userJid.bare];
                }
            }
            HYLog(@"群组成员列表: owner : %@, admins = %@, members = %@", self.roomOwners, self.roomAdmins, self.roomMembers);
            if (self.roomOwnersBlock) {
                self.roomOwnersBlock(self.roomOwners);
                self.roomOwnersBlock = nil;
            }
            if (self.roomAdminsBlock) {
                self.roomAdminsBlock(self.roomAdmins);
                self.roomAdminsBlock = nil;
            }
            if (self.roomMembersBlock) {
                self.roomMembersBlock(self.roomMembers);
                self.roomMembersBlock = nil;
            }
            
        }
    } else if([iq isRoomBookmarks]) {
        NSXMLElement *element = iq.childElement;
        [self removeAllRooms]; // 移除所有room
        for (NSXMLElement *storage in element.children) {
            for (NSXMLElement *conference in storage.children) {
                NSString *roomJidStr = conference.attributesAsDictionary[@"jid"];
                XMPPJID *roomJid = [XMPPJID jidWithString:roomJidStr];
                XMPPRoom *room = [[XMPPRoom alloc] initWithRoomStorage:_xmppRoomStorage jid:roomJid dispatchQueue:dispatch_get_main_queue()];
                [room activate:_xmppStream];
                [room addDelegate:self delegateQueue:dispatch_get_main_queue()];
                NSXMLElement *history = [NSXMLElement elementWithName:@"history"];
                [history addAttributeWithName:@"maxstanzas" stringValue:@"0"]; // 设置历史消息条数
                [room joinRoomUsingNickname:_xmppStream.myJID.user history:history]; // 密码设置为空
                [room fetchConfigurationForm];
                [self.bookmarkedRooms addObject:room];
            }
        }
        HYLog(@"已添加标签群组:%@", self.bookmarkedRooms);
        if (self.bookmarkedRoomsBlock) {
            self.bookmarkedRoomsBlock(self.bookmarkedRooms);
            self.bookmarkedRoomsBlock = nil;
        }
    } else if ([iq isRoomRegisterQuery:self.registerRoomJID.bare]) {
        HYLog(@"接收到注册请求清单...");
        if (![[iq type] isEqualToString:@"error"]) {
            XMPPJID *roomJid = [iq from];
            [self commitRegisterFormToRoom:roomJid withNickname:_xmppStream.myJID.bare];
        }
    } else if ([iq isRoomRegisterCommitResult:self.registerRoomJID.bare]) {
        HYLog(@"接收到房间注册提交结果.");
        if (![[iq type] isEqualToString:@"error"]) {
            [self joinRoomWithRoomJID:self.registerRoomJID withNickName:_xmppStream.myJID.bare success:nil];
        }
    }
    return YES;
}


- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    if ([presence isApplyToJoinRoom]) {
        NSString *roomJid = [self getJid:presence.attributesAsDictionary[@"from"]];
        NSString *userJid = nil;
        for (NSXMLElement *element in presence.children) {
            if ([element.name isEqualToString:@"x"] && [element.xmlns isEqualToString:@"http://jabber.org/protocol/muc#user"]) {
                for (NSXMLElement *item in element.children) {
                    userJid = [self getJid:item.attributesAsDictionary[@"jid"]];
                }
            }
        }
        HYLog(@"用户：%@，请求加入群组：%@\nTODO: 管理员为该用户分配岗位...", userJid, roomJid);
    }
}

- (NSString *)getJid:(NSString *)userJIDFull
{
    NSString *name = [NSString stringWithFormat:@"%@", [[userJIDFull componentsSeparatedByString:@"/"] firstObject]];
    return name;
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - XMPPRoomDelegate
///////////////////////////////////////////////////////////////////////////////////////////

#pragma mark 创建聊天室成功
- (void)xmppRoomDidCreate:(XMPPRoom *)sender
{
    HYLog(@"聊天室已创建,roomJID = %@", sender.roomJID.bare);
    if (self.createRoomBlock) {
        self.createRoomBlock(YES);
    }
}

/**
 * Invoked with the results of a request to fetch the configuration form.
 * The given config form will look something like:
 *
 * <x xmlns='jabber:x:data' type='form'>
 *   <title>Configuration for MUC Room</title>
 *   <field type='hidden'
 *           var='FORM_TYPE'>
 *     <value>http://jabber.org/protocol/muc#roomconfig</value>
 *   </field>
 *   <field label='Natural-Language Room Name'
 *           type='text-single'
 *            var='muc#roomconfig_roomname'/>
 *   <field label='Enable Public Logging?'
 *           type='boolean'
 *            var='muc#roomconfig_enablelogging'>
 *     <value>0</value>
 *   </field>
 *   ...
 * </x>
 *
 * The form is to be filled out and then submitted via the configureRoomUsingOptions: method.
 *
 * @see fetchConfigurationForm:
 * @see configureRoomUsingOptions:
 **/
- (void)xmppRoom:(XMPPRoom *)sender didFetchConfigurationForm:(NSXMLElement *)configForm
{
    HYLog(@"xmppRoom获取到配置格式，%@", configForm);
    
    NSXMLElement *newConfig = [configForm copy];
    NSArray *fields = [newConfig elementsForName:@"field"];
    
    for (NSXMLElement *field in fields) {
        NSString *var = [field attributeStringValueForName:@"var"];
        if ([var isEqualToString:@"muc#roomconfig_persistentroom"]) {
            [field removeChildAtIndex:0];
            [field addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
        }
    }
    [sender configureRoomUsingOptions:newConfig];
}

- (void)xmppRoom:(XMPPRoom *)sender willSendConfiguration:(XMPPIQ *)roomConfigForm
{
    HYLog(@"xmppRoom将要发送配置信息");
}

- (void)xmppRoom:(XMPPRoom *)sender didConfigure:(XMPPIQ *)iqResult
{
    HYLog(@"xmppRoom配置完成. %@", iqResult);
}

- (void)xmppRoom:(XMPPRoom *)sender didNotConfigure:(XMPPIQ *)iqResult
{
    HYLog(@"xmppRoom配置失败, %@", iqResult);
}

- (void)xmppRoomDidJoin:(XMPPRoom *)sender
{
    HYLog(@"%@已经加入群组", sender.myRoomJID.resource);
    if (self.createRoomBlock) {
        HYLog(@"对新创建的群组进行配置...");
        self.createRoomBlock = nil;
        [self configXmppRoom:sender.roomJID];
    } else if (self.joinRoomBlock) {
        self.joinRoomBlock(YES);
        self.joinRoomBlock = nil;
    }
}

- (void)xmppRoomDidLeave:(XMPPRoom *)sender
{
    HYLog(@"%@已经离开群组", sender.myRoomJID.resource);
}

- (void)xmppRoomDidDestroy:(XMPPRoom *)sender
{
    HYLog(@"群组已解散，JID = %@", sender.roomJID.bare);
}

#pragma mark 加入群组
- (void)xmppRoom:(XMPPRoom *)sender occupantDidJoin:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence
{
    HYLog(@"xmppRoom occupant已经加入群组, JID = %@, presence = %@", occupantJID, presence);
    
}

#pragma mark 离开群组
- (void)xmppRoom:(XMPPRoom *)sender occupantDidLeave:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence
{
    HYLog(@"xmppRoom occupant离开群组, JID = %@, presence = %@", occupantJID, presence);
}

#pragma mark 群组人员加入
- (void)xmppRoom:(XMPPRoom *)sender occupantDidUpdate:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence
{
    HYLog(@"xmppRoom occupant更新, JID = %@, presence = %@", occupantJID, presence);
    
}

/**
 * Invoked when a message is received.
 * The occupant parameter may be nil if the message came directly from the room, or from a non-occupant.
 **/
- (void)xmppRoom:(XMPPRoom *)sender didReceiveMessage:(XMPPMessage *)message fromOccupant:(XMPPJID *)occupantJID
{
    HYLog(@"xmppRoom接收到聊天室消息, message = %@, JID = %@", message, occupantJID);
    if ([occupantJID.resource isEqualToString:_xmppStream.myJID.user]) { // 收到自己发送的消息
        return;
    }
    
    if ([[message type] isEqualToString:@"groupchat"]) { // 群聊消息
        if ([message body].length) {
            // 1.
            HYRecentChatModel *chatModel = [[HYRecentChatModel alloc] init];
            [[HYDatabaseHandler sharedInstance] recentChatModel:chatModel fromJid:message.from];// 从数据库读取
            chatModel.jid = message.from;
            chatModel.body = [message body];
            chatModel.time = [[NSDate date] timeIntervalSince1970];
            chatModel.isGroup = YES;
            chatModel.unreadCount++;
            [HYNotification postNotificationName:HYChatDidReceiveMessage object:chatModel];
            
            // 2.
            HYChatMessage *chatMessage = [[HYChatMessage alloc] initWithJsonString:[message body]];
            chatMessage.jid = message.from;
            chatMessage.time = [[NSDate date] timeIntervalSince1970];
            chatMessage.isRead = NO;
            chatMessage.isOutgoing = NO;
            chatMessage.isGroup = YES;
            [[HYDatabaseHandler sharedInstance] addGroupChatMessage:chatMessage]; // 储存
            if ([HYXMPPManager sharedInstance].isBackGround == NO) {
                [HYNotification postNotificationName:HYChatDidReceiveGroupMessage object:chatMessage];
            }
            
            // 3.本地通知
            if ([HYXMPPManager sharedInstance].isBackGround == YES) {
                
                // 消息免打扰
                BOOL isShield = [[NSUserDefaults standardUserDefaults] boolForKey:HYChatShieldNotifaction];
                if (isShield) {
                    return;
                }
                // 不显示内容
                BOOL notShowBody = [[NSUserDefaults standardUserDefaults] boolForKey:HYChatNotShowBody];
                
                UILocalNotification *notification = [[UILocalNotification alloc] init];
                // 设置触发通知的时间(立即触发，不需要设置)
                // notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1.0];
                // 时区
                notification.timeZone = [NSTimeZone defaultTimeZone];
                // 设置重复的间隔
                notification.repeatInterval = kCFCalendarUnitSecond;
                
                NSRange atRange = [message.from.resource rangeOfString:@"@"];
                XMPPJID *userJid;
                if (atRange.location == NSNotFound) {
                    userJid = [XMPPJID jidWithString:[NSString stringWithFormat:@"%@@%@",message.from.resource,_xmppStream.myJID.domain]];
                } else {
                    userJid = [XMPPJID jidWithString:message.from.resource];
                }
                
                NSString *nickName = [[HYLoginInfo sharedInstance] nickNameForJid:userJid];
                // 通知内容
                 NSString *bodyString = [HYUtils bodyFromJsonString:[message body]];
                NSString *body = [NSString stringWithFormat:@"%@(%@):%@",nickName,message.from.user,bodyString];
                if (notShowBody) {
                    body = [NSString stringWithFormat:@"来自%@聊天室的新消息",message.from.user];
                }
                notification.alertBody = body;
                notification.alertAction = @"查看"; // 锁屏界面，显示-->滑动XXX
                // 通知被触发时播放的声音
                notification.soundName = UILocalNotificationDefaultSoundName;
                // 通知参数
                NSDictionary *userDict = [NSDictionary dictionaryWithObjectsAndKeys:[message.from full],@"chatJid",@(1),@"isGroup", nil];
                notification.userInfo = userDict;
                // 执行通知注册
                [[UIApplication sharedApplication] scheduleLocalNotification:notification];
            }
            
        }
    }
    
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchBanList:(NSArray *)items
{
    HYLog(@"xmppRoom获取禁止名单列表成功, %@", items);
}
- (void)xmppRoom:(XMPPRoom *)sender didNotFetchBanList:(XMPPIQ *)iqError
{
    HYLog(@"xmppRoom获取禁止名单列表失败, %@", iqError);
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchMembersList:(NSArray *)items
{
    HYLog(@"xmppRoom获取成员列表成功, %@", items);
}

- (void)xmppRoom:(XMPPRoom *)sender didNotFetchMembersList:(XMPPIQ *)iqError
{
    HYLog(@"xmppRoom获取成员列表失败, %@", iqError);
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchAdminsList:(NSArray *)items
{
    HYLog(@"xmppRoom获取管理员列表成功, %@", items);
}
- (void)xmppRoom:(XMPPRoom *)sender didNotFetchAdminsList:(XMPPIQ *)iqError
{
    HYLog(@"xmppRoom获取管理员列表失败, %@", iqError);
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchModeratorsList:(NSArray *)items
{
    HYLog(@"xmppRoom获取ModeratorsList成功, %@", items);
}
- (void)xmppRoom:(XMPPRoom *)sender didNotFetchModeratorsList:(XMPPIQ *)iqError
{
    HYLog(@"xmppRoom获取ModeratorsList失败, %@", iqError);
}

- (void)xmppRoom:(XMPPRoom *)sender didEditPrivileges:(XMPPIQ *)iqResult
{
    HYLog(@"xmppRoom获取到BanList成功, %@", iqResult);
}
- (void)xmppRoom:(XMPPRoom *)sender didNotEditPrivileges:(XMPPIQ *)iqError
{
    HYLog(@"xmppRoom获取到BanList成功, %@", iqError);
}

#pragma mark - XMPPMUCDelegate

/**
 *  接收到群邀请
 */
- (void)xmppMUC:(XMPPMUC *)sender roomJID:(XMPPJID *)roomJID didReceiveInvitation:(XMPPMessage *)message
{
    HYLog(@"xmppMUCDidReceiveInvitation:roomJID = %@, message = %@", roomJID.bare, [message body]);
    
    XMPPRoom *room = [self roomFromJid:roomJID];
    if (room) { // 已经是聊天室成员
        return;
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@邀请你加入聊天室",message.from.user] message:[NSString stringWithFormat:@"%@",[message body]] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"拒绝" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self rejectInviteRoom:roomJID withReason:@"没有兴趣..."]; // 拒绝邀请
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"接受" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self acceptInviteRoom:roomJID]; // 接受邀请
        [self joinRoomWithRoomJID:roomJID withNickName:_xmppStream.myJID.user success:nil];
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
}

- (void)xmppMUC:(XMPPMUC *)sender roomJID:(XMPPJID *)roomJID didReceiveInvitationDecline:(XMPPMessage *)message
{
    HYLog(@"xmppMUCDidReceiveInvitationDecline:roomJID = %@, message = %@", roomJID.bare, [message body]);
}

- (void)xmppMUC:(XMPPMUC *)sender didDiscoverServices:(NSArray *)services
{
    HYLog(@"xmppMUCDidDiscoverServices:services = %@", services);
}

- (void)xmppMUCFailedToDiscoverServices:(XMPPMUC *)sender withError:(NSError *)error
{
   HYLog(@"xmppMUCFailedToDiscoverServices:error = %@", error);
}

- (void)xmppMUC:(XMPPMUC *)sender didDiscoverRooms:(NSArray *)rooms forServiceNamed:(NSString *)serviceName
{
    HYLog(@"xmppMUCDidDiscoverRooms:srooms = %@, serviceName = %@", rooms, serviceName);
}

- (void)xmppMUC:(XMPPMUC *)sender failedToDiscoverRoomsForServiceNamed:(NSString *)serviceName withError:(NSError *)error;
{
    HYLog(@"xmppMUCFailedToDiscoverRoomsForServiceNamed:serviceName = %@, error = %@", serviceName, error);
}

@end
