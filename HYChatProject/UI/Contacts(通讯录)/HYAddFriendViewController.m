//
//  HYAddFriendViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/5/1.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYAddFriendViewController.h"
#import "HYXMPPManager.h"
#import "HYXMPPRoomManager.h"
#import "HYUtils.h"
#import "XMPPvCardTemp.h"
#import "HYUservCardViewController.h"

@interface HYAddFriendViewController ()<UITextFieldDelegate, UIAlertViewDelegate>
@property (nonatomic, strong) UILabel *accountLabel;
@property (nonatomic, strong) UITextField *accountTextField;
@property (nonatomic, strong) UIView *line;
@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, strong) XMPPJID *roomJid;

@end

@implementation HYAddFriendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = [self titleWithType:self.type];;
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGFloat labelX = 20;
    self.accountLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelX, CGRectGetMaxY(self.navigationController.navigationBar.frame) + 44, 80, 44)];
    self.accountLabel.text = @"帐号";
    [self.view addSubview:self.accountLabel];
    
    
    self.accountTextField = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.accountLabel.frame), CGRectGetMinY(self.accountLabel.frame), kScreenW - 20 - CGRectGetMaxX(self.accountLabel.frame), 44)];
    self.accountTextField.font = [UIFont systemFontOfSize:17];
    self.accountTextField.placeholder = @"请填写帐号";
    self.accountTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.accountTextField.returnKeyType = UIReturnKeyGo; // return -> GO
    self.accountTextField.delegate = self;
    [self.view addSubview:self.accountTextField];
    
    self.line = [[UIView alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(self.accountLabel.frame), kScreenW - 20, 1)];
    self.line.backgroundColor = COLOR(239, 239, 244, 1.0f);
    [self.view addSubview:self.line];
    
    self.addButton = [[UIButton alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(self.line.frame) + 24, kScreenW - 40, 40)];
    [self.addButton addTarget:self action:@selector(addButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.addButton setTitle:@"确认" forState:UIControlStateNormal];
    [self.addButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.addButton.backgroundColor = COLOR(90, 200, 255, 1.0f);
    self.addButton.layer.cornerRadius = 4;
    self.addButton.layer.masksToBounds = YES;
    self.addButton.alpha = 0.8;
    self.addButton.enabled = NO;
    [self.view addSubview:self.addButton];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldTextDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 文字改变
- (BOOL)textFieldTextDidChange:(NSNotification *)noti
{
    NSString *textStr = [self.accountTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (textStr.length) {
        self.addButton.enabled = YES;
        self.addButton.alpha = 1.0;
    } else {
        self.addButton.enabled = NO;
        self.addButton.alpha = 0.8;
    }
    return YES;
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self addButtonClick:nil];
    return YES;
}

- (void)addButtonClick:(UIButton *)sender
{
    // 删除两端空格
    NSString *bareStr = [self.accountTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (bareStr.length == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"请重新输入！" delegate:nil cancelButtonTitle:@"确认" otherButtonTitles: nil];
        [alert show];
        return;
    }
    NSRange atRange = [bareStr rangeOfString:@"@"];
    NSString *domain = [HYXMPPManager sharedInstance].myJID.domain;
    __weak typeof(self) weakSelf = self;
    switch (self.type) {
        case HYAddFriendTypeFriend:{
            if (atRange.location == NSNotFound){
                bareStr = [NSString stringWithFormat:@"%@@%@",bareStr,domain];
            }
            XMPPJID *jid = [XMPPJID jidWithString:bareStr];
            int status = [[HYXMPPManager sharedInstance] addUser:jid];
            if (status == -1) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"\n不能添加自己为好友！" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
                [alert show];
            }else if (status == 0) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"\n已在好友列表！不能重复添加好友" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
                [alert show];
                
            } else {
                [HYUtils alertWithSuccessMsg:@"已发送好友请求！"];
            }
            break;
        }
        case HYAddFriendTypeGroup:{
            if (atRange.location == NSNotFound){
                bareStr = [NSString stringWithFormat:@"%@@conference.%@",bareStr,domain];
            }
            self.roomJid = [XMPPJID jidWithString:bareStr];
            [[HYXMPPRoomManager sharedInstance] fetchRoom:self.roomJid info:^(NSDictionary *roomInfo) {
                if (roomInfo == nil) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"\n聊天室不存在！是否创建?" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
                    alert.tag = 1001;
                    [alert show];
                } else {
                    [[HYXMPPRoomManager sharedInstance] joinRoomWithRoomJID:self.roomJid withNickName:[HYXMPPManager sharedInstance].myJID.user success:^(BOOL success) {
                        if (success) {
                            [HYUtils alertWithSuccessMsg:@"加入房间成功 !"];
                        } else {
                            [HYUtils alertWithSuccessMsg:@"加入房间失败 !"];
                        }
                    }];
                }
            }];
            break;
        }
        case HYAddFriendTypeCreateGroup:{
            if (atRange.location == NSNotFound){
                bareStr = [NSString stringWithFormat:@"%@@conference.%@",bareStr,domain];
            }
            self.roomJid = [XMPPJID jidWithString:bareStr];
            [[HYXMPPRoomManager sharedInstance] fetchRoom:self.roomJid info:^(NSDictionary *roomInfo) {
                if (roomInfo == nil) { // 如果没有获取到room信息，创建room
                    [[HYXMPPRoomManager sharedInstance] createRoomWithRoomName:self.roomJid.user success:^(BOOL success) {
                        if (success) {
                            [HYUtils alertWithSuccessMsg:@"创建房间成功 !"];
                        } else {
                            [HYUtils alertWithSuccessMsg:@"创建房间失败 !"];
                        }
                    }];
                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"\n聊天室已被创建！是否加入?" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
                    alert.tag = 1002;
                    [alert show];
                }
            }];
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - alertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        return;
    } else { // 加入聊天室
        if (alertView.tag == 1001) { // 创建
            [[HYXMPPRoomManager sharedInstance] createRoomWithRoomName:self.roomJid.user success:^(BOOL success) {
                if (success) {
                    [HYUtils alertWithSuccessMsg:@"创建房间成功 !"];
                } else {
                    [HYUtils alertWithSuccessMsg:@"创建房间失败 !"];
                }
            }];
        } else if (alertView.tag == 1002) { // 加入
            [[HYXMPPRoomManager sharedInstance] joinRoomWithRoomJID:self.roomJid withNickName:[HYXMPPManager sharedInstance].myJID.user success:^(BOOL success) {
                if (success) {
                    [HYUtils alertWithSuccessMsg:@"加入房间成功 !"];
                } else {
                    [HYUtils alertWithSuccessMsg:@"加入房间失败 !"];
                }
            }];
        }
        
    }
}

- (NSString *)titleWithType:(HYAddFriendType)type
{
    NSString *title = nil;
    switch (type) {
        case HYAddFriendTypeFriend:{
            title = @"添加好友";
            break;
        }
        case HYAddFriendTypeGroup:{
            title = @"加入聊天室";
            break;
        }
        case HYAddFriendTypeCreateGroup:{
            title = @"创建聊天室";
            break;
        }
            
        default:
            break;
    }
    return title;
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
