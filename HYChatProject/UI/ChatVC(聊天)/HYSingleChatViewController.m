//
//  HYSingleChatViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/3/20.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYSingleChatViewController.h"
#import "HYInputViewController.h"
#import "HYChatMessageFrame.h"
#import "HYXMPPManager.h"
#import "GJCFAudioModel.h"
#import "GJCFAudioManager.h"
#import "GJCFAudioPlayer.h"
#import "GJCFCachePathManager.h"
#import "HYUtils.h"
#import "HYDatabaseHandler+HY.h"
#import "AFNetworking.h"

#import "HYBaseChatViewCell.h"
#import "HYTextChatViewCell.h"
#import "HYImageChatViewCell.h"
#import "HYAudioChatViewCell.h"
#import "HYVideoChatViewCell.h"

static NSString *kTextChatViewCellIdentifier = @"kTextChatViewCellIdentifier";
static NSString *kImageChatViewCellIdentifier = @"kImageChatViewCellIdentifier";
static NSString *kAudioChatViewCellIdentifier = @"kAudioChatViewCellIdentifier";
static NSString *kVideoChatViewCellIdentifier = @"kVideoChatViewCellIdentifier";
@interface HYSingleChatViewController ()<UITableViewDataSource, UITableViewDelegate,NSFetchedResultsControllerDelegate, HYInputViewControllerDelegate, HYBaseChatViewCellDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) HYInputViewController *inputVC;
@property (nonatomic, strong) NSFetchedResultsController *resultController;//查询结果集合

@property (nonatomic, strong) GJCFAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSString *playingAudioMsgId;// 当前播放的消息
@end

@implementation HYSingleChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    // 1.tableView
    [self.tableView registerClass:[HYTextChatViewCell class] forCellReuseIdentifier:kTextChatViewCellIdentifier];
    [self.tableView registerClass:[HYImageChatViewCell class] forCellReuseIdentifier:kImageChatViewCellIdentifier];
    [self.tableView registerClass:[HYAudioChatViewCell class] forCellReuseIdentifier:kAudioChatViewCellIdentifier];
    [self.tableView registerClass:[HYVideoChatViewCell class] forCellReuseIdentifier:kVideoChatViewCellIdentifier];
    
    [self.view addSubview:self.tableView];
    
    // 2.聊天工具条
    self.inputVC = [[HYInputViewController alloc] init];
    self.inputVC.delegate = self;
    self.inputVC.view.frame = CGRectMake(0, CGRectGetHeight(self.view.bounds) - kInputBarHeight, CGRectGetWidth(self.view.bounds), kInputBarHeight);
    [self.view addSubview:self.inputVC.view];
    
    // 3.设置当前聊天对象
    [HYXMPPManager sharedInstance].chatJID = self.chatJid;
    
    // 4.获取聊天数据
     [self getChatHistory];
    
    
    // 5.监听网络状态改变
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status == AFNetworkReachabilityStatusNotReachable) { // 网络不可用
            
        }
    }];
    
    // 6.音频
    __weak typeof(self) weakSelf = self;
    [[GJCFAudioManager shareManager] setCurrentAudioPlayFinishedBlock:^(NSString *uniqueIdentifier) {
        [weakSelf stopPlayAudioWithUniqueIdentifier:uniqueIdentifier];
    }];
    
    // 7.注册通知
    [HYNotification addObserver:self selector:@selector(receiveSingleMessage:) name:HYChatDidReceiveSingleMessage object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // 自动滚动表格到最后一行
    CGRect section = [self.tableView rectForSection:0];
    CGFloat offsetY = section.size.height - (CGRectGetHeight(self.view.bounds) - CGRectGetHeight(self.inputVC.view.frame));
    if (offsetY > 0) {
        [self.tableView setContentOffset:CGPointMake(0, offsetY) animated:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self controlKeyboard];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HYBaseChatViewCell *cell = nil;
    HYChatMessageFrame *messageFrame = [self.dataSource objectAtIndex:indexPath.row];
    HYChatMessage *message = messageFrame.chatMessage;
    switch (message.type) {
        case HYChatMessageTypeText:{
            cell = [tableView dequeueReusableCellWithIdentifier:kTextChatViewCellIdentifier];
            break;
        }
        case HYChatMessageTypeImage:{
            cell = [tableView dequeueReusableCellWithIdentifier:kImageChatViewCellIdentifier];
            break;
        }
        case HYChatMessageTypeAudio:{
            cell = [tableView dequeueReusableCellWithIdentifier:kAudioChatViewCellIdentifier];
            break;
        }
        case HYChatMessageTypeVideo:{
            cell = [tableView dequeueReusableCellWithIdentifier:kVideoChatViewCellIdentifier];
            break;
        }
        default:
            break;
    }
    cell.messageFrame = messageFrame;
    cell.delegate = self;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HYChatMessageFrame *messageFrame = [self.dataSource objectAtIndex:indexPath.row];
    return messageFrame.cellHeight;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    UIMenuController *popMenu = [UIMenuController sharedMenuController];
    if (popMenu.isMenuVisible) {
        [popMenu setMenuVisible:NO animated:YES];
    }
    if (self.inputVC.isFirstResponder) {
        [self.inputVC resignFirstResponder]; // 输入框取消第一响应者
        [self controlKeyboard];
    }
    
}

#pragma mark - 获取聊天数据

- (void)getChatHistory
{
    NSMutableArray *chatMessages = [NSMutableArray array];
    [[HYDatabaseHandler sharedInstance] recentChatMessages:chatMessages fromChatJID:self.chatJid];
    // 处理数据
    [chatMessages enumerateObjectsUsingBlock:^(HYChatMessage *message, NSUInteger idx, BOOL * _Nonnull stop) {
        // 判断是否显示时间
        message.timeString = [HYUtils timeStringSince1970:message.time];
        HYChatMessageFrame *lastMessageFrame = [self.dataSource lastObject];
        message.isHidenTime = [lastMessageFrame.chatMessage.timeString isEqualToString:message.timeString];
        HYChatMessageFrame *messageFrame = [[HYChatMessageFrame alloc] init];
        messageFrame.chatMessage = message;
        [self.dataSource addObject:messageFrame];
    }];
}

// 获取更多数据
- (void)loadMoreChatMessage
{
    
}

/**
 *  自动滚动表格到最后一行
 */
- (void)scrollToBottom
{
    if (self.dataSource.count) {
        NSIndexPath *lastPath = [NSIndexPath indexPathForRow:self.dataSource.count - 1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:lastPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

#pragma mark - 发送inputViewControllerDDelegate

- (void)inputViewController:(HYInputViewController *)inputViewController sendText:(NSString *)text
{
    //发送消息
    HYChatMessage *message = [[HYChatMessage alloc] init];
    message.type = HYChatMessageTypeText;
    message.textMessage = text;
    [[HYXMPPManager sharedInstance] sendText:[message jsonString] toJid:self.chatJid];
}

- (void)inputViewController:(HYInputViewController *)inputViewController sendAudioModel:(GJCFAudioModel *)audioModel
{
    HYChatMessage *message = [[HYChatMessage alloc] init];
    message.type = HYChatMessageTypeAudio;
    message.audioModel = audioModel;
    __weak typeof(self) weakSelf = self;
    [[GJCFAudioManager shareManager] startUploadAudioFile:audioModel successBlock:^(BOOL success) {
        if(success){ // 上传音频文件成功
            [[HYXMPPManager sharedInstance] sendText:[message jsonString] toJid:weakSelf.chatJid];
        } else {
            
        }
    }];
}

- (void)inputViewController:(HYInputViewController *)inputViewController newHeight:(CGFloat)height
{
    self.tableView.contentInset = UIEdgeInsetsMake(64, 0, height, 0);
    [self scrollToBottom];
}


#pragma mark - HYBaseChatViewCellDelegate
// 点击音频
- (void)chatViewCellClickAudio:(HYBaseChatViewCell *)chatViewCell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:chatViewCell];
    HYChatMessageFrame *messageFrame = [self.dataSource objectAtIndex:indexPath.row];
    HYChatMessage *message = messageFrame.chatMessage;
    if ([self.playingAudioMsgId isEqualToString:message.messageID]) { // 当前播放
        [[GJCFAudioManager shareManager] stopPlayCurrentAudio];// 停止播放
        message.isRead = YES;
        message.isPlayingAudio = NO;
    } else {
        self.playingAudioMsgId = message.messageID;
        [[GJCFAudioManager shareManager] stopPlayCurrentAudio];// 停止播放
        [[GJCFAudioManager shareManager] playRemoteAudioFileByUrl:message.audioModel.remotePath];
        message.isRead = YES;
        message.isPlayingAudio = YES;
    }
    [self.dataSource replaceObjectAtIndex:indexPath.row withObject:messageFrame];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

// 停止播放
- (void)stopPlayAudioWithUniqueIdentifier:(NSString *)uniqueIdentifier
{
    NSInteger count = self.dataSource.count;
    for (NSInteger index = 0; index < count; index++) {
        HYChatMessageFrame *messageFrame = [self.dataSource objectAtIndex:index];
        HYChatMessage *message = messageFrame.chatMessage;
        if ([message.audioModel.uniqueIdentifier isEqualToString:uniqueIdentifier]) {
            message.isPlayingAudio = NO;
            [self.dataSource replaceObjectAtIndex:index withObject:messageFrame];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            return; // 返回
        }
    }
}

// 点击图片
- (void)chatViewCellClickImage:(HYBaseChatViewCell *)chatViewCell
{
    
}

// 点击视频
- (void)chatViewCellClickVideo:(HYBaseChatViewCell *)chatViewCell
{
    
}

// 点击头像
- (void)chatViewCell:(HYBaseChatViewCell *)chatViewCell didClickHeaderWithJid:(XMPPJID *)jid
{
    
}
// 删除消息
- (void)chatViewCellDelete:(HYBaseChatViewCell *)chatViewCell
{
    
}

// 转发
- (void)chatViewCellForward:(HYBaseChatViewCell *)chatViewCell
{
    
}

// 重发
- (void)chatViewCellReSend:(HYBaseChatViewCell *)chatViewCell
{
    
}


/**
 *  控制keyboard显示
 */
- (void)controlKeyboard
{
    CGRect section = [self.tableView rectForSection:0];
    CGFloat h = CGRectGetHeight(self.view.bounds) - 64 - section.size.height;
    if (h > kPanelHeight) {
        self.inputVC.onlyMoveKeyboard = YES;// 数据太少就不整体向上移动
    } else {
        self.inputVC.onlyMoveKeyboard = NO;// 整体向上移动
    }
}

#pragma mark - 接收消息通知

- (void)receiveSingleMessage:(NSNotification *)noti
{
    HYChatMessage *message = noti.object;
    if (![message.jid.bare isEqualToString:self.chatJid.bare]) {
        return;
    }
    // 判断是否显示时间
    message.timeString = [HYUtils timeStringSince1970:message.time];
    HYChatMessageFrame *lastMessageFrame = [self.dataSource lastObject];
    message.isHidenTime = [lastMessageFrame.chatMessage.timeString isEqualToString:message.timeString];
    HYChatMessageFrame *messageFrame = [[HYChatMessageFrame alloc] init];
    messageFrame.chatMessage = message;
    [self.dataSource addObject:messageFrame];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.dataSource.count - 1 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self scrollToBottom];
}

#pragma mark - 懒加载
- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.dataSource = self;
        _tableView.delegate = self;
    }
    return _tableView;
}

// 懒加载
- (NSMutableArray *)dataSource
{
    if (_dataSource == nil) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

- (void)dealloc
{
    self.dataSource = nil;
    self.inputVC = nil;
    [HYXMPPManager sharedInstance].chatJID = nil;
    [HYNotification removeObserver:self];
    HYLog(@"%@-dealloc",self);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 - (void)getChatHistory
 {
 // 1.上下文
 NSManagedObjectContext *context = [[HYXMPPManager sharedInstance] managedObjectContext_messageArchiving];
 if (context == nil) { // 防止xmppStream没有连接会崩溃
 return;
 }
 // 2.Fetch请求
 NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"XMPPMessageArchiving_Message_CoreDataObject"];
 // 3.过滤
 NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bareJidStr == %@ AND streamBareJidStr == %@",self.chatJid.bare, [HYXMPPManager sharedInstance].myJID.bare];
 [fetchRequest setPredicate:predicate];
 // 4.排序(降序)
 NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
 [fetchRequest setSortDescriptors:@[sortDescriptor]];
 //    [fetchRequest setFetchLimit:20]; // 分页
 //    [fetchRequest setFetchOffset:0];
 
 // 5.执行查询获取数据
 _resultController = [[NSFetchedResultsController alloc]initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
 _resultController.delegate=self;
 // 6.执行
 NSError *error=nil;
 if(![_resultController performFetch:&error]){
 HYLog(@"%s---%@",__func__,error);
 } else {
 [self.dataSource removeAllObjects];
 [_resultController.fetchedObjects enumerateObjectsUsingBlock:^(XMPPMessageArchiving_Message_CoreDataObject *object, NSUInteger idx, BOOL * _Nonnull stop) {
 HYChatMessageFrame *messageFrame = [self chatmessageFrameFromObject:object];
 [self.dataSource addObject:messageFrame]; // 添加到数据源
 }];
 }
 }
 
 #pragma mark - NSFetchedResultsControllerDelegate
 // 数据更新
 - (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(nullable NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(nullable NSIndexPath *)newIndexPath
 {
 XMPPMessageArchiving_Message_CoreDataObject *object = anObject;
 if (object.body.length == 0) return; // 如果body为空，返回
 HYChatMessageFrame *messageFrame = [self chatmessageFrameFromObject:object];
 switch (type) {
 case NSFetchedResultsChangeInsert:{ // 插入
 [self.dataSource addObject:messageFrame];
 [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.dataSource.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
 [self scrollToBottom];
 break;
 }
 case NSFetchedResultsChangeDelete:{ // 删除
 [self.dataSource removeObjectAtIndex:indexPath.row];
 [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
 break;
 }
 case NSFetchedResultsChangeMove:{ // 移动
 break;
 }
 case NSFetchedResultsChangeUpdate:{ // 更新
 [self.dataSource replaceObjectAtIndex:indexPath.row withObject:messageFrame];
 [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
 break;
 }
 default:
 break;
 }
 }
 
 #pragma mark - 转换模型
 
 - (HYChatMessageFrame *)chatmessageFrameFromObject:(XMPPMessageArchiving_Message_CoreDataObject *)object
 {
 HYChatMessage *message = [[HYChatMessage alloc] initWithJsonString:object.body];
 XMPPJID *jid = nil;
 if (object.isOutgoing) { // 发送
 jid = [HYXMPPManager sharedInstance].myJID;
 } else { // 接收
 jid = self.chatJid;
 }
 message.jid = jid;
 message.isOutgoing = object.isOutgoing;
 message.timeString = [HYUtils timeStringFromDate:object.timestamp];
 // 判断是否显示时间
 HYChatMessageFrame *lastMessageFrame = [self.dataSource lastObject];
 message.isHidenTime = [lastMessageFrame.chatMessage.timeString isEqualToString:message.timeString];
 // 计算message的Frame
 HYChatMessageFrame *messageFrame = [[HYChatMessageFrame alloc] init];
 messageFrame.chatMessage = message;
 return messageFrame;
 }
 */

@end
