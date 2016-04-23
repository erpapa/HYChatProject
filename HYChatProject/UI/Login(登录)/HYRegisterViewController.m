//
//  HYRegisterViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/4/21.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYRegisterViewController.h"
#import "HYXMPPManager.h"
#import "HYLoginInfo.h"
#import "HYUtils.h"

@interface HYRegisterViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *userTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *registerButton;
@end

@implementation HYRegisterViewController
/**
 *  从storyBord加载
 */
+ (instancetype)registerViewController{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
    HYRegisterViewController *registerVC = [storyboard instantiateViewControllerWithIdentifier:@"registerVC"];
    return registerVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // 设置圆角
    self.registerButton.layer.cornerRadius = 4;
    self.registerButton.layer.masksToBounds = YES;
    self.registerButton.enabled = NO;
    self.registerButton.alpha = 0.8;
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
    if (userStr.length && pwdStr.length >= 6) {
        self.registerButton.enabled = YES;
        self.registerButton.alpha = 1.0;
    } else {
        self.registerButton.enabled = NO;
        self.registerButton.alpha = 0.8;
    }
    return YES;
}
#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.userTextField) { //next
        [self.passwordTextField becomeFirstResponder];
    } else { // done
        [self registerClick:nil];
    }
    return YES;
}

- (IBAction)cancelClick:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)registerClick:(UIButton *)sender {
    [self.view endEditing:YES];
    HYLoginInfo *userInfo = [HYLoginInfo sharedInstance];
    // 删除两端空格
    userInfo.user = [self.userTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    userInfo.password = [self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    __weak typeof(self) weakSelf = self;
    [[HYXMPPManager sharedInstance] xmppUserRegister:^(HYXMPPConnectStatus status) {
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
                [HYUtils alertWithErrorMsg:@"与服务器断开连接"];
                break;
            }
            case HYXMPPConnectStatusTimeOut:
            {
                [HYUtils alertWithErrorMsg:@"网络连接超时"];
                break;
            }
            case HYXMPPConnectStatusRegisterSuccess:
            {
                [HYUtils alertWithSuccessMsg:@"注册成功!"];
                [self dismissViewControllerAnimated:YES completion:nil];
                break;
            }
            case HYXMPPConnectStatusRegisterFailure:
            {
                [HYUtils alertWithTitle:@"注册失败!"];
                break;
            }
            default:{
                [HYUtils clearWaitingMsg]; // 隐藏
                break;
            }
        }
    });
    
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
