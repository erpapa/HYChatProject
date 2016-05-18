//
//  HYChangePasswordViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/5/16.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYChangePasswordViewController.h"
#import "HYXMPPManager.h"
#import "HYLoginInfo.h"
#import "HYUtils.h"

@interface HYChangePasswordViewController ()<UITextFieldDelegate>

@property (nonatomic, strong) UITextField *oldPwdTextField;
@property (nonatomic, strong) UITextField *aNewPwdTextField;
@property (nonatomic, strong) UITextField *repeatPwdTextField;
@property (nonatomic, strong) UIButton *okButton;

@end

@implementation HYChangePasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"修改密码";
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGFloat labelX = 20;
    UILabel *oldPwdLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelX, CGRectGetMaxY(self.navigationController.navigationBar.frame) + 20, 68, 44)];
    oldPwdLabel.text = @"原密码";
    oldPwdLabel.textAlignment = NSTextAlignmentRight;
    [self.view addSubview:oldPwdLabel];
    
    self.oldPwdTextField = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(oldPwdLabel.frame) + 12, CGRectGetMinY(oldPwdLabel.frame), kScreenW - 32 - CGRectGetMaxX(oldPwdLabel.frame), 44)];
    self.oldPwdTextField.font = [UIFont systemFontOfSize:16];
    self.oldPwdTextField.placeholder = @"请输入原密码";
    self.oldPwdTextField.keyboardType = UIKeyboardTypeASCIICapable;
    self.oldPwdTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.oldPwdTextField.returnKeyType = UIReturnKeyNext; // return -> next
    self.oldPwdTextField.delegate = self;
    [self.view addSubview:self.oldPwdTextField];
    
    UIView *line0 = [[UIView alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(oldPwdLabel.frame), kScreenW - 20, 1)];
    line0.backgroundColor = COLOR(239, 239, 244, 1.0f);
    [self.view addSubview:line0];
    
    UILabel *newPwdLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelX, CGRectGetMaxY(line0.frame), 68, 44)];
    newPwdLabel.text = @"新密码";
    newPwdLabel.textAlignment = NSTextAlignmentRight;
    [self.view addSubview:newPwdLabel];
    
    self.aNewPwdTextField = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(newPwdLabel.frame) + 12, CGRectGetMinY(newPwdLabel.frame), kScreenW - 32 - CGRectGetMaxX(newPwdLabel.frame), 44)];
    self.aNewPwdTextField.font = [UIFont systemFontOfSize:16];
    self.aNewPwdTextField.placeholder = @"请输入新密码";
    self.aNewPwdTextField.secureTextEntry = YES; // 密码输入
    self.aNewPwdTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.aNewPwdTextField.returnKeyType = UIReturnKeyNext; // return -> next
    self.aNewPwdTextField.delegate = self;
    [self.view addSubview:self.aNewPwdTextField];
    
    UIView *line1 = [[UIView alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(newPwdLabel.frame), kScreenW - 20, 1)];
    line1.backgroundColor = COLOR(239, 239, 244, 1.0f);
    [self.view addSubview:line1];
    
    UILabel *repeatPwdLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelX, CGRectGetMaxY(line1.frame), 68, 44)];
    repeatPwdLabel.text = @"确认密码";
    repeatPwdLabel.textAlignment = NSTextAlignmentRight;
    [self.view addSubview:repeatPwdLabel];
    
    self.repeatPwdTextField = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(repeatPwdLabel.frame) + 12, CGRectGetMinY(repeatPwdLabel.frame), kScreenW - 32 - CGRectGetMaxX(repeatPwdLabel.frame), 44)];
    self.repeatPwdTextField.font = [UIFont systemFontOfSize:16];
    self.repeatPwdTextField.placeholder = @"请再次输入密码";
    self.repeatPwdTextField.secureTextEntry = YES; // 密码输入
    self.repeatPwdTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.repeatPwdTextField.returnKeyType = UIReturnKeyGo; // return -> GO
    self.repeatPwdTextField.delegate = self;
    [self.view addSubview:self.repeatPwdTextField];
    
    UIView *line2 = [[UIView alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(repeatPwdLabel.frame), kScreenW - 20, 1)];
    line2.backgroundColor = COLOR(239, 239, 244, 1.0f);
    [self.view addSubview:line2];
    
    self.okButton = [[UIButton alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(line2.frame) + 24, kScreenW - 40, 40)];
    [self.okButton addTarget:self action:@selector(okButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.okButton setTitle:@"确认" forState:UIControlStateNormal];
    [self.okButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.okButton.backgroundColor = COLOR(90, 200, 255, 1.0f);
    self.okButton.layer.cornerRadius = 4;
    self.okButton.layer.masksToBounds = YES;
    [self.view addSubview:self.okButton];
}

- (void)okButtonClick:(UIButton *)sender
{
    NSString *oldPwd = [self.oldPwdTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *aNewPwd = [self.aNewPwdTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *repeatPwd = [self.repeatPwdTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (oldPwd.length == 0 || aNewPwd.length == 0 || repeatPwd.length == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"密码不能为空！" message:nil delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil];
        [alert show];
    } else if (![aNewPwd isEqualToString:repeatPwd]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"两次输入的密码不相同！" message:nil delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil];
        [alert show];
    } else if (![oldPwd isEqualToString:[HYLoginInfo sharedInstance].password]) {
        [HYUtils showWaitingMsg:@"请稍候..."];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [HYUtils clearWaitingMsg];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"密码不正确！" message:nil delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil];
            [alert show];
        });
        
    } else {
        [[HYXMPPManager sharedInstance] xmppUserChangePassword:aNewPwd];
        [HYUtils showWaitingMsg:@"请稍候..."];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [HYUtils alertWithSuccessMsg:@"修改密码成功!"];
            [[HYXMPPManager sharedInstance] xmppUserlogout]; // 退出登录
        });
    }
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.oldPwdTextField) { //next
        [self.aNewPwdTextField becomeFirstResponder];
    } else if (textField == self.aNewPwdTextField) { //next
        [self.repeatPwdTextField becomeFirstResponder];
    } else { // go
        [self okButtonClick:self.okButton];
    }
    return YES;
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
