//
//  HYNewFriendViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/5/1.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYNewFriendViewController.h"
#import "HYNewFriendViewCell.h"
#import "HYNewFriendModel.h"
#import "HYDatabaseHandler+HY.h"
#import "HYSingleChatViewController.h"
#import "HYAddFriendViewController.h"

@interface HYNewFriendViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataSource;
@end

@implementation HYNewFriendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"新朋友";
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    [[HYDatabaseHandler sharedInstance] allNewFriends:self.dataSource];// 获取数据
    if (self.dataSource.count == 0) { // 没有记录，显添加好友
        UIView *moreView = [[UIView alloc] initWithFrame:self.view.bounds];
        moreView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:moreView];
        
        UILabel *tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, CGRectGetWidth(moreView.bounds) - 40, 28)];
        tipLabel.font = [UIFont systemFontOfSize:15];
        tipLabel.textColor = [UIColor blackColor];
        tipLabel.text = @"最近没有添加新的好友哦！点击添加好友";
        tipLabel.textAlignment = NSTextAlignmentCenter;
        [moreView addSubview:tipLabel];
        
        UIButton *addButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(moreView.bounds) * 0.25, CGRectGetMaxY(tipLabel.frame) + 22, CGRectGetWidth(moreView.bounds) * 0.5, 36)];
        addButton.backgroundColor = COLOR(200, 200, 200, 1.0f);
        [addButton setTitle:@"添加好友" forState:UIControlStateNormal];
        [addButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [addButton addTarget:self action:@selector(addButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        addButton.layer.cornerRadius = 2;
        addButton.layer.masksToBounds = YES;
        [moreView addSubview:addButton];
    }
}


#pragma mark - UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HYNewFriendViewCell *cell = [HYNewFriendViewCell cellWithTableView:tableView];
    HYNewFriendModel *model = [self.dataSource objectAtIndex:indexPath.row];
    cell.friendModel = model;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    HYSingleChatViewController *singleChat = [[HYSingleChatViewController alloc] init];
    HYNewFriendModel *model = [self.dataSource objectAtIndex:indexPath.row];
    singleChat.chatJid = model.jid;
    [self.navigationController pushViewController:singleChat animated:YES];
}

- (void)addButtonClick:(UIButton *)sender
{
    HYAddFriendViewController *addFriend = [[HYAddFriendViewController alloc] init];
    [self.navigationController pushViewController:addFriend animated:YES];
}

#pragma mark - 懒加载

- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.rowHeight = kNewFriendViewCellHeight;
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
