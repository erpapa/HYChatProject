//
//  HYMyViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/4/22.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYSettingViewController.h"
#import "HYMeViewCell.h"
#import "HYSettingViewCell.h"
#import "XMPPvCardTemp.h"
#import "HYXMPPManager.h"

static NSString *kMeViewCellIdentifier = @"kMeViewCellIdentifier";
static NSString *kSettingViewCellIdentifier = @"kSettingViewCellIdentifier";
@interface HYSettingViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) XMPPvCardTemp *vCard;
@end

@implementation HYSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    __weak typeof(self) weakSelf = self;
    [[HYXMPPManager sharedInstance] getMyvCard:^(XMPPvCardTemp *vCardTemp) { // 获取个人名片
        weakSelf.vCard = vCardTemp;
        [weakSelf.tableView reloadData];
    }];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return 3;
    }
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) { // 个人名片
        HYMeViewCell *meCell = [tableView dequeueReusableCellWithIdentifier:kMeViewCellIdentifier];
        if (meCell == nil) {
            meCell = [[HYMeViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMeViewCellIdentifier];
        }
        meCell.vCard = self.vCard;
        return meCell;
    }
    HYSettingViewCell *settingCell = [tableView dequeueReusableCellWithIdentifier:kSettingViewCellIdentifier];
    if (settingCell == nil) {
        settingCell = [[HYSettingViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kSettingViewCellIdentifier];
    }
    return settingCell;
    
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return kMeViewCellHeight;
    }
    return kSettingViewCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 22.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 1.0f;
}

#pragma mark - 懒加载
- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.dataSource = self;
        _tableView.delegate = self;
    }
    return _tableView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
