//
//  HYUservCardViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/5/1.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYUservCardViewController.h"
#import "HYXMPPManager.h"
#import "XMPPvCardTemp.h"
#import "HYMeViewCell.h"
#import "HYUtils.h"
#import "HYSingleChatViewController.h"
#import "HYQRCodeViewController.h"
#import "HYLoginInfo.h"

static NSString *kMeViewCellIdentifier = @"kMeViewCellIdentifier";
static NSString *kUservCardViewCellIdentifier=@"kUservCardViewCellIdentifier";

@interface HYUservCardViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *dataSource;
@property (nonatomic, strong) XMPPvCardTemp *vCard;
@property (nonatomic, assign) BOOL isMe;
@end

@implementation HYUservCardViewController

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
    
    self.isMe = [self.userJid.bare isEqualToString:[HYXMPPManager sharedInstance].myJID.bare];
    // 1.1 footerView
    if (self.isMe == NO) {
        UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 64)];
        UIButton *sendButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 24, CGRectGetWidth(footerView.bounds) - 40, 40)];
        sendButton.backgroundColor = COLOR(90, 200, 255, 1.0f);
        sendButton.layer.cornerRadius = 4;
        sendButton.layer.masksToBounds = YES;
        [sendButton setTitle:@"发送消息" forState:UIControlStateNormal];
        [sendButton addTarget:self action:@selector(send:) forControlEvents:UIControlEventTouchUpInside];
        [footerView addSubview:sendButton];
        self.tableView.tableFooterView = footerView;
    }
    
    // 获取数据
    __weak typeof(self) weakSelf = self;
    [[HYXMPPManager sharedInstance] getvCardFromJID:self.userJid vCardBlock:^(XMPPvCardTemp *vCardTemp) {
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
    if (section == 1) {
        if (self.isMe) {
            return 1;
        } else {
            return 2;
        }
    } else if (section == 2) {
        return 3;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) { // 个人名片
        HYMeViewCell *meCell = [tableView dequeueReusableCellWithIdentifier:kMeViewCellIdentifier];
        if (meCell == nil) {
            meCell = [[HYMeViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMeViewCellIdentifier];
        }
        meCell.accessoryType = UITableViewCellAccessoryNone;
        meCell.vCard = self.vCard;
        meCell.QRView.hidden = YES;
        return meCell;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kUservCardViewCellIdentifier];
    if(cell == nil){
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kUservCardViewCellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    if (indexPath.section == 1) {
        if (self.isMe) {
            UIImageView *QRView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.bounds) - 56, 12, 20, 20)];
            QRView.image = [UIImage imageNamed:@"setting_QRcode_nor"];
            [cell.contentView addSubview:QRView];
            cell.textLabel.text = @"二维码";
        } else {
            if (indexPath.row == 0) { // 昵称
                cell.textLabel.text = @"设置昵称";
                cell.detailTextLabel.text = [[HYLoginInfo sharedInstance] nickNameForJid:self.userJid];
            } else if (indexPath.row == 1) { // 二维码
                UIImageView *QRView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.bounds) - 56, 12, 20, 20)];
                QRView.image = [UIImage imageNamed:@"setting_QRcode_nor"];
                [cell.contentView addSubview:QRView];
                cell.textLabel.text = @"二维码";
            }
        }
    } else {
        if (indexPath.row == 0) { // 邮箱
            cell.textLabel.text = @"邮箱";
            cell.detailTextLabel.text = self.vCard.email;
        } else if (indexPath.row == 1) { // 个人相册
            cell.textLabel.text = @"个人相册";
        } else if (indexPath.row == 2) { // 个性签名
            cell.textLabel.text = @"个性签名";
            cell.detailTextLabel.text = self.vCard.signature;
        }
    }
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        if (self.isMe) {
            HYQRCodeViewController *QRCodeVC = [[HYQRCodeViewController alloc] init];
            QRCodeVC.jid = self.userJid;
            [self.navigationController pushViewController:QRCodeVC animated:YES];
        } else {
            if (indexPath.row == 0) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"设置昵称" message:nil preferredStyle:UIAlertControllerStyleAlert];
                [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField){
                    textField.text = [[HYLoginInfo sharedInstance] nickNameForJid:self.userJid];
                }];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    UITextField *textField = alertController.textFields.firstObject;
                    NSString *inputText = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    if (inputText.length) {
                        [[HYXMPPManager sharedInstance] setNickname:inputText forUser:self.userJid];
                        [[HYLoginInfo sharedInstance].nickNameDict setObject:inputText forKey:self.userJid.bare];
                        [self.tableView reloadData];
                    } else {
                        [HYUtils alertWithErrorMsg:@"请重新输入！"];
                    }
                    
                }];
                [alertController addAction:cancelAction];
                [alertController addAction:okAction];
                [self presentViewController:alertController animated:YES completion:nil];
            } else if (indexPath.row == 1) {
                HYQRCodeViewController *QRCodeVC = [[HYQRCodeViewController alloc] init];
                QRCodeVC.jid = self.userJid;
                [self.navigationController pushViewController:QRCodeVC animated:YES];
            }
        }
    }
    
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
    if (indexPath.section == 0 || (indexPath.section == 2 && indexPath.row == 1)) {
        return 76.0;
    }
    return 44.0;
}


- (void)send:(UIButton *)sender
{
    // 分情况
    // 1.从聊天界面点入
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if ([vc isKindOfClass:[HYSingleChatViewController class]]) {
            [self.navigationController popViewControllerAnimated:YES];
            return;
        }
    }
    
    // 2.列表点入
    HYSingleChatViewController *singleChatVC = [[HYSingleChatViewController alloc] init];
    singleChatVC.chatJid = self.userJid;
    singleChatVC.hidesBottomBarWhenPushed = YES;
    UIViewController *firstVC = [self.navigationController.viewControllers firstObject]; // 第一个
    [self.navigationController setViewControllers:@[firstVC,singleChatVC] animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
