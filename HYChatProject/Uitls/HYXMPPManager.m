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
#import "HYRecentChatModel.h"
#import "HYDatabaseHandler+HY.h"
#import "XMPPRoomCoreDataStorage.h"
#import "XMPPCapabilitiesCoreDataStorage.h"

NSString *const HYConnectStatusDidChangeNotification = @"HYConnectStatusDidChangeNotification"; // 连接状态变更通知

@interface HYXMPPManager()<XMPPStreamDelegate, XMPPRosterDelegate, XMPPvCardTempModuleDelegate, XMPPvCardAvatarDelegate>
{
    XMPPReconnect *_xmppReconnect; // 如果失去连接,自动重连
    XMPPvCardTempModule *_vCardTempModule;//好友名片
    XMPPvCardCoreDataStorage *_vCardStorage;//电子名片的数据存储
    XMPPRoster *_roster;//好友列表类
    XMPPRosterCoreDataStorage *_rosterStorage;//好友列表（用户账号）在core data中的操作类
    XMPPvCardAvatarModule *_vCardAvatarModule;//头像
    XMPPRoom *_room;
    XMPPRoomCoreDataStorage *_roomStorage;
    XMPPMessageArchiving *_messageArchiving;//信息
    XMPPMessageArchivingCoreDataStorage *_messageArchivingStorage;//信息数据存储
    XMPPCapabilities *_capabilities; // 设置功能
    XMPPCapabilitiesCoreDataStorage *_capabilitiesStorage; // 设置功能储存
}
@property (assign, nonatomic) BOOL registerUser;
@property (strong, nonatomic) NSMutableDictionary *avatarBlockDict; // 头像block
@property (strong, nonatomic) NSMutableDictionary *vCardBlockDict; // 名片block
@property (copy, nonatomic) HYXMPPConnectStatusBlock connectStatusBlock; // 连接状态
@property (copy, nonatomic) HYSuccessBlock successBlock; // 操作成功/失败

@end

@implementation HYXMPPManager

static HYXMPPManager *instance;

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
    _rosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    // 不用每次都重新创建数据库，否则会导致未读消息数丢失，good idea
    _rosterStorage.autoRemovePreviousDatabaseFile = NO;
    _rosterStorage.autoRecreateDatabaseFile = NO;
    
    _roster = [[XMPPRoster alloc] initWithRosterStorage:_rosterStorage];
    _roster.autoFetchRoster = YES; // 自动获取好友列表
    _roster.autoClearAllUsersAndResources = NO; // 断开连接不清空好友列表
    _roster.autoAcceptKnownPresenceSubscriptionRequests = YES;
    
    // 设置房间
    _roomStorage = [[XMPPRoomCoreDataStorage alloc] init];
    _roomStorage.autoRemovePreviousDatabaseFile = NO;
    _roomStorage.autoRecreateDatabaseFile = NO;
    
    // 添加聊天模块
    _messageArchivingStorage = [[XMPPMessageArchivingCoreDataStorage alloc] init];
    _messageArchiving = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:_messageArchivingStorage];
    
    // 设置功能
    _capabilitiesStorage = [XMPPCapabilitiesCoreDataStorage sharedInstance];
    _capabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:_capabilitiesStorage];
    _capabilities.autoFetchHashedCapabilities = YES;
    _capabilities.autoFetchNonHashedCapabilities = NO;
    
    // 激活模块
    [_xmppReconnect activate:_xmppStream];
    [_vCardTempModule activate:_xmppStream];
    [_vCardAvatarModule activate:_xmppStream];
    [_roster activate:_xmppStream];
    [_messageArchiving activate:_xmppStream];
    
    _xmppStream.enableBackgroundingOnSocket = YES;// 允许在后台运行
    
    // 设置代理
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [_roster addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [_vCardTempModule addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [_vCardAvatarModule addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
}

- (void)dealloc
{
    [_xmppStream        removeDelegate:self];
    [_roster            removeDelegate:self];
    [_vCardTempModule   removeDelegate:self];
    [_vCardAvatarModule removeDelegate:self];
    [_messageArchiving  removeDelegate:self];
    
    [_xmppReconnect       deactivate];
    [_vCardTempModule     deactivate];
    [_vCardAvatarModule   deactivate];
    [_roster              deactivate];
    [_messageArchiving    deactivate];
    
    [_xmppStream disconnect];
    _xmppStream = nil;
    _xmppReconnect = nil;
    _vCardStorage = nil;
    _vCardTempModule = nil;
    _vCardAvatarModule = nil;
    _roster = nil;
    _rosterStorage = nil;
    _room = nil;
    _roomStorage = nil;
    _messageArchiving = nil;
    _messageArchivingStorage = nil;
    _capabilities = nil;
    _capabilitiesStorage = nil;
}

#pragma mark -公共方法

/**
 *  CoreData
 */
- (NSManagedObjectContext *)managedObjectContext_roster
{
    return [_rosterStorage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext *)managedObjectContext_capabilities
{
    return [_capabilitiesStorage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext *)managedObjectContext_messageArchiving
{
    return [_messageArchivingStorage mainThreadManagedObjectContext];
}


- (NSManagedObjectContext *)managedObjectContext_room
{
    return [_roomStorage mainThreadManagedObjectContext];
}

// 注销
-(void)xmppUserlogout
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
// 登录
-(void)xmppUserLogin:(HYXMPPConnectStatusBlock)resultBlock{
    self.registerUser = NO;
    // 先把block存起来
    self.connectStatusBlock = resultBlock;
    
    //  Domain=XMPPStreamErrorDomain Code=1 "Attempting to connect while already connected or connecting." UserInfo=0x7fd86bf06700 {NSLocalizedDescription=Attempting to connect while already connected or connecting.}
    // 如果以前连接过服务，要断开
    [_xmppStream disconnect];
    
    // 连接主机 成功后发送登录密码
    [self connectToHost];
}
// 注册
-(void)xmppUserRegister:(HYXMPPConnectStatusBlock)resultBlock{
    self.registerUser = YES;
    // 先把block存起来
    self.connectStatusBlock = resultBlock;
    
    // 如果以前连接过服务，要断开
    [_xmppStream disconnect];
    
    // 连接主机 成功后发送注册密码
    [self connectToHost];
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
        [self.vCardBlockDict setObject:[myvCardBlock copy] forKey:[[HYLoginInfo sharedInstance].jid bare]];
    }
}
/**
 *  更新我的名片
 */
- (void)updateMyvCard:(XMPPvCardTemp *)myvCard successBlock:(HYSuccessBlock)successBlock
{
    self.successBlock = successBlock;
    [_vCardTempModule updateMyvCardTemp:myvCard];// 更新名片
}
/**
 *  获得好友名片
 */
- (void)getvCardFromJID:(XMPPJID *)jid shouldRefresh:(BOOL)shouldRefresh vCardBlock:(HYvCardBlock)vCardBlock
{
    // 如果本地为空，自动从网络获取好友名片
    XMPPvCardTemp *vCardTemp = [_vCardTempModule vCardTempForJID:jid shouldFetch:!shouldRefresh];
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
    NSData *data = [_vCardAvatarModule photoDataForJID:jid];
    if (data) {
        avatarBlock(data);
    } else {
        [self.avatarBlockDict setObject:[avatarBlock copy] forKey:[jid bare]];
    }
}

#pragma mark 连接到服务器
-(void)connectToHost{
    if (!_xmppStream) {//如果_xmppStream为空，则初始化_xmppStream
        [self setupXMPPStream];
    }
    HYLoginInfo *userInfo = [HYLoginInfo sharedInstance];
    // 设置登录用户JID
    _xmppStream.myJID = userInfo.jid;
    // 设置服务器域名
    _xmppStream.hostName = userInfo.hostName;
    // 设置端口 默认是5222
    _xmppStream.hostPort = userInfo.hostPort;
    // 连接，设置超时为2.0f
    NSError *error = nil;
    if (![_xmppStream connectWithTimeout:2.0f error:&error]) {
        HYLog(@"%@",error);
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
    if (message.body != nil) {
        HYRecentChatModel *chatModel = [[HYRecentChatModel alloc] init];
        [[HYDatabaseHandler sharedInstance] recentChatModel:chatModel fromJid:message.from];// 从数据库读取
        chatModel.jid = message.from;
        chatModel.body = message.body;
        chatModel.time = [[NSDate date] timeIntervalSince1970];
        chatModel.isGroup = NO;
        chatModel.unreadCount++;
        [HYNotification postNotificationName:HYChatDidReceiveMessage object:chatModel];
    }
}
// 在接收了用户在线状态消息后会回调此代理方法
- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    //XMPPPresence 在线/离线
    //presence.from 消息是谁发送过来
    HYLog(@"presence.from %@", presence.from);
}

// 在接收IQ/messag、presence出错时，会回调此代理方法
- (void)xmppStream:(XMPPStream *)sender didReceiveError:(NSXMLElement *)error;
{
    
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
    
}
// 更新我的电子名片成功
- (void)xmppvCardTempModuleDidUpdateMyvCard:(XMPPvCardTempModule *)vCardTempModule
{
    if (self.successBlock) {
        self.successBlock(YES);
        self.successBlock = nil;
    }
}
// 更新我的电子名片失败
- (void)xmppvCardTempModule:(XMPPvCardTempModule *)vCardTempModule failedToUpdateMyvCard:(NSXMLElement *)error
{
    if (self.successBlock) {
        self.successBlock(YES);
        self.successBlock = nil;
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

#pragma mark 获得离线消息的时间

-(NSDate *)getDelayStampTime:(XMPPMessage *)message{
    //获得xml中的delay元素
    XMPPElement *delay=(XMPPElement *)[message elementsForName:@"delay"];
    if (delay == nil) {
        return nil;
    }
    //获得时间戳
    NSString *timeString=[[ (XMPPElement *)[message elementForName:@"delay"] attributeForName:@"stamp"] stringValue];
    //创建日期格式构造器
    NSDateFormatter *formatter=[[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    //按照T 把字符串分割成数组
    NSArray *arr=[timeString componentsSeparatedByString:@"T"];
    //获得日期字符串
    NSString *dateStr=[arr objectAtIndex:0];
    //获得时间字符串
    NSString *timeStr=[[[arr objectAtIndex:1] componentsSeparatedByString:@"."] objectAtIndex:0];
    //构建一个日期对象 这个对象的时区是0
    NSDate *localDate=[formatter dateFromString:[NSString stringWithFormat:@"%@T%@+0000",dateStr,timeStr]];
    return localDate;
    
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
