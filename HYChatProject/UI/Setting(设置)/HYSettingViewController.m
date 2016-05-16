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
#import "HYUtils.h"
#import "HYXMPPManager.h"
#import "HYMyvCardViewController.h"

static NSString *kMeViewCellIdentifier = @"kMeViewCellIdentifier";
static NSString *kSettingViewCellIdentifier = @"kSettingViewCellIdentifier";
@interface HYSettingViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) XMPPvCardTemp *vCard;
@property (nonatomic, strong) NSArray *dataSource;
@end

@implementation HYSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    
    self.vCard = [HYUtils currentUservCard]; // 从本地读取名片
    if (self.vCard == nil) {
        __weak typeof(self) weakSelf = self;
        [[HYXMPPManager sharedInstance] getMyvCard:^(XMPPvCardTemp *vCardTemp) { // 获取个人名片
            __strong typeof(weakSelf) strongSellf = weakSelf;
            strongSellf.vCard = vCardTemp;
            [strongSellf.tableView reloadData];
        }];
    }
    
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.dataSource.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *array = [self.dataSource objectAtIndex:section];
    return array.count;
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
        settingCell = [[HYSettingViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kSettingViewCellIdentifier];
    }
    NSArray *array = [self.dataSource objectAtIndex:indexPath.section];
    NSDictionary *dict = [array objectAtIndex:indexPath.row];
    settingCell.textLabel.text = [dict objectForKey:@"text"];
    return settingCell;
    
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
    if (section == 0) {
        return 12.0;
    }
    return 22.0;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.section == 0) {
        HYMyvCardViewController *myvCardVC = [[HYMyvCardViewController alloc] init];
        myvCardVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:myvCardVC animated:YES];
    } else {
        [[HYXMPPManager sharedInstance] xmppUserlogout];
    }
}

#pragma mark - 懒加载
- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.sectionFooterHeight = 0.0f;
        _tableView.dataSource = self;
        _tableView.delegate = self;
    }
    return _tableView;
}

- (NSArray *)dataSource
{
    if (_dataSource == nil) {
        _dataSource = @[@[
                              @{@"image":@"",@"text":@""}
                          ],
                        @[
                              @{@"image":@"",@"text":@"通知"},
                              @{@"image":@"",@"text":@"好友请求"},
                              @{@"image":@"",@"text":@"照片和媒体文件"}
                          ],
                        @[
                              @{@"image":@"",@"text":@"报告问题"},
                              @{@"image":@"",@"text":@"帮助"},
                              @{@"image":@"",@"text":@"关于"}
                        ]];
    }
    return _dataSource;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
