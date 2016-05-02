//
//  HYSingleChatViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/3/20.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYSingleChatViewController.h"
#import "HYChatMessageFrame.h"
#import "HYInputViewController.h"
#import "HYXMPPManager.h"
#import "HYLoginInfo.h"
#import "HYUtils.h"

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
    [HYXMPPManager sharedInstance].chatJid = self.chatJid;
    
    // 4.获取聊天数据
    [self getChatHistory];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // 自动滚动表格到最后一行
    CGRect section = [self.tableView rectForSection:0];
    self.tableView.contentOffset = CGPointMake(0, section.size.height - (CGRectGetHeight(self.view.bounds) - kInputBarHeight));
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
    }
    
}

#pragma mark - 获取聊天数据
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
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bareJidStr == %@ AND streamBareJidStr == %@",self.chatJid.bare, [HYLoginInfo sharedInstance].jid.bare];
    [fetchRequest setPredicate:predicate];
    // 4.排序(降序)
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
//    [fetchRequest setFetchLimit:20]; // 分页
//    [fetchRequest setFetchOffset:0];
    
    //4.执行查询获取数据
    _resultController = [[NSFetchedResultsController alloc]initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    _resultController.delegate=self;
    //执行
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
/**
 *  数据更新
 */
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
//            [self.dataSource removeObjectAtIndex:indexPath.row];
//            [self.dataSource insertObject:messageFrame atIndex:newIndexPath.row];
//            [self.tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
//            [self.tableView reloadRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
        }
        case NSFetchedResultsChangeUpdate:{ // 更新
            [self.dataSource removeObjectAtIndex:indexPath.row];
            [self.dataSource insertObject:messageFrame atIndex:indexPath.row];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
        }
        default:
            break;
    }
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

#pragma mark - 转换模型

- (HYChatMessageFrame *)chatmessageFrameFromObject:(XMPPMessageArchiving_Message_CoreDataObject *)object
{
    HYChatMessage *message = [[HYChatMessage alloc] initWithJsonString:object.body];
    XMPPJID *jid = nil;
    if (object.isOutgoing) { // 发送
        jid = [HYLoginInfo sharedInstance].jid;
    } else { // 接收
        jid = self.chatJid;
    }
    message.jid = jid;
    message.isOutgoing = object.isOutgoing;
    message.isComposing = object.isComposing;
    message.timeString = [HYUtils timeStringFromDate:object.timestamp];
    // 判断是否显示时间
    HYChatMessageFrame *lastMessageFrame = [self.dataSource lastObject];
    message.isHidenTime = [lastMessageFrame.chatMessage.timeString isEqualToString:message.timeString];
    // 计算message的Frame
    HYChatMessageFrame *messageFrame = [[HYChatMessageFrame alloc] init];
    messageFrame.chatMessage = message;
    return messageFrame;
}
#pragma mark - 发送inputViewControllerDDelegate

- (void)inputViewController:(HYInputViewController *)inputViewController sendMessage:(HYChatMessage *)message
{
    NSString *body = [message jsonString];
    [[HYXMPPManager sharedInstance] sendText:body toJid:self.chatJid success:^(BOOL success) {
        
    }];
}

- (void)inputViewController:(HYInputViewController *)inputViewController newHeight:(CGFloat)height
{
    self.tableView.contentInset = UIEdgeInsetsMake(64, 0, height, 0);
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
    HYLog(@"%@-dealloc",self);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
