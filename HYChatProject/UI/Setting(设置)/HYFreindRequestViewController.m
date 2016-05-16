//
//  HYFreindRequestViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/5/13.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYFreindRequestViewController.h"
#import "HYFriendRequestViewCell.h"
#import "HYUservCardViewController.h"
#import "HYXMPPManager.h"
#import "HYNewFriendModel.h"
#import "HYDatabaseHandler+HY.h"
#import "HYAddFriendViewController.h"

@interface HYFreindRequestViewController ()<UITableViewDataSource,UITableViewDelegate,HYFriendRequestViewCellDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataSource;
@end

@implementation HYFreindRequestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"好友请求";
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    [[HYDatabaseHandler sharedInstance] allRequestFriends:self.dataSource];// 获取数据
    if (self.dataSource.count == 0) { // 没有记录，显添加好友
        UIView *moreView = [[UIView alloc] initWithFrame:self.view.bounds];
        moreView.backgroundColor = COLOR(241, 241, 241, 1.0);
        [self.view addSubview:moreView];
        
        UILabel *tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, CGRectGetWidth(moreView.bounds) - 40, 28)];
        tipLabel.font = [UIFont systemFontOfSize:15];
        tipLabel.textColor = [UIColor blackColor];
        tipLabel.text = @"最近没有好友请求！点击添加好友";
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
    HYFriendRequestViewCell *cell = [HYFriendRequestViewCell cellWithTableView:tableView];
    HYNewFriendModel *model = [self.dataSource objectAtIndex:indexPath.row];
    cell.friendModel = model;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    HYNewFriendModel *model = [self.dataSource objectAtIndex:indexPath.row];
    HYUservCardViewController *userInfoVC = [[HYUservCardViewController alloc] init];
    userInfoVC.userJid = model.jid;
    [self.navigationController pushViewController:userInfoVC animated:YES];
    
}

// 接受
- (void)friendRequestAccept:(HYFriendRequestViewCell *)friendRequestViewCell
{
    HYNewFriendModel *friendModel = friendRequestViewCell.friendModel;
    NSString *message = [NSString stringWithFormat:@"您确定要添加%@为好友吗？",friendModel.jid.user];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"拒绝" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [[HYXMPPManager sharedInstance] rejectUserRequest:friendModel.jid];
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"同意" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[HYXMPPManager sharedInstance] agreeUserRequest:friendModel.jid];
    }];
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
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
        _tableView.rowHeight = kFriendRequestViewCellHeight;
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
