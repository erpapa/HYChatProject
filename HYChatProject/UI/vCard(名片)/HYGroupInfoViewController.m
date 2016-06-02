//
//  HYGroupInfoViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/5/6.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYGroupInfoViewController.h"
#import "HYXMPPRoomManager.h"
#import "HYGroupInviteViewController.h"
#import "HYDatabaseHandler+HY.h"
#import "HYRecentChatModel.h"

@interface HYGroupInfoViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSDictionary *dictionary;
@end

@implementation HYGroupInfoViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"详细资料";
    self.view.backgroundColor = [UIColor whiteColor];
    // 1.tableView
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.sectionFooterHeight = 0.0f;
    [self.view addSubview:self.tableView];
    // 获取在线人数
    __weak typeof(self) weakSelf = self;
    [[HYXMPPRoomManager sharedInstance] fetchRoom:self.roomJid info:^(NSDictionary *roomInfo) {
        weakSelf.dictionary = roomInfo;
        [weakSelf.tableView reloadData];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 1) {
        return 2;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *kCellIdentifier=@"kCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if(cell == nil){
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kCellIdentifier];
    }
    if (indexPath.section == 0) { // 头像
        cell.imageView.image = [UIImage imageNamed:@"defaultGroupHead"];
        cell.textLabel.text = self.roomJid.user;
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"在线人数";
            cell.detailTextLabel.text = self.dictionary[@"muc#roominfo_occupants"];
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"创建日期";
            cell.detailTextLabel.text = self.dictionary[@"x-muc#roominfo_creationdate"];
        }
        
    } else if (indexPath.section == 2) { // 邀请好友
        UILabel *invateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 44)];
        invateLabel.text = @"邀请好友";
        invateLabel.textColor = [UIColor blackColor];
        invateLabel.textAlignment = NSTextAlignmentCenter;
        [cell.contentView addSubview:invateLabel];
    } else if (indexPath.section == 3) { // 退出聊天室
        UILabel *logoutLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 44)];
        logoutLabel.text = @"退出聊天室";
        logoutLabel.textColor = [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f];
        logoutLabel.textAlignment = NSTextAlignmentCenter;
        [cell.contentView addSubview:logoutLabel];
    }
    
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return 12.0;
    }
    return 24.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return 76.0;
    }
    return 44.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 2) { // 邀请好友
        HYGroupInviteViewController *inviteVC = [[HYGroupInviteViewController alloc] init];
        inviteVC.roomJid = self.roomJid;
        [self.navigationController pushViewController:inviteVC animated:YES];
    } else if (indexPath.section == 3) { // 退出聊天室
        [[HYXMPPRoomManager sharedInstance] leaveRoomWithRoomJID:self.roomJid];
        HYRecentChatModel *model = [[HYRecentChatModel alloc] init];
        model.jid = self.roomJid;
        [[HYDatabaseHandler sharedInstance] deleteRecentChatModel:model]; // 删除最近联系人中的数据
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
