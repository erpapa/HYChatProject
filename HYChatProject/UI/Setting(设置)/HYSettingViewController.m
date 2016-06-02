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
#import "HYRequestModel.h"
#import "HYDatabaseHandler+HY.h"
#import <MessageUI/MessageUI.h>

static NSString *kMeViewCellIdentifier = @"kMeViewCellIdentifier";
static NSString *kSettingViewCellIdentifier = @"kSettingViewCellIdentifier";
@interface HYSettingViewController ()<UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) XMPPvCardTemp *vCard;
@property (nonatomic, strong) NSArray *dataSource;
@end

@implementation HYSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.sectionFooterHeight = 0.0f;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.vCard = [HYUtils currentUservCard]; // 从本地读取名片
    [self.tableView reloadData]; // 刷新数据
    
    if (self.vCard == nil) {
        __weak typeof(self) weakSelf = self;
        [[HYXMPPManager sharedInstance] getMyvCard:^(XMPPvCardTemp *vCardTemp) { // 获取个人名片
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.vCard = vCardTemp;
            [strongSelf.tableView reloadData];
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
    settingCell.badgeView.hidden = YES;
    settingCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; // 箭头
    if (indexPath.section == 1 && indexPath.row == 1) {
        NSMutableArray *requests = [NSMutableArray array];
        [[HYDatabaseHandler sharedInstance] allRequestFriends:requests];// 获取数据
        for (HYRequestModel *model in requests) {
            if (model.option == 0) { // 没有处理
                settingCell.badgeView.hidden = NO;
                settingCell.accessoryType = UITableViewCellAccessoryNone;
                break;
            }
        }
    }
    NSArray *array = [self.dataSource objectAtIndex:indexPath.section];
    NSDictionary *dict = [array objectAtIndex:indexPath.row];
    settingCell.textLabel.text = [dict objectForKey:@"text"];
    settingCell.imageView.image = [UIImage imageNamed:dict[@"image"]];
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
    
    if (indexPath.section == 2 && indexPath.row == 0) { // 反馈（发送邮件）
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController* mailController = [[MFMailComposeViewController alloc] init];
            mailController.mailComposeDelegate = self;
            [mailController setToRecipients:@[@"hyplcf@163.com"]];
            [mailController setSubject:[NSString stringWithFormat:@"%@的反馈",[HYXMPPManager sharedInstance].myJID.user]];
            [mailController setMessageBody:@"" isHTML:NO];
            [self presentViewController:mailController animated:YES completion:nil];
        }
        
    } else {
        NSArray *array = [self.dataSource objectAtIndex:indexPath.section];
        NSDictionary *dict = [array objectAtIndex:indexPath.row];
        UIViewController *VC = [[NSClassFromString(dict[@"class"]) alloc] init];
        VC.title = dict[@"text"];
        VC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:VC animated:YES];
    }
    
}

#pragma mark - MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    /*
     enum MFMailComposeResult {
     MFMailComposeResultCancelled, //取消发送
     MFMailComposeResultSaved, //保存草稿
     MFMailComposeResultSent, //发送成功
     MFMailComposeResultFailed, //发送失败
     };
     */
    [controller dismissViewControllerAnimated:YES completion:^{
        switch (result) {
            case MFMailComposeResultSent:{
                [HYUtils alertWithSuccessMsg:@"发送成功!"];
                break;
            } case MFMailComposeResultFailed:{
                [HYUtils alertWithSuccessMsg:@"发送失败!"];
                break;
            }
            default:
                break;
        }
    }];
}

#pragma mark - 懒加载

- (NSArray *)dataSource
{
    if (_dataSource == nil) {
        _dataSource = @[@[
                              @{@"image":@"",@"text":@"",@"class":@"HYMyvCardViewController"}
                          ],
                        @[
                              @{@"image":@"notifaction",@"text":@"通知",@"class":@"HYNotifactionViewController"},
                              @{@"image":@"friendRequest",@"text":@"好友请求",@"class":@"HYFreindRequestViewController"},
                              @{@"image":@"videos",@"text":@"照片和媒体文件",@"class":@"HYPhotoSettingViewController"}
                          ],
                        @[
                              @{@"image":@"feedback",@"text":@"报告问题",@"class":@"UIViewController"},
                              @{@"image":@"help",@"text":@"帮助",@"class":@"HYHelpViewController"},
                              @{@"image":@"about",@"text":@"关于",@"class":@"HYAboutViewController"}
                        ]];
    }
    return _dataSource;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
