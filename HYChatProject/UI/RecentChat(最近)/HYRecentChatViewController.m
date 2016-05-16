//
//  HYRecentContactsViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/3/20.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYRecentChatViewController.h"
#import "HYRecentChatViewCell.h"
#import "HYRecentChatModel.h"
#import "HYXMPPManager.h"
#import "HYDatabaseHandler+HY.h"
#import "HYUtils.h"
#import "HYLoginInfo.h"
#import "HYSingleChatViewController.h"
#import "HYGroupChatViewController.h"
#import "HYSearchController.h"
#import "HYRecentSearchResultsController.h"

@interface HYRecentChatViewController ()<UITableViewDataSource, UITableViewDelegate,UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataSource; // 模型数据
@property (nonatomic, assign) NSInteger unreadCount; // 消息未读数
@property (nonatomic, strong) HYSearchController *searchController;
@property (nonatomic, strong) HYRecentSearchResultsController *resultsController;
@end

@implementation HYRecentChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    // 搜索
    self.resultsController = [[HYRecentSearchResultsController alloc] init];
    self.searchController = [[HYSearchController alloc] initWithSearchResultsController:self.resultsController];
    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;
    [self.searchController.searchBar sizeToFit];
    self.searchController.searchBar.delegate = self; // so we can monitor text changes + others
    self.definesPresentationContext = YES;// know where you want UISearchController to be displayed
    self.tableView.tableHeaderView = self.searchController.searchBar;
    [self.view addSubview:self.tableView];
    // 加载最近联系人
    [self loadRecentChatDataSource];
    // 注册通知
    [HYNotification addObserver:self selector:@selector(receiveRecentMessage:) name:HYChatDidReceiveMessage object:nil];
    [HYNotification addObserver:self selector:@selector(chatWithSomebody:) name:HYChatWithSomebody object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    XMPPStream *stream = [HYXMPPManager sharedInstance].xmppStream;
    if ([stream isConnected] || [stream isConnecting]) {
        return;
    } else {
        [[HYXMPPManager sharedInstance] xmppUserLogin:nil];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.searchController.active = NO; // 当view消失后取消搜索的激活状态
}

#pragma mark - 更新搜索结果 UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSMutableArray *searchResults = [NSMutableArray array];
    [self.dataSource enumerateObjectsUsingBlock:^(HYRecentChatModel *chatModel, NSUInteger idx, BOOL *stop) {
        if ([chatModel.jid.user containsString:self.searchController.searchBar.text] || [chatModel.nickName containsString:self.searchController.searchBar.text]) {
            [searchResults addObject:chatModel];
        }
    }];
    HYRecentSearchResultsController *tableController = (HYRecentSearchResultsController *)self.searchController.searchResultsController;
    tableController.searchResults = searchResults;//传递搜索结果
    [tableController.tableView reloadData];
}

#pragma mark - UISearchBarDelegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

#pragma mark - UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HYRecentChatModel *chatModel = [self.dataSource objectAtIndex:indexPath.row];
    HYRecentChatViewCell *cell = [HYRecentChatViewCell cellWithTableView:tableView];
    cell.rightButtons = [self rightButtonsWithUnreadCount:chatModel.unreadCount];
    cell.allowsButtonsWithDifferentWidth = YES;
    cell.chatModel = chatModel;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    HYRecentChatModel *chatModel = [self.dataSource objectAtIndex:indexPath.row];
    if (chatModel.isGroup) { // 群聊
        HYGroupChatViewController *groupVC = [[HYGroupChatViewController alloc] init];
        groupVC.roomJid = chatModel.jid;
        groupVC.hidesBottomBarWhenPushed = YES; // 隐藏tabBar
        [self.navigationController pushViewController:groupVC animated:YES];
    }else{
        HYSingleChatViewController *singleVC = [[HYSingleChatViewController alloc] init];
        singleVC.chatJid = chatModel.jid;
        singleVC.hidesBottomBarWhenPushed = YES; // 隐藏tabBar
        [self.navigationController pushViewController:singleVC animated:YES];
    }
}

- (NSArray *)rightButtonsWithUnreadCount:(NSInteger)unreadCount
{
    NSMutableArray *result = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    MGSwipeButton *delButton = [MGSwipeButton buttonWithTitle:@"删除" backgroundColor:[UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f] padding:15.0 callback:^BOOL(MGSwipeTableCell * sender){
        weakSelf.unreadCount -= unreadCount;
        NSIndexPath *indexPath = [weakSelf.tableView indexPathForCell:sender];
        [weakSelf deleteChatModelAtIndexPath:indexPath];
        return YES;
    }];
    
    NSString *markTitle = unreadCount ? @"标为已读" : @"标为未读";
    MGSwipeButton *markButton = [MGSwipeButton buttonWithTitle:markTitle backgroundColor:[UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0] padding:10.0 callback:^BOOL(MGSwipeTableCell * sender){
        NSIndexPath *indexPath = [weakSelf.tableView indexPathForCell:sender];
        HYRecentChatModel *chatModel = [weakSelf.dataSource objectAtIndex:indexPath.row];
        if ([markTitle isEqualToString:@"标为已读"]) {
            weakSelf.unreadCount -= unreadCount;
            chatModel.unreadCount = 0;
        } else {
            weakSelf.unreadCount += 1;
            chatModel.unreadCount = 1;
        }
        [weakSelf updateChatModel:chatModel atIndexPath:indexPath]; // 更新数据
        return YES;
    }];
    [result addObject:delButton];
    [result addObject:markButton];
    
    return result;
}

#pragma mark - 接收到消息通知

- (void)receiveRecentMessage:(NSNotification *)noti
{
    HYRecentChatModel *chatModel = noti.object;
    NSString *nickName = [[HYLoginInfo sharedInstance].nickNameDict objectForKey:chatModel.jid.bare];
    chatModel.nickName = nickName.length ? nickName : chatModel.jid.user;
    NSInteger found = NSNotFound;
    NSString *chatBare = [[HYXMPPManager sharedInstance].chatJID bare];
    for (NSInteger index = 0; index < self.dataSource.count; index++) {
        HYRecentChatModel *model = [self.dataSource objectAtIndex:index];
        if (chatBare.length && [[model.jid bare] isEqualToString:chatBare]) {
            found = index;
            chatModel.unreadCount = 0;
            NSIndexPath *currentIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
            NSIndexPath *toIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [self moveChatModel:chatModel fromIndexPath:currentIndexPath toIndexPath:toIndexPath]; // 更新数据
            break;
        } else if ([[model.jid bare] isEqualToString:[chatModel.jid bare]]) { // 已在列表中
            found = index;
            if (chatModel.unreadCount != 0) { // 如果等于0,说明是自己发送的消息
                self.unreadCount += 1; // 未读数+1
            }
            NSIndexPath *currentIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
            NSIndexPath *toIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [self moveChatModel:chatModel fromIndexPath:currentIndexPath toIndexPath:toIndexPath]; // 更新数据
            break;
        }
    }
    if (found == NSNotFound) {
        if (chatBare.length && [[chatModel.jid bare] isEqualToString:chatBare]) {
            [self insertChatModel:chatModel atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];// 插入数据
        } else {
            if (chatModel.unreadCount != 0) { // 如果等于0,说明是自己发送的消息
                self.unreadCount += 1; // 未读数+1
            }
            [self insertChatModel:chatModel atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];// 插入数据
        }
    }
    
}

#pragma mark - 操作数据
/**
 *  更新数据
 */
- (void)updateChatModel:(HYRecentChatModel *)chatModel atIndexPath:(NSIndexPath *)indexPath
{
    [[HYDatabaseHandler sharedInstance] updateRecentChatModel:chatModel];
    [self.dataSource replaceObjectAtIndex:indexPath.row withObject:chatModel];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}
/**
 *  插入数据
 */
- (void)insertChatModel:(HYRecentChatModel *)chatModel atIndexPath:(NSIndexPath *)indexPath
{
    [[HYDatabaseHandler sharedInstance] insertRecentChatModel:chatModel]; // 插入数据
    [self.dataSource insertObject:chatModel atIndex:indexPath.row];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}
/**
 *  移动数据
 */
- (void)moveChatModel:(HYRecentChatModel *)chatModel fromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    
    [[HYDatabaseHandler sharedInstance] updateRecentChatModel:chatModel]; // 更新数据库数据
    [self.dataSource removeObjectAtIndex:fromIndexPath.row];
    [self.dataSource insertObject:chatModel atIndex:toIndexPath.row];
    [self.tableView moveRowAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
    [self.tableView reloadRowsAtIndexPaths:@[toIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

/**
 *  删除数据
 */
- (void)deleteChatModelAtIndexPath:(NSIndexPath *)indexPath
{
    HYRecentChatModel *chatModel = [self.dataSource objectAtIndex:indexPath.row];
    [[HYDatabaseHandler sharedInstance] deleteRecentChatModel:chatModel];
    [self.dataSource removeObjectAtIndex:indexPath.row];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - 未读消息数
/**
 *  设置未读消息
 */
- (void)setUnreadCount:(NSInteger)unreadCount
{
    _unreadCount = MAX(0, unreadCount);
    self.navigationController.tabBarItem.badgeValue = [HYUtils stringFromUnreadCount:_unreadCount];
    [UIApplication sharedApplication].applicationIconBadgeNumber = _unreadCount;
}


#pragma mark - 加载最近联系人
/**
 *  加载最近联系人
 */
- (void)loadRecentChatDataSource
{
    [[HYDatabaseHandler sharedInstance] recentChatModels:self.dataSource];
    [self.dataSource enumerateObjectsUsingBlock:^(HYRecentChatModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *nickName = [[HYLoginInfo sharedInstance].nickNameDict objectForKey:obj.jid.bare];
        obj.nickName = nickName.length ? nickName : obj.jid.user;
        self.unreadCount += obj.unreadCount; // 获得所有未读消息数
    }];

}

#pragma mark - 接收进入聊天界面通知

- (void)chatWithSomebody:(NSNotification *)noti
{
    XMPPJID *chatJid = noti.object;
    NSInteger count = self.dataSource.count;
    for (NSInteger index = 0; index < count; index++) {
        HYRecentChatModel *chatModel = [self.dataSource objectAtIndex:index];
        if ([chatModel.jid.bare isEqualToString:chatJid.bare]) {
            self.unreadCount -= chatModel.unreadCount;
            chatModel.unreadCount = 0;
            [self updateChatModel:chatModel atIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        }
    }
}

#pragma mark - 懒加载
- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.rowHeight = kRecentChatViewCellHeight;
        _tableView.dataSource = self;
        _tableView.delegate = self;
    }
    return _tableView;
}

- (NSMutableArray *)dataSource
{
    if (_dataSource == nil) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

- (void)dealloc
{
    [HYNotification removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
