//
//  HYXMPPManager.m
//  HYChatProject
//
//  Created by erpapa on 16/4/20.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYXMPPManager.h"
#import "HYUserInfo.h"
#import "HYUtils.h"

NSString *const HYConnectStatusDidChangeNotification = @"HYConnectStatusDidChangeNotification"; // 连接状态变更通知

@interface HYXMPPManager()<XMPPStreamDelegate, XMPPRosterDelegate, XMPPvCardTempModuleDelegate, XMPPvCardAvatarDelegate>
{
    XMPPReconnect *_xmppReconnect;
    XMPPvCardTempModule *_vCardTempModule;//电子名片
    XMPPvCardCoreDataStorage *_vCardStorage;//电子名片的数据存储
    XMPPRoster *_roster;//花名册
    XMPPRosterCoreDataStorage *_rosterStorage;//花名册数据存储
    XMPPvCardAvatarModule *_vCardAvatarModule;//头像
    XMPPMessageArchiving *_messageArchiving;//信息
    XMPPMessageArchivingCoreDataStorage *_messageArchivingStorage;//信息数据存储
}

@property (strong, nonatomic) NSMutableDictionary *vCardBlockDict; // 名片block数组
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
+ (instancetype)sharedManager
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
#warning 每一个模块添加后都要激活
    //添加自动连接模块
    _xmppReconnect = [[XMPPReconnect alloc] init];
    [_xmppReconnect activate:_xmppStream];
    
    //添加电子名片模块
    _vCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
    _vCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:_vCardStorage];
    [_vCardTempModule activate:_xmppStream];
    
    //添加头像模块
    _vCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:_vCardTempModule];
    [_vCardAvatarModule activate:_xmppStream];
    
    
    // 添加花名册模块【获取好友列表】
    _rosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    _roster = [[XMPPRoster alloc] initWithRosterStorage:_rosterStorage];
    [_roster activate:_xmppStream];
    
    // 添加聊天模块
    _messageArchivingStorage = [[XMPPMessageArchivingCoreDataStorage alloc] init];
    _messageArchiving = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:_messageArchivingStorage];
    [_messageArchiving activate:_xmppStream];
    
    _xmppStream.enableBackgroundingOnSocket = YES; // 允许设备在后台运行
    
    // 设置代理
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [_roster addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [_vCardTempModule addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [_vCardAvatarModule addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [_messageArchiving addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
}

#pragma mark -公共方法
// 注销
-(void)xmppUserlogout
{
    // 1." 发送 "离线" 消息"
    XMPPPresence *offline = [XMPPPresence presenceWithType:@"unavailable"];
    [_xmppStream sendElement:offline];
    
    // 2. 与服务器断开连接
    [_xmppStream disconnect];
    
    // 3.更新用户的登录状态
    [HYUserInfo sharedUserInfo].logon = NO;
    [[HYUserInfo sharedUserInfo] saveUserInfoToSanbox];
    
    // 4.切换根控制器
    [HYUtils initRootViewController];
}
// 登录
-(void)xmppUserLogin:(HYXMPPConnectStatusBlock)resultBlock{
    
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
        [self.vCardBlockDict setObject:[myvCardBlock copy] forKey:[HYUserInfo sharedUserInfo].jid];
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
- (void)getvCardFromJID:(XMPPJID *)jid vCardBlock:(HYvCardBlock)vCardBlock
{
    // 如果本地为空，自动从网络获取好友名片
    XMPPvCardTemp *vCardTemp = [_vCardTempModule vCardTempForJID:jid shouldFetch:YES];
    if (vCardTemp) {
        vCardBlock(vCardTemp);
    } else {
        [self.vCardBlockDict setObject:[vCardBlock copy] forKey:jid];
    }
}

#pragma mark 连接到服务器
-(void)connectToHost{
    if (!_xmppStream) {//如果_xmppStream为空，则初始化_xmppStream
        [self setupXMPPStream];
    }
    HYUserInfo *userInfo = [HYUserInfo sharedUserInfo];
    // 设置登录用户JID
    _xmppStream.myJID = userInfo.jid;
    // 设置服务器域名
    _xmppStream.hostName = userInfo.hostName;
    // 设置端口 默认是5222
    _xmppStream.hostPort = userInfo.hostPort;
    // 连接，设置超时为2.0f
    [_xmppStream connectWithTimeout:2.0f error:nil];
    
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
    NSString *pwd = [HYUserInfo sharedUserInfo].password;
    if ([HYUserInfo sharedUserInfo].registerMark) {//注册操作，发送注册的密码
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
    _status = HYXMPPConnectStatusAuthSuccess;
    [self postConnectStatus:HYXMPPConnectStatusAuthSuccess];
    // 回调控制器登录成功
    if(self.connectStatusBlock){
        self.connectStatusBlock(HYXMPPConnectStatusAuthSuccess);
        self.connectStatusBlock = nil;
    }
    XMPPPresence *presence = [XMPPPresence presence];
    [_xmppStream sendElement:presence];
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
- (XMPPIQ *)xmppStream:(XMPPStream *)sender willReceiveIQ:(XMPPIQ *)iq
{
    return nil;
}
// 将要接收到消息时的回调
- (XMPPMessage *)xmppStream:(XMPPStream *)sender willReceiveMessage:(XMPPMessage *)message
{
    return nil;
}
// 将要接收到用户在线状态时的回调
- (XMPPPresence *)xmppStream:(XMPPStream *)sender willReceivePresence:(XMPPPresence *)presence
{
    return nil;
}
// 当xmppStream:willReceiveX:(也就是前面这三个API回调后)，过滤了stanza，会回调此代理方法。
// 通过实现此代理方法，可以知道被过滤的原因，有一定的帮助。
//- (void)xmppStreamDidFilterStanza:(XMPPStream *)sender;

// 在接收了IQ（消息查询后）会回调此代理方法
- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    return YES;
}
// 在接收了消息后会回调此代理方法
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)messag
{
    
}
// 在接收了用户在线状态消息后会回调此代理方法
- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    
}

// 在接收IQ/messag、presence出错时，会回调此代理方法
- (void)xmppStream:(XMPPStream *)sender didReceiveError:(NSXMLElement *)error;
{
    
}


// ######################### 发送消息 #######################

#pragma mark - ####### 发送消息 ########
// 将要发送IQ（消息查询时）时会回调此代理方法
- (XMPPIQ *)xmppStream:(XMPPStream *)sender willSendIQ:(XMPPIQ *)iq
{
    return nil;
}
// 在将要发送消息时，会回调此代理方法
- (XMPPMessage *)xmppStream:(XMPPStream *)sender willSendMessage:(XMPPMessage *)message
{
    return nil;
}
// 在将要发送用户在线状态信息时，会回调此方法
- (XMPPPresence *)xmppStream:(XMPPStream *)sender willSendPresence:(XMPPPresence *)presence
{
    return nil;
}

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
    HYvCardBlock vCardBlock = [self.vCardBlockDict objectForKey:jid];
    if (vCardBlock) {
        vCardBlock(vCardTemp);
        [self.vCardBlockDict removeObjectForKey:jid]; // 删除该键值
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

#pragma mark - 接收到头像 XMPPvCardAvatarModuleDelegate
- (void)xmppvCardAvatarModule:(XMPPvCardAvatarModule *)vCardTempModule
              didReceivePhoto:(UIImage *)photo
                       forJID:(XMPPJID *)jid
{
    
}


#pragma mark - vCardBlockDict

- (NSMutableDictionary *)vCardBlockDict
{
    if (_vCardBlockDict == nil) {
        _vCardBlockDict = [NSMutableDictionary dictionary];
    }
    return _vCardBlockDict;
}

@end
