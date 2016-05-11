//
//  HYLoginViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/3/20.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYLoginViewController.h"
#import "HYLoginInfo.h"
#import "HYXMPPManager.h"
#import "HYUtils.h"

@interface HYLoginViewController ()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;
@property (weak, nonatomic) IBOutlet UITextField *userTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;

@end

@implementation HYLoginViewController

+ (instancetype)loginViewController{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
    HYLoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"loginVC"];
    return loginVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // 设置圆角
    self.loginBtn.layer.cornerRadius = 4;
    self.loginBtn.layer.masksToBounds = YES;
    self.loginBtn.enabled = NO;
    self.loginBtn.alpha = 0.8;
    self.userTextField.delegate = self;
    self.passwordTextField.delegate = self;
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

/**
 *  文字改变
 */
- (BOOL)textFieldTextDidChange:(NSNotification *)noti
{
    NSString *userStr = [self.userTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *pwdStr = [self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (userStr.length && pwdStr.length) {
        self.loginBtn.enabled = YES;
        self.loginBtn.alpha = 1.0;
    } else {
        self.loginBtn.enabled = NO;
        self.loginBtn.alpha = 0.8;
    }
    return YES;
}
#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.userTextField) { //next
        [self.passwordTextField becomeFirstResponder];
    } else { // done
        [self loginClick:nil];
    }
    return YES;
}
- (IBAction)cancelClick:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 登录
- (IBAction)loginClick:(UIButton *)sender {
    [self.view endEditing:YES];
    HYLoginInfo *loginInfo = [HYLoginInfo sharedInstance];
    // 删除两端空格
    NSString *bareStr = [self.userTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSRange atRange = [bareStr rangeOfString:@"@"];
    if (atRange.location == NSNotFound)
    {
        loginInfo.user = bareStr;
    } else {
        XMPPJID *jid = [XMPPJID jidWithString:bareStr];
        loginInfo.user = jid.user;
        loginInfo.hostName = jid.domain;
    }
    loginInfo.password = [self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    __weak typeof(self) weakSelf = self;
    [[HYXMPPManager sharedInstance] xmppUserLogin:^(HYXMPPConnectStatus status) {
        [weakSelf handleResultType:status];
    }];
}

- (void)handleResultType:(HYXMPPConnectStatus)status{
    
    MAIN(^{ // 主线程刷新UI
        switch (status) {
            case HYXMPPConnectStatusConnecting:
            {
                [HYUtils showWaitingMsg:@"请稍候..."];
                break;
            }
            case HYXMPPConnectStatusDidConnect:
            {
                [HYUtils showWaitingMsg:@"请稍候..."];
                break;
            }
            case HYXMPPConnectStatusDisConnect:
            {
                [HYUtils alertWithErrorMsg:@"与服务器断开连接 !"];
                break;
            }
            case HYXMPPConnectStatusTimeOut:
            {
                [HYUtils alertWithErrorMsg:@"网络连接超时 !"];
                break;
            }
            case HYXMPPConnectStatusAuthSuccess:
            {
                [HYUtils clearWaitingMsg]; // 隐藏
                [self enterMainPage];
                break;
            }
            case HYXMPPConnectStatusAuthFailure:
            {
                [HYUtils alertWithTitle:@"用户名或者密码不正确 !"];
                break;
            }
            default:{
                [HYUtils clearWaitingMsg]; // 隐藏
                break;
            }
        }
    });
    
}

- (void)enterMainPage{
    // 更改用户的登录状态为YES
    [HYLoginInfo sharedInstance].logon = YES;
    // 把用户登录成功的数据，保存到沙盒
    [[HYLoginInfo sharedInstance] saveUserInfoToSanbox];
    // 登录成功来到主界面
    [HYUtils initRootViewController];
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
