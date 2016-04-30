//
//  HYCurrentLoginViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/4/21.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYCurrentLoginViewController.h"
#import "HYActionSheetController.h"
#import "HYLoginViewController.h"
#import "HYRegisterViewController.h"
#import "HYLoginInfo.h"
#import "HYXMPPManager.h"
#import "XMPPvCardTemp.h"
#import "HYUtils.h"
#import "YYWebImage.h"
#import "YYKeyboardManager.h"

@interface HYCurrentLoginViewController ()<UITextFieldDelegate,YYKeyboardObserver>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView *iconView;
@property (strong, nonatomic) UILabel *userLabel;
@property (strong, nonatomic) UILabel *pwdLabel;
@property (strong, nonatomic) UITextField *pwdTextField;
@property (strong, nonatomic) UIView *line;
@property (strong, nonatomic) UIButton *loginButton;

@end

@implementation HYCurrentLoginViewController

/**
 *  从storyBord加载
 */
+ (instancetype)currentLoginViewController
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
    HYCurrentLoginViewController *currentLoginVC = [storyboard instantiateViewControllerWithIdentifier:@"currentLoginVC"];
    return currentLoginVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do anyadditional setup after loading the view.
    // 1.头像
    CGFloat iconViewY = 88;
    CGFloat iconViewW = 100;
    self.iconView = [[UIImageView alloc] initWithFrame:CGRectMake((kScreenW - iconViewW) * 0.5, iconViewY, iconViewW, iconViewW)];
    self.iconView.layer.cornerRadius = iconViewW * 0.5;
    self.iconView.layer.masksToBounds = YES;
    [self.scrollView addSubview:self.iconView];
    XMPPvCardTemp *vCard = [HYUtils currentUservCard];
    if (vCard) {
        self.iconView.image = [UIImage imageWithData:vCard.photo];
    } else {
        self.iconView.image = [UIImage imageNamed:@"defaultHead"];
    }
    
    // 2.用户名
    CGFloat userLabelX = 60;
    self.userLabel = [[UILabel alloc] initWithFrame:CGRectMake(userLabelX, CGRectGetMaxY(self.iconView.frame) + 10, kScreenW - userLabelX * 2, 32)];
    self.userLabel.textAlignment = NSTextAlignmentCenter;
    [self.scrollView addSubview:self.userLabel];
    
    // 3.密码
    self.pwdLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(self.userLabel.frame) + 20, 80, 44)];
    self.pwdLabel.text = @"密码";
    [self.scrollView addSubview:self.pwdLabel];
    
    self.pwdTextField = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.pwdLabel.frame), CGRectGetMinY(self.pwdLabel.frame), kScreenW - 20 - CGRectGetMaxX(self.pwdLabel.frame), 44)];
    self.pwdTextField.font = [UIFont systemFontOfSize:17];
    self.pwdTextField.placeholder = @"请填写密码";
    self.pwdTextField.secureTextEntry = YES; // 密码输入
    self.pwdTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.pwdTextField.returnKeyType = UIReturnKeyGo; // return -> GO
    self.pwdTextField.delegate = self;
    [self.scrollView addSubview:self.pwdTextField];
    
    self.line = [[UIView alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(self.pwdLabel.frame), kScreenW - 20, 1)];
    self.line.backgroundColor = COLOR(239, 239, 244, 1.0f);
    [self.scrollView addSubview:self.line];
    
    // 4.登录
    self.loginButton = [[UIButton alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(self.line.frame) + 24, kScreenW - 40, 40)];
    [self.loginButton addTarget:self action:@selector(loginClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.loginButton setTitle:@"登录" forState:UIControlStateNormal];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.loginButton.backgroundColor = COLOR(90, 200, 255, 1.0f);
    self.loginButton.layer.cornerRadius = 4;
    self.loginButton.layer.masksToBounds = YES;
    self.loginButton.alpha = 0.8;
    self.loginButton.enabled = NO;
    [self.scrollView addSubview:self.loginButton];
    
    // 5.scrollView
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) + 1);
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    HYLoginInfo *loginInfo = [HYLoginInfo sharedInstance];
//    [self.iconView yy_setImageWithURL:nil placeholder:nil];
    self.userLabel.text = loginInfo.user.length ? loginInfo.user : @"用户名";
    
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[YYKeyboardManager defaultManager] addObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldTextDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[YYKeyboardManager defaultManager] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 键盘状态改变
- (void)keyboardChangedWithTransition:(YYKeyboardTransition)transition
{
    if (transition.toVisible == YES) { // 键盘弹起
        CGFloat offsetY = CGRectGetMaxY(self.loginButton.frame) + CGRectGetHeight(transition.toFrame) - CGRectGetHeight(self.scrollView.frame) + 24;
        [UIView animateWithDuration:transition.animationCurve delay:0 options:transition.animationOption animations:^{
            if (offsetY > 0) self.scrollView.transform = CGAffineTransformMakeTranslation(0, -offsetY);
        } completion:^(BOOL finished) {
        }];
    } else { // 键盘隐藏
        [UIView animateWithDuration:transition.animationCurve delay:0 options:transition.animationOption animations:^{
            self.scrollView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
        }];
    }
}

#pragma mark - 文字改变
- (BOOL)textFieldTextDidChange:(NSNotification *)noti
{
    NSString *pwdStr = [self.pwdTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (pwdStr.length) {
        self.loginButton.enabled = YES;
        self.loginButton.alpha = 1.0;
    } else {
        self.loginButton.enabled = NO;
        self.loginButton.alpha = 0.8;
    }
    return YES;
}
#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self loginClick:nil];
    return YES;
}

/**
 *  更多
 */
- (IBAction)more:(UIButton *)sender {
    HYActionSheetController *actionVC = [[HYActionSheetController alloc] init];
    __weak typeof(self) weakSelf = self;
    [actionVC addActionTitle:@"切换帐号" withBlock:^{
        HYLoginViewController *loginVC = [HYLoginViewController loginViewController];
        [weakSelf presentViewController:loginVC animated:YES completion:nil];
    }];
    [actionVC addActionTitle:@"注册" withBlock:^{
        HYRegisterViewController *registerVC = [HYRegisterViewController registerViewController];
        [weakSelf presentViewController:registerVC animated:YES completion:nil];
    }];
    [self presentViewController:actionVC animated:NO completion:nil];
}

- (void)loginClick:(UIButton *)sender
{
    [self.view endEditing:YES];
    HYLoginInfo *loginInfo = [HYLoginInfo sharedInstance];
    // 删除两端空格
    loginInfo.password = [self.pwdTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
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
                [HYUtils alertWithErrorMsg:@"与服务器断开连接"];
                break;
            }
            case HYXMPPConnectStatusTimeOut:
            {
                [HYUtils alertWithErrorMsg:@"网络连接超时"];
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
                [HYUtils alertWithTitle:@"用户名或者密码不正确"];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
