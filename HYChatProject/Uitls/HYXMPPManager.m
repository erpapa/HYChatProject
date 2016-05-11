//
//  HYXMPPManager.m
//  HYChatProject
//
//  Created by erpapa on 16/4/20.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYXMPPManager.h"
#import "HYLoginInfo.h"
#import "HYUtils.h"
#import "HYXMPPRoomManager.h"
#import "HYRecentChatModel.h"
#import "HYChatMessage.h"
#import "HYDatabaseHandler+HY.h"
#import "XMPPMUC.h"
#import "XMPP+IM.h"
#import "XMPPRoomCoreDataStorage.h"
#import "XMPPCapabilitiesCoreDataStorage.h"

NSString *const HYConnectStatusDidChangeNotification = @"HYConnectStatusDidChangeNotification"; // 连接状态变更通知

@interface HYXMPPManager()<XMPPStreamDelegate, XMPPRosterDelegate, XMPPvCardTempModuleDelegate, XMPPvCardAvatarDelegate>
{
    XMPPReconnect *_xmppReconnect; // 如果失去连接,自动重连
    XMPPvCardTempModule *_vCardTempModule;//好友名片
    XMPPvCardCoreDataStorage *_vCardStorage;//电子名片的数据存储
    XMPPRoster *_xmppRoster;//好友列表类
    XMPPRosterCoreDataStorage *_xmppRosterStorage;//好友列表（用户账号）在core data中的操作类
    XMPPvCardAvatarModule *_vCardAvatarModule;//头像
    XMPPMessageArchiving *_messageArchiving;//信息
    XMPPMessageArchivingCoreDataStorage *_messageArchivingStorage;//信息数据存储
    XMPPCapabilities *_capabilities; // 设置功能
    XMPPCapabilitiesCoreDataStorage *_capabilitiesStorage; // 设置功能储存
}
@property (nonatomic, assign) BOOL registerUser;
@property (nonatomic, strong) NSMutableDictionary *avatarBlockDict; // 头像block
@property (nonatomic, strong) NSMutableDictionary *vCardBlockDict; // 名片block
@property (nonatomic, copy) HYXMPPConnectStatusBlock connectStatusBlock; // 连接状态
@property (nonatomic, copy) HYUpdatevCardSuccess updatevCardSuccess; // 更新名片成功/失败

@end

@implementation HYXMPPManager

/**
 *  单例
 */
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    // dispatch_once宏可以保证块代码中的指令只被执行一次
    static HYXMPPManager *instance;
    dispatch_once(&onceToken, ^{
        instance = [[super alloc] init];
    });
    
    return instance;
}

#pragma mark  -私有方法
/**
 *  发送通知
 */
- (void)postConnectStatus:(HYXMPPConnectStatus)status
{
    [[NSNotificationCenter defaultCenter] postNotificationName:HYConnectStatusDidChangeNotification object:@(status)];
}

/**
 *  初始化XMPPStream
 */
-(void)setupXMPPStream{
    
    _xmppStream = [[XMPPStream alloc] init];

    //添加自动连接模块
    _xmppReconnect = [[XMPPReconnect alloc] init];

    //添加电子名片模块
    _vCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
    _vCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:_vCardStorage];
    //添加头像模块
    _vCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:_vCardTempModule];
    
    // 添加花名册模块【获取好友列表】
    _xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    // 不用每次都重新创建数据库，否则会导致未读消息数丢失，good idea
    _xmppRosterStorage.autoRemovePreviousDatabaseFile = NO;
    _xmppRosterStorage.autoRecreateDatabaseFile = NO;
    
    _xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:_xmppRosterStorage];
    _xmppRoster.autoFetchRoster = YES; //  //自动从服务器更新好友记录,例如:好友更改了名片
    _xmppRoster.autoClearAllUsersAndResources = NO; // 断开连接不清空好友列表
    _xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;// 开启接收自动订阅功能（加好友不需要验证）
    
    // 添加聊天模块
    _messageArchivingStorage = [[XMPPMessageArchivingCoreDataStorage alloc] init];
    _messageArchiving = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:_messageArchivingStorage];
    
    // 设置功能
    _capabilitiesStorage = [XMPPCapabilitiesCoreDataStorage sharedInstance];
    _capabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:_capabilitiesStorage];
    _capabilities.autoFetchHashedCapabilities = YES;
    _capabilities.autoFetchNonHashedCapabilities = NO;
    
    // 激活模块
    [_xmppReconnect     activate:_xmppStream];
    [_vCardTempModule   activate:_xmppStream];
    [_vCardAvatarModule activate:_xmppStream];
    [_xmppRoster        activate:_xmppStream];
    [_messageArchiving  activate:_xmppStream];
    
    _xmppStream.enableBackgroundingOnSocket = YES;// 允许在后台运行
    
    // 设置代理
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()]; // 主线程调用代理
    [_xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [_vCardTempModule addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [_vCardAvatarModule addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [_messageArchiving addDelegate:self delegateQueue:dispatch_get_main_queue()];
}

- (void)dealloc
{
    [_xmppStream        removeDelegate:self];
    [_xmppRoster        removeDelegate:self];
    [_vCardTempModule   removeDelegate:self];
    [_vCardAvatarModule removeDelegate:self];
    [_messageArchiving  removeDelegate:self];
    
    [_xmppReconnect       deactivate];
    [_vCardTempModule     deactivate];
    [_vCardAvatarModule   deactivate];
    [_xmppRoster          deactivate];
    [_messageArchiving    deactivate];
    
    [_xmppStream disconnect];
    _xmppStream = nil;
    _xmppReconnect = nil;
    _vCardStorage = nil;
    _vCardTempModule = nil;
    _vCardAvatarModule = nil;
    _xmppRoster = nil;
    _xmppRosterStorage = nil;
    _messageArchiving = nil;
    _messageArchivingStorage = nil;
    _capabilities = nil;
    _capabilitiesStorage = nil;
}

#pragma mark -公共方法

- (void)setChatJID:(XMPPJID *)chatJID
{
    _chatJID = chatJID;
    if (_chatJID) {
        [HYNotification postNotificationName:HYChatWithSomebody object:_chatJID];
    }
}

// 登录
- (void)xmppUserLogin:(HYXMPPConnectStatusBlock)resultBlock{
    self.registerUser = NO;
    // 先把block存起来
    self.connectStatusBlock = resultBlock;
    
    //  Domain=XMPPStreamErrorDomain Code=1 "Attempting to connect while already connected or connecting." UserInfo=0x7fd86bf06700 {NSLocalizedDescription=Attempting to connect while already connected or connecting.}
    // 如果以前连接过服务，要断开
    [_xmppStream disconnect];
    
    // 连接主机 成功后发送登录密码
    [self connectToHost];
}
// 注册（先建立匿名连接）
- (void)xmppUserRegister:(HYXMPPConnectStatusBlock)resultBlock{
    self.registerUser = YES;
    // 先把block存起来
    self.connectStatusBlock = resultBlock;
    
    // 如果以前连接过服务，要断开
    [_xmppStream disconnect];
    
    // 连接主机 成功后发送注册密码
    [self connectToHost];
}

// 注销
- (void)xmppUserlogout
{
    // 1." 发送 "离线" 消息"
    XMPPPresence *offline = [XMPPPresence presenceWithType:@"unavailable"];
    [_xmppStream sendElement:offline];
    
    // 2. 与服务器断开连接
    [_xmppStream disconnect];
    
    // 3.更新用户的登录状态
    [HYLoginInfo sharedInstance].logon = NO;
    [[HYLoginInfo sharedInstance] saveUserInfoToSanbox];
    
    // 4.切换根控制器
    [HYUtils initRootViewController];
}

// 更改密码
- (void)xmppUserChangePassword:(NSString *)password
{
    NSXMLElement *query =[NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:register"];
    NSXMLElement *username =[NSXMLElement elementWithName:@"username" stringValue:_myJID.user];
    NSXMLElement *changePassword =[NSXMLElement elementWithName:@"password" stringValue:password];
    [query addChild:username];
    [query addChild:changePassword];
    
    XMPPIQ *iq =[XMPPIQ iqWithType:@"set" elementID:[XMPPStream generateUUID] child:query];
    [iq addAttributeWithName:@"to" stringValue:[NSString stringWithFormat:@"%@",_myJID.domain]];
    [_xmppStream sendElement:iq];
}


/**
 *  获得我的名片
 */
- (void)getMyvCard:(HYvCardBlock)myvCardBlock
{
    XMPPvCardTemp *vCardtemp=[_vCardTempModule myvCardTemp];
    if (vCardtemp) {
        myvCardBlock(vCardtemp); // 返回我的名片
    } else {
        [self.vCardBlockDict setObject:[myvCardBlock copy] forKey:[_myJID bare]];
    }
}
/**
 *  更新我的名片
 */
- (void)updateMyvCard:(XMPPvCardTemp *)myvCard successBlock:(HYUpdatevCardSuccess)successBlock
{
    self.updatevCardSuccess = successBlock;
    [_vCardTempModule updateMyvCardTemp:myvCard];// 更新名片
}
/**
 *  获得好友名片
 */
- (void)getvCardFromJID:(XMPPJID *)jid vCardBlock:(HYvCardBlock)vCardBlock
{
    if (jid == nil) {
        vCardBlock(nil);
    }
    // 如果本地为空，自动从网络获取好友名片
    XMPPvCardTemp *vCardTemp = [_vCardTempModule vCardTempForJID:jid shouldFetch:YES];
    if (vCardTemp) {
        vCardBlock(vCardTemp);
    } else {
        [self.vCardBlockDict setObject:[vCardBlock copy] forKey:[jid bare]];
    }
}

/**
 *  获得好友头像
 */
- (void)getAvatarFromJID:(XMPPJID *)jid avatarBlock:(HYAvatarBlock)avatarBlock
{
    if (jid == nil) {
        avatarBlock(nil);
        return;
    }
    NSData *data = [_vCardAvatarModule photoDataForJID:jid];
    if (data) {
        avatarBlock(data);
    } else {
        [self.avatarBlockDict setObject:[avatarBlock copy] forKey:[jid bare]];
    }
}


/**
 *  添加好友
 */
- (int)addUser:(XMPPJID *)userID
{
    if ([userID.bare isEqualToString:_myJID.bare]) {
        return -1;
    }
    BOOL contains = [_xmppRosterStorage userExistsWithJID:userID xmppStream:_xmppStream];// 如果已经是好友就不需要再次添加
    if (contains) {
        return 0;
    }
    [_xmppRoster subscribePresenceToUser:userID];
    return 1;
}
/**
 *  删除好友
 */
- (void)removeUser:(XMPPJID *)jid
{
    [_xmppRoster removeUser:jid];
}

/**
 *  同意好友申请
 */
-(void)agreeUserRequest:(XMPPJID *)jid
{
    if ([[jid bare] isEqualToString:[_myJID bare]]) {
        return; // 自己不能添加自己为好友
    }
    [_xmppRoster acceptPresenceSubscriptionRequestFrom:jid andAddToRoster:YES];
}
/**
 *  拒绝好友申请
 */
-(void)rejectUserRequest:(XMPPJID *)jid
{
    [_xmppRoster rejectPresenceSubscriptionRequestFrom:jid];
}

/**
 *  发送聊天消息
 */

- (void)sendText:(NSString *)text
{
    XMPPJID *jid = self.chatJID;
    if (jid) {
        [self sendText:text toJid:jid];
    }
}
- (void)sendText:(NSString *)text toJid:(XMPPJID *)jid
{
    // 发送聊天消息
    XMPPMessage *message = [XMPPMessage messageWithType:@"chat" to:jid];
    [message addBody:text];
    [_xmppStream sendElement:message];
//    XMPPElementReceipt *receipt = [XMPPElementReceipt new];
//    [_xmppStream sendElement:message andGetReceipt:&receipt];
//    BOOL messageState =[receipt wait:-1];
//    return messageState;
    
}

/**
 *  CoreData
 */
- (NSManagedObjectContext *)managedObjectContext_roster
{
    return [_xmppRosterStorage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext *)managedObjectContext_capabilities
{
    return [_capabilitiesStorage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext *)managedObjectContext_messageArchiving
{
    return [_messageArchivingStorage mainThreadManagedObjectContext];
}

#pragma mark 连接到服务器
-(void)connectToHost{
    if (!_xmppStream) {//如果_xmppStream为空，则初始化_xmppStream
        [self setupXMPPStream];
    }
    HYLoginInfo *userInfo = [HYLoginInfo sharedInstance];
    _myJID = userInfo.jid;
    _xmppStream.myJID = userInfo.jid;
    
    // 设置服务器域名
    _xmppStream.hostName = userInfo.hostName;
    // 设置端口 默认是5222
    _xmppStream.hostPort = userInfo.hostPort;
    // 连接，设置超时为2.0f
    if (![_xmppStream connectWithTimeout:2.0f error:nil]) {
        if (self.connectStatusBlock) {
            self.connectStatusBlock(HYXMPPConnectStatusDisConnect);
        }
    }
    
}

// 将要连接到服务器
- (void)xmppStreamWillConnect:(XMPPStream *)sender
{
    HYLog(@"将要连接到服务器");
    _status = HYXMPPConnectStatusConnecting;
    [self postConnectStatus:HYXMPPConnectStatusConnecting];// 发送通知【正在连接】
    if (self.connectStatusBlock) {
        self.connectStatusBlock(HYXMPPConnectStatusConnecting);
    }
}

// 当tcp socket已经与远程主机连接上时会回调此代理方法
// 若App要求在后台运行，需要设置XMPPStream's enableBackgroundingOnSocket属性
- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket
{
    HYLog(@"已经与远程主机建立TCP Socket连接");
}
// 当TCP与服务器建立连接后会回调此代理方法
- (void)xmppStreamDidStartNegotiation:(XMPPStream *)sender
{
    HYLog(@"与服务器建立TCP连接");
}

// 连接超时
- (void)xmppStreamConnectDidTimeout:(XMPPStream *)sender
{
    HYLog(@"连接超时");
    _status = HYXMPPConnectStatusTimeOut;
    [self postConnectStatus:HYXMPPConnectStatusTimeOut];
    if (self.connectStatusBlock) { // 回调
        self.connectStatusBlock(HYXMPPConnectStatusTimeOut);
        self.connectStatusBlock = nil;
    }
}


/* ejabberd 配置/opt/ejabberd-15.10/conf/ejabberd.yml
## In-band registration allows registration of any possible username.
## To disable in-band registration, replace 'allow' with 'deny'.
register:
    all: allow  // 允许注册
## Only allow to register from localhost
trusted_network:
    all: allow  // 允许所有人注册
*/
// 与主机连接成功
-(void)xmppStreamDidConnect:(XMPPStream *)sender{
    HYLog(@"与主机连接成功");
    _status = HYXMPPConnectStatusDidConnect;
    [self postConnectStatus:HYXMPPConnectStatusDidConnect];
    if (self.connectStatusBlock) {
        self.connectStatusBlock(HYXMPPConnectStatusDidConnect);
    }
    NSString *pwd = [HYLoginInfo sharedInstance].password;
    if (self.registerUser == YES) {//注册操作，发送注册的密码
        [_xmppStream registerWithPassword:pwd error:nil];
    }else{  //登录操作
        [_xmppStream authenticateWithPassword:pwd error:nil];
    }
}
// 与主机断开连接
-(void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error{
    HYLog(@"与主机断开连接 %@",error);
    if (_status == HYXMPPConnectStatusConnecting) {
        if (self.connectStatusBlock) {// 判断block有无值，再回调
            self.connectStatusBlock(HYXMPPConnectStatusDisConnect);
            self.connectStatusBlock = nil;
        }
    }
    _status = HYXMPPConnectStatusDisConnect;
    [self postConnectStatus:HYXMPPConnectStatusDisConnect];
}

#pragma mark - 授权成功
-(void)xmppStreamDidAuthenticate:(XMPPStream *)sender{
    HYLog(@"授权成功，发送在线消息");
    XMPPPresence *presence = [XMPPPresence presence];
    [_xmppStream sendElement:presence];
    [[HYXMPPRoomManager sharedInstance] fetchBookmarkedRooms:nil];// 加入所有已加入/创建的房间
    [_vCardTempModule myvCardTemp]; // 获取自己的名片
    _status = HYXMPPConnectStatusAuthSuccess;
    [self postConnectStatus:HYXMPPConnectStatusAuthSuccess];
    // 回调控制器登录成功
    if(self.connectStatusBlock){
        self.connectStatusBlock(HYXMPPConnectStatusAuthSuccess);
        self.connectStatusBlock = nil;
    }
   
}

#pragma mark - 授权失败
-(void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error{
    HYLog(@"授权失败 %@",error);
    _status = HYXMPPConnectStatusAuthFailure;
    [self postConnectStatus:HYXMPPConnectStatusAuthFailure];
    // 判断block有无值，再回调给登录控制器
    if (self.connectStatusBlock) {
        self.connectStatusBlock(HYXMPPConnectStatusAuthFailure);
        self.connectStatusBlock = nil;
    }
}

#pragma mark - 注册成功
-(void)xmppStreamDidRegister:(XMPPStream *)sender{
    HYLog(@"注册成功");
    _status = HYXMPPConnectStatusRegisterSuccess;
    [self postConnectStatus:HYXMPPConnectStatusRegisterSuccess];
    if(self.connectStatusBlock){
        self.connectStatusBlock(HYXMPPConnectStatusRegisterSuccess);
        self.connectStatusBlock = nil;
    }
}

#pragma mark - 注册失败
-(void)xmppStream:(XMPPStream *)sender didNotRegister:(DDXMLElement *)error{
    HYLog(@"注册失败 %@",error);
    _status = HYXMPPConnectStatusRegisterFailure;
    [self postConnectStatus:HYXMPPConnectStatusRegisterFailure];
    if(self.connectStatusBlock){
        self.connectStatusBlock(HYXMPPConnectStatusRegisterFailure);
        self.connectStatusBlock = nil;
    }
}

#pragma mark - 当修改了JID信息时，会回调此代理方法
- (void)xmppStreamDidChangeMyJID:(XMPPStream *)xmppStream
{
    HYLog(@"修改了JID信息");
}

#pragma mark - 当Stream被告知与服务器断开连接时会回调此代理方法
- (void)xmppStreamWasToldToDisconnect:(XMPPStream *)sender
{
    HYLog(@"Stream被告知与服务器断开连接");
}

#pragma mark - 当发送了</stream:stream>节点时，会回调此代理方法
- (void)xmppStreamDidSendClosingStreamStanza:(XMPPStream *)sender
{
     HYLog(@"发送了断开Stream节点</stream:stream>");
}

#pragma mark - 将要绑定JID resource时的回调
// 这是授权程序的标准部分，当验证JID用户名通过时，下一步就验证resource。若使用标准绑定处理，return nil或者不要实现此方法
//- (id <XMPPCustomBinding>)xmppStreamWillBind:(XMPPStream *)sender;

#pragma mark - 如果服务器出现resouce冲突而导致不允许resource选择时，会回调此代理方法。
// 返回指定的resource或者返回nil让服务器自动帮助我们来选择。一般不用实现它。
//- (NSString *)xmppStream:(XMPPStream *)sender alternativeResourceForConflictingResource:(NSString *)conflictingResource;


// ######################### 接收消息 #######################

#pragma mark - ####### 接收消息 #######

// 将要收到IQ（消息查询）时的回调
//- (XMPPIQ *)xmppStream:(XMPPStream *)sender willReceiveIQ:(XMPPIQ *)iq
//{
//    return nil;
//}
// 将要接收到消息时的回调
//- (XMPPMessage *)xmppStream:(XMPPStream *)sender willReceiveMessage:(XMPPMessage *)message
//{
//    return nil;
//}
// 将要接收到用户在线状态时的回调
//- (XMPPPresence *)xmppStream:(XMPPStream *)sender willReceivePresence:(XMPPPresence *)presence
//{
//    return nil;
//}
// 当xmppStream:willReceiveX:(也就是前面这三个API回调后)，过滤了stanza，会回调此代理方法。
// 通过实现此代理方法，可以知道被过滤的原因，有一定的帮助。
//- (void)xmppStreamDidFilterStanza:(XMPPStream *)sender;

// 在接收了IQ（消息查询后）会回调此代理方法
//- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
//{
//    return YES;
//}

// 在接收了消息后会回调此代理方法
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    //XEP--0136 已经用coreData实现了数据的接收和保存
    // 1.单聊消息
    if ([[message type] isEqualToString:@"chat"]) {
        if ([message body].length) {
            // 1.
            HYRecentChatModel *chatModel = [[HYRecentChatModel alloc] init];
            [[HYDatabaseHandler sharedInstance] recentChatModel:chatModel fromJid:message.from];// 从数据库读取
            chatModel.jid = message.from;
            chatModel.body = [message body];
            chatModel.time = [[NSDate date] timeIntervalSince1970];
            chatModel.isGroup = NO;
            chatModel.unreadCount++;
            [HYNotification postNotificationName:HYChatDidReceiveMessage object:chatModel];
            
            // 2.
            HYChatMessage *chatMessage = [[HYChatMessage alloc] initWithJsonString:[message body]];
            chatMessage.jid = message.from;
            chatMessage.time = [[NSDate date] timeIntervalSince1970];
            chatMessage.isRead = NO;
            chatMessage.isOutgoing = NO;
            chatMessage.isGroup = NO;
            [[HYDatabaseHandler sharedInstance] addChatMessage:chatMessage]; // 储存
            [HYNotification postNotificationName:HYChatDidReceiveSingleMessage object:chatMessage];
        }
    }
}
// 在接收了用户在线状态消息后会回调此代理方法
- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    //XMPPPresence 在线/离线
    //presence.from 消息是谁发送过来
    HYLog(@"接收好友状态from %@ type: %@", presence.from, presence.type);
    //取得好友状态
    NSString *presenceType = [NSString stringWithFormat:@"%@", [presence type]]; //online/offline
    //当前用户
    //    NSString *userId = [NSString stringWithFormat:@"%@", [[sender myJID] user]];
    //在线用户
    //    NSString *presenceFromUser =[NSString stringWithFormat:@"%@", [[presence from] user]];
    //这里再次加好友
    if ([presenceType isEqualToString:@"subscribed"]) { // 对方同意添加好友回执
        XMPPJID *jid = [XMPPJID jidWithString:[NSString stringWithFormat:@"%@",[presence from]]];
        [_xmppRoster acceptPresenceSubscriptionRequestFrom:jid andAddToRoster:YES];
    }
}

// 在接收IQ/messag、presence出错时，会回调此代理方法
- (void)xmppStream:(XMPPStream *)sender didReceiveError:(NSXMLElement *)error;
{
    HYLog(@"error %@", error);
}


// ######################### 发送消息 #######################

#pragma mark - ####### 发送消息 ########
// 将要发送IQ（消息查询时）时会回调此代理方法
//- (XMPPIQ *)xmppStream:(XMPPStream *)sender willSendIQ:(XMPPIQ *)iq
//{
//    return nil;
//}
// 在将要发送消息时，会回调此代理方法
//- (XMPPMessage *)xmppStream:(XMPPStream *)sender willSendMessage:(XMPPMessage *)message
//{
//    return nil;
//}
// 在将要发送用户在线状态信息时，会回调此方法
//- (XMPPPresence *)xmppStream:(XMPPStream *)sender willSendPresence:(XMPPPresence *)presence
//{
//    return nil;
//}

// 在发送IQ（消息查询）成功后会回调此代理方法
- (void)xmppStream:(XMPPStream *)sender didSendIQ:(XMPPIQ *)iq
{
    
}
// 在发送消息成功后，会回调此代理方法
- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message
{
    // 1.单聊消息
    if ([[message type] isEqualToString:@"chat"]) {
        if ([message body].length) {
            // 1.
            HYRecentChatModel *chatModel = [[HYRecentChatModel alloc] init];
            [[HYDatabaseHandler sharedInstance] recentChatModel:chatModel fromJid:message.from];// 从数据库读取
            chatModel.jid = message.to;
            chatModel.body = [message body];
            chatModel.time = [[NSDate date] timeIntervalSince1970];
            chatModel.isGroup = NO;
            chatModel.unreadCount = 0;
            [HYNotification postNotificationName:HYChatDidReceiveMessage object:chatModel];
            
            // 2.
            HYChatMessage *chatMessage = [[HYChatMessage alloc] initWithJsonString:[message body]];
            chatMessage.jid = message.to;
            chatMessage.time = [[NSDate date] timeIntervalSince1970];
            chatMessage.isRead = YES;
            chatMessage.isOutgoing = YES;
            chatMessage.isGroup = NO;
            chatMessage.sendStatus = HYChatSendMessageStatusSuccess; // 发送成功
            [[HYDatabaseHandler sharedInstance] addChatMessage:chatMessage]; // 储存
            [HYNotification postNotificationName:HYChatDidReceiveSingleMessage object:chatMessage];
        }
    }
}
// 在发送用户在线状态信息成功后，会回调此方法
- (void)xmppStream:(XMPPStream *)sender didSendPresence:(XMPPPresence *)presence
{
    
}

#pragma mark - ####### 发送消息失败 ########

// 在发送IQ（消息查询）失败后会回调此代理方法
- (void)xmppStream:(XMPPStream *)sender didFailToSendIQ:(XMPPIQ *)iq error:(NSError *)error
{
    
}
// 在发送消息失败后，会回调此代理方法
- (void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error
{
    // 1.单聊消息
    if ([[message type] isEqualToString:@"chat"]) {
        if ([message body].length) {
            // 1.
            HYRecentChatModel *chatModel = [[HYRecentChatModel alloc] init];
            [[HYDatabaseHandler sharedInstance] recentChatModel:chatModel fromJid:message.from];// 从数据库读取
            chatModel.jid = message.to;
            chatModel.body = [message body];
            chatModel.time = [[NSDate date] timeIntervalSince1970];
            chatModel.isGroup = NO;
            chatModel.unreadCount = 0;
            [HYNotification postNotificationName:HYChatDidReceiveMessage object:chatModel];
            
            // 2.
            HYChatMessage *chatMessage = [[HYChatMessage alloc] initWithJsonString:[message body]];
            chatMessage.jid = message.to;
            chatMessage.time = [[NSDate date] timeIntervalSince1970];
            chatMessage.isRead = YES;
            chatMessage.isOutgoing = YES;
            chatMessage.isGroup = NO;
            chatMessage.sendStatus = HYChatSendMessageStatusFaild; // 发送失败
            [[HYDatabaseHandler sharedInstance] addChatMessage:chatMessage]; // 储存
            [HYNotification postNotificationName:HYChatDidReceiveSingleMessage object:chatMessage];
        }
    }
}
// 在发送用户在线状态失败信息后，会回调此方法
- (void)xmppStream:(XMPPStream *)sender didFailToSendPresence:(XMPPPresence *)presence error:(NSError *)error
{
    
}


#pragma mark - p2p - 相关
//- (void)xmppStream:(XMPPStream *)sender didReceiveP2PFeatures:(NSXMLElement *)streamFeatures
//{
//    
//}
//- (void)xmppStream:(XMPPStream *)sender willSendP2PFeatures:(NSXMLElement *)streamFeatures
//{
//    
//}

#pragma mark - 这些方法称为XMPP模块注册和未注册与流
//- (void)xmppStream:(XMPPStream *)sender didRegisterModule:(id)module
//{
//    
//}
//
//- (void)xmppStream:(XMPPStream *)sender willUnregisterModule:(id)module
//{
//    
//}

#pragma mark - 当发送/接收非XMPP元素节点时，会回调此代理方法。
// 如果发送的element不是<iq>, <message> 或者 <presence>，那么就会回调此代理方法
- (void)xmppStream:(XMPPStream *)sender didSendCustomElement:(NSXMLElement *)element
{
    
}

// 如果接收的element不是 <iq>, <message> 或者 <presence>，那么就会回调此代理方法
- (void)xmppStream:(XMPPStream *)sender didReceiveCustomElement:(NSXMLElement *)element
{
    
}

#pragma mark - 电子名片 - XMPPvCardTempModuleDelegate

// 接收到电子名片
- (void)xmppvCardTempModule:(XMPPvCardTempModule *)vCardTempModule
        didReceivevCardTemp:(XMPPvCardTemp *)vCardTemp
                     forJID:(XMPPJID *)jid
{
    HYvCardBlock vCardBlock = [self.vCardBlockDict objectForKey:[jid bare]];
    if (vCardBlock) {
        vCardBlock(vCardTemp);
        [self.vCardBlockDict removeObjectForKey:[jid bare]]; // 删除该键值
    }
    
    // 储存自己的名片
    if ([jid.bare isEqualToString:[_myJID bare]]) {
        [HYUtils saveCurrentUservCard:vCardTemp];
    }
    
}
// 更新我的电子名片成功
- (void)xmppvCardTempModuleDidUpdateMyvCard:(XMPPvCardTempModule *)vCardTempModule
{
    if (self.updatevCardSuccess) {
        self.updatevCardSuccess(YES);
        self.updatevCardSuccess = nil;
    }
}
// 更新我的电子名片失败
- (void)xmppvCardTempModule:(XMPPvCardTempModule *)vCardTempModule failedToUpdateMyvCard:(NSXMLElement *)error
{
    if (self.updatevCardSuccess) {
        self.updatevCardSuccess(NO);
        self.updatevCardSuccess = nil;
    }
}

#pragma mark - 头像 - XMPPvCardAvatarModuleDelegate
- (void)xmppvCardAvatarModule:(XMPPvCardAvatarModule *)vCardTempModule
              didReceivePhoto:(UIImage *)photo
                       forJID:(XMPPJID *)jid
{
    HYAvatarBlock avatarBlock = [self.avatarBlockDict objectForKey:[jid bare]];
    if (avatarBlock) {
        NSData *data = UIImageJPEGRepresentation(photo,0.9);
        avatarBlock(data);
        [self.avatarBlockDict removeObjectForKey:[jid bare]];
    }
    
}

#pragma mark - XMPPRosterDelegate
/**
 *  处理加好友回调,加好友
 */
- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence
{
    HYLog(@"接收到%@的好友请求：%@",[presence from], presence);
    XMPPJID *jid = [XMPPJID jidWithString:[NSString stringWithFormat:@"%@",[presence from]]];
    NSString *message = [NSString stringWithFormat:@"\n%@请求添加您为好友！", jid.user];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"拒绝" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self rejectUserRequest:jid];
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"同意" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self agreeUserRequest:jid];
    }];
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

/**
 * Sent when a Roster Push is received as specified in Section 2.1.6 of RFC 6121.
 **/
- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterPush:(XMPPIQ *)iq
{
    
}

/**
 * Sent when the initial roster is received.
 **/
- (void)xmppRosterDidBeginPopulating:(XMPPRoster *)sender withVersion:(NSString *)version
{
    
}

/**
 * Sent when the initial roster has been populated into storage.
 **/
- (void)xmppRosterDidEndPopulating:(XMPPRoster *)sender
{
    
}

/**
 * Sent when the roster receives a roster item.
 *
 * Example:
 *
 * <item jid='romeo@example.net' name='Romeo' subscription='both'>
 *   <group>Friends</group>
 * </item>
 **/
- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterItem:(NSXMLElement *)item
{
    
}

#pragma mark - 懒加载

- (NSMutableDictionary *)avatarBlockDict
{
    if (_avatarBlockDict == nil) {
        _avatarBlockDict = [NSMutableDictionary dictionary];
    }
    return _avatarBlockDict;
}

- (NSMutableDictionary *)vCardBlockDict
{
    if (_vCardBlockDict == nil) {
        _vCardBlockDict = [NSMutableDictionary dictionary];
    }
    return _vCardBlockDict;
}



@end
