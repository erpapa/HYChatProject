//
//  HYMYvCardViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/5/6.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYMYvCardViewController.h"
#import "HYXMPPManager.h"
#import "XMPPvCardTemp.h"
#import "HYUtils.h"
#import "HYQRCodeViewController.h"
#import "HYChangePasswordViewController.h"


@interface HYMyvCardViewController ()<UITableViewDataSource,UITableViewDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate,HYSexSelectioViewControllerDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *dataSource;
@property (nonatomic, strong) XMPPvCardTemp *vCard;
@property (nonatomic, assign) BOOL shouldUpdate;
@property (nonatomic, weak) UIImageView *headView;
@property (nonatomic, weak) UIImageView *QRView;
@property (nonatomic, weak) UILabel *logoutLabel;

@end

@implementation HYMyvCardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"个人信息";
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(back:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(changePassWord:)];
    
    // 1.tableView
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.sectionFooterHeight = 0.0f;
    [self.view addSubview:self.tableView];
    
    // 2.
    self.dataSource = @[@[@"头像",@"帐号",@"昵称",@"二维码"],@[@"性别",@"邮箱",@"个性签名"],@[@""]];
    // 3.
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

#pragma mark - UITableViewDatasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.dataSource.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *array = [self.dataSource objectAtIndex:section];
    return array.count;;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *kCellIdentifier=@"kCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if(cell == nil){
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kCellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    NSArray *array = [self.dataSource objectAtIndex:indexPath.section];
    NSString *title = [array objectAtIndex:indexPath.row];
    cell.textLabel.text = title;
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:{
                if (self.QRView.superview) {
                    self.headView.image = self.vCard.photo ? [UIImage imageWithData:self.vCard.photo] : [UIImage imageNamed:@"defaultHead"];
                    break;
                }
                UIImageView *headView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.bounds) - 96, 8, 60, 60)];
                headView.layer.cornerRadius = 30;
                headView.layer.masksToBounds = YES;
                [cell.contentView addSubview:headView];
                headView.image = self.vCard.photo ? [UIImage imageWithData:self.vCard.photo] : [UIImage imageNamed:@"defaultHead"];
                self.headView = headView;
                break;
            }
            case 1:{
                cell.detailTextLabel.text = [HYXMPPManager sharedInstance].myJID.user;
                break;
            }
            case 2:{
                cell.detailTextLabel.text = self.vCard.nickname.length ? self.vCard.nickname : [HYXMPPManager sharedInstance].myJID.user;
                break;
            }
            case 3:{
                if (self.QRView.superview) {
                    break;
                }
                UIImageView *QRView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.bounds) - 56, 12, 20, 20)];
                QRView.image = [UIImage imageNamed:@"setting_QRcode_nor"];
                [cell.contentView addSubview:QRView];
                self.QRView = QRView;
                break;
            }
                
            default:
                break;
        }
    } else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:{
                cell.detailTextLabel.text = self.vCard.sex.length ? self.vCard.sex : @"未知";
                break;
            }
            case 1:{
                cell.detailTextLabel.text = self.vCard.email;
                break;
            }
            case 2:{
                cell.detailTextLabel.text = self.vCard.signature;
                break;
            }
                
            default:
                break;
        }
    } else if (indexPath.section == 2) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        if (!self.logoutLabel.superview) {
            UILabel *logoutLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 44)];
            logoutLabel.text = @"退出登录";
            logoutLabel.textColor = [UIColor blackColor];
            logoutLabel.textAlignment = NSTextAlignmentCenter;
            [cell.contentView addSubview:logoutLabel];
            self.logoutLabel = logoutLabel;
        }
    }
    return cell;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0) {
        return 76.0;
    }
    return 44.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return 12.0;
    }
    return 24.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:{ // 查看&修改头像
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"设置头像，让好友们认出是你" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
                UIAlertAction *photoAction = [UIAlertAction actionWithTitle:@"从照片中选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
                    pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                    pickerController.allowsEditing = YES;
                    pickerController.delegate = self;
                    [self presentViewController:pickerController animated:YES completion:nil];
                }];
                UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
                    pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                    pickerController.allowsEditing = YES;
                    pickerController.delegate = self;
                    [self presentViewController:pickerController animated:YES completion:nil];
                }];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
                
                [alertController addAction:photoAction];
                [alertController addAction:cameraAction];
                [alertController addAction:cancelAction];
                [self presentViewController:alertController animated:YES completion:nil];
                break;
            }
            case 1:{ // 帐号(不可修改)
                
                
                break;
            }
            case 2:{ // 修改昵称
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"设置昵称" message:nil preferredStyle:UIAlertControllerStyleAlert];
                [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField){
                    textField.text = self.vCard.nickname;
                }];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    UITextField *textField = alertController.textFields.firstObject;
                    NSString *inputText = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    if (inputText.length) {
                        self.vCard.nickname = inputText;
                        [self.tableView reloadData];
                        self.shouldUpdate = YES;
                    } else {
                        [HYUtils alertWithErrorMsg:@"请重新输入！"];
                    }
                    
                }];
                [alertController addAction:cancelAction];
                [alertController addAction:okAction];
                [self presentViewController:alertController animated:YES completion:nil];
                
                break;
            }
            case 3:{ // 查看二维码
                HYQRCodeViewController *QRCodeVC = [[HYQRCodeViewController alloc] init];
                QRCodeVC.jid = [HYXMPPManager sharedInstance].myJID;
                [self.navigationController pushViewController:QRCodeVC animated:YES];
                
                break;
            }
                
            default:
                break;
        }
    } else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:{ // 性别
                HYSexSelectioViewController *sexSelectioVC = [[HYSexSelectioViewController alloc] init];
                sexSelectioVC.sex = self.vCard.sex;
                sexSelectioVC.delegate = self;
                [self.navigationController pushViewController:sexSelectioVC animated:YES];
                break;
            }
            case 1:{ // 邮箱
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"设置邮箱" message:nil preferredStyle:UIAlertControllerStyleAlert];
                [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField){
                    textField.text = self.vCard.email;
                }];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    UITextField *textField = alertController.textFields.firstObject;
                    NSString *inputText = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([a-zA-Z0-9%_.+\\-]+)@([a-zA-Z0-9.\\-]+?\\.[a-zA-Z]{2,6})" options:kNilOptions error:NULL];
                     NSArray<NSTextCheckingResult *> *results = [regex matchesInString:inputText options:kNilOptions range:NSMakeRange(0, inputText.length)];
                    if (results.count) {
                        self.vCard.email = inputText.length ? inputText : self.vCard.nickname;
                        [self.tableView reloadData];
                        self.shouldUpdate = YES;
                    } else {
                        [HYUtils alertWithErrorMsg:@"错误的邮箱格式！"];
                    }
                    
                }];
                [alertController addAction:cancelAction];
                [alertController addAction:okAction];
                [self presentViewController:alertController animated:YES completion:nil];
                
                break;
            }
            case 2:{ // 个性签名
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"设置个性签名" message:nil preferredStyle:UIAlertControllerStyleAlert];
                [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField){
                    textField.text = self.vCard.signature;
                }];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    UITextField *textField = alertController.textFields.firstObject;
                    self.vCard.signature = textField.text;
                    [self.tableView reloadData];
                    self.shouldUpdate = YES;
                }];
                [alertController addAction:cancelAction];
                [alertController addAction:okAction];
                [self presentViewController:alertController animated:YES completion:nil];
                
                break;
            }
            default:
                break;
        }
    } else {
        [HYUtils showWaitingMsg:@"请稍候..."];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [HYUtils clearWaitingMsg];
            [[HYXMPPManager sharedInstance] xmppUserlogout]; // 退出登录
        });
    }
    
}

#pragma mark - HYSexSelectioViewControllerDelegate

- (void)sexSelectioDidFinished:(HYSexSelectioViewController *)sexSelectioVC
{
    if (![sexSelectioVC.sex isEqualToString:self.vCard.sex]) {
        self.vCard.sex = sexSelectioVC.sex;
        [self.tableView reloadData];
        self.shouldUpdate = YES;
    }
}

#pragma mark - UIImagePickerControllerDelegate

/**
 *  设置头像
 */
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [picker dismissViewControllerAnimated:YES completion:^{
        UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
        //把获取的iamge进行压缩，保存在vcard中
        NSData *data = UIImageJPEGRepresentation(image, 0.01);
        self.vCard.photo = data;
        [self.tableView reloadData];
        self.shouldUpdate = YES;
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}


- (void)back:(id)sender
{
    if (self.shouldUpdate) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"是否保存修改？" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self.navigationController popViewControllerAnimated:YES];
        }];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [HYUtils saveCurrentUservCard:self.vCard]; // 保存名片
            [[HYXMPPManager sharedInstance] updateMyvCard:self.vCard successBlock:^(BOOL success) {
                if (success) {
                    [HYUtils alertWithSuccessMsg:@"保存成功！"];
                } else {
                    [HYUtils alertWithSuccessMsg:@"保存失败！"];
                }
            }];
            [self.navigationController popViewControllerAnimated:YES];
        }];
        [alertController addAction:cancelAction];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
    
    
}

- (void)changePassWord:(id)sender
{
    HYChangePasswordViewController *vc = [[HYChangePasswordViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end


@implementation HYSexSelectioViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"性别选择";
    // 1.tableView
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.sectionFooterHeight = 0.0f;
    [self.view addSubview:self.tableView];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if ([self.delegate respondsToSelector:@selector(sexSelectioDidFinished:)]) {
        [self.delegate sexSelectioDidFinished:self];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *kSexSelectioIdentifier=@"kSexSelectioIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSexSelectioIdentifier];
    if(cell == nil){
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSexSelectioIdentifier];
    }
    if (indexPath.row == 0) {
        cell.textLabel.text = @"男";
    } else if (indexPath.row == 1) {
        cell.textLabel.text = @"女";
    }
    if ([cell.textLabel.text isEqualToString:self.sex]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    self.sex = cell.textLabel.text;
    [tableView reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 12.0;
}

@end