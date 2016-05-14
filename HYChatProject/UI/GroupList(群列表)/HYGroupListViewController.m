//
//  HYGroupListViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/5/1.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "HYGroupListViewController.h"
#import "HYGroupChatViewController.h"
#import "HYXMPPRoomManager.h"
#import "HYContactsModel.h"
#import "HYGroupListViewCell.h"
#import "XMPPRoom.h"
#import "HYGroupSearchListController.h"
#import "HYSearchController.h"
#import "HYAddFriendViewController.h"

@interface HYGroupListViewController ()<UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating>
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *dataSource;
@property (nonatomic, strong) HYSearchController *searchController;
@property (nonatomic, strong) HYGroupSearchListController *resultsController;

@end

@implementation HYGroupListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"聊天室";
    self.view.backgroundColor = [UIColor whiteColor];
    // 搜索
    self.resultsController = [[HYGroupSearchListController alloc] init];
    self.searchController = [[HYSearchController alloc] initWithSearchResultsController:self.resultsController];
    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;
    [self.searchController.searchBar sizeToFit];
    self.searchController.searchBar.delegate = self; // so we can monitor text changes + others
    self.definesPresentationContext = YES;// know where you want UISearchController to be displayed
    self.tableView.tableHeaderView = self.searchController.searchBar;
    [self.view addSubview:self.tableView];
    // 获得房间列表
    [self reloadData:nil];
    // 创建/添加房间
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createRoom:)];
    // 通知
    [HYNotification addObserver:self selector:@selector(reloadData:) name:HYChatJoinOrCreateGroup object:nil];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.dataSource.count == 0) {
        // 加载房间列表
        __weak typeof(self) weakSelf = self;
        [[HYXMPPRoomManager sharedInstance] fetchBookmarkedRooms:^(NSArray *bookmarkedRooms) {
            [bookmarkedRooms enumerateObjectsUsingBlock:^(XMPPRoom *room, NSUInteger idx, BOOL * _Nonnull stop) {
                HYContactsModel *model = [[HYContactsModel alloc] init];
                model.jid = room.roomJID;
                model.displayName = room.roomJID.user;
                model.isGroup = YES;
                [self.dataSource addObject:model];
            }];
            [weakSelf.tableView reloadData];
        }];
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
    [self.dataSource enumerateObjectsUsingBlock:^(HYContactsModel *model, NSUInteger idx, BOOL *stop) {
        if ([model.jid.user containsString:self.searchController.searchBar.text]) {
            [searchResults addObject:model];
        }
    }];
    HYGroupSearchListController *tableController = (HYGroupSearchListController *)self.searchController.searchResultsController;
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
    return self.dataSource.count;;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HYGroupListViewCell *cell = [HYGroupListViewCell cellWithTableView:tableView];
    HYContactsModel *model = [self.dataSource objectAtIndex:indexPath.row];
    cell.model = model;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    HYGroupChatViewController *groupChat = [[HYGroupChatViewController alloc] init];
    HYContactsModel *model = [self.dataSource objectAtIndex:indexPath.row];
    groupChat.roomJid = model.jid;
    [self.navigationController pushViewController:groupChat animated:YES];
}

/*
- (void)loadRooms
{
    //1.上下文   XMPPRoster.xcdatamodel
    NSManagedObjectContext *context = [[HYXMPPRoomManager sharedInstance] managedObjectContext_room];
    if (context == nil) { // 防止xmppStream没有连接会崩溃
        return;
    }
    //2.Fetch请求
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"XMPPRoomOccupantCoreDataStorageObject"];
    //3.排序和过滤
    NSPredicate *pre=[NSPredicate predicateWithFormat:@"streamBareJidStr == %@",[HYXMPPRoomManager sharedInstance].xmppStream.myJID.bare];
    fetchRequest.predicate=pre;
    //
    NSSortDescriptor *sort=[NSSortDescriptor sortDescriptorWithKey:@"roomJIDStr" ascending:YES];
    fetchRequest.sortDescriptors=@[sort];
    
    //4.执行查询获取数据
    _resultController = [[NSFetchedResultsController alloc]initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    _resultController.delegate=self;
    //执行
    NSError *error=nil;
    if(![_resultController performFetch:&error]){
        HYLog(@"%s---%@",__func__,error);
    } else {
        [self.dataSource removeAllObjects];
        [_resultController.fetchedObjects enumerateObjectsUsingBlock:^(XMPPRoomOccupantCoreDataStorageObject *object, NSUInteger idx, BOOL * _Nonnull stop) {
            HYContactsModel *model = [[HYContactsModel alloc] init];
            model.jid = object.roomJID;
            model.displayName = object.roomJID.user;
            model.isGroup = YES;
            [self.dataSource addObject:model];
        }];
    }
    
}
*/

#pragma mark - 创建/加入房间
- (void)createRoom:(id)sender
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"添加或者创建聊天室" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *addAction = [UIAlertAction actionWithTitle:@"加入聊天室" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        HYAddFriendViewController *addFriendVC = [[HYAddFriendViewController alloc] init];
        addFriendVC.type = HYAddFriendTypeGroup;
        [self.navigationController pushViewController:addFriendVC animated:YES];
    }];
    UIAlertAction *createAction = [UIAlertAction actionWithTitle:@"创建聊天室" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        HYAddFriendViewController *addFriendVC = [[HYAddFriendViewController alloc] init];
        addFriendVC.type = HYAddFriendTypeCreateGroup;
        [self.navigationController pushViewController:addFriendVC animated:YES];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:addAction];
    [alert addAction:createAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)reloadData:(NSNotification *)noti
{
    // 获取数据
    NSArray *bookmarkedRooms = [HYXMPPRoomManager sharedInstance].bookmarkedRooms;
    [self.dataSource removeAllObjects];
    [bookmarkedRooms enumerateObjectsUsingBlock:^(XMPPRoom *room, NSUInteger idx, BOOL * _Nonnull stop) {
        HYContactsModel *model = [[HYContactsModel alloc] init];
        model.jid = room.roomJID;
        model.displayName = room.roomJID.user;
        model.isGroup = YES;
        [self.dataSource addObject:model];
    }];
    if (noti) { // 如果获得通知
        [self.tableView reloadData];
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
        _tableView.rowHeight = kGroupListViewCellHeight;
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
    [HYNotification removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
