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
    
    // 2.获取数据
    NSArray *bookmarkedRooms = [HYXMPPRoomManager sharedInstance].bookmarkedRooms;
    [bookmarkedRooms enumerateObjectsUsingBlock:^(XMPPRoom *room, NSUInteger idx, BOOL * _Nonnull stop) {
        HYContactsModel *model = [[HYContactsModel alloc] init];
        model.jid = room.roomJID;
        model.displayName = room.roomJID.user;
        model.isGroup = YES;
        [self.dataSource addObject:model];
    }];
    // 3.创建/添加房间
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createRoom:)];
    
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

#pragma mark - 创建/加入房间
- (void)createRoom:(id)sender
{
    
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
