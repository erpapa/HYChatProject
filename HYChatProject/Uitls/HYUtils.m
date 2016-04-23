//
//  HYUtils.m
//  HYChatProject
//
//  Created by erpapa on 16/4/20.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYUtils.h"
#import "HYLoginInfo.h"
#import "HYXMPPManager.h"
#import "SVProgressHUD.h"
#import "HYFirstLoginViewController.h"
#import "HYCurrentLoginViewController.h"
#import "HYTabBarController.h"

@implementation HYUtils
/**
 *  切换控制器
 */
+ (void)initRootViewController
{
    // 1.从沙盒里加载用户的数据到单例
    [[HYLoginInfo sharedInstance] loadUserInfoFromSanbox];
    if ([HYLoginInfo sharedInstance].user.length) {
        // 2.判断用户的登录状态,logon == YES 直接来到主界面
        if([HYLoginInfo sharedInstance].logon){
            // 2.1. 设置根控制器
            [UIApplication sharedApplication].delegate.window.rootViewController = [HYTabBarController tabBarController];
        }else{
            [UIApplication sharedApplication].delegate.window.rootViewController = [HYCurrentLoginViewController currentLoginViewController];
        }
    } else { // 没有用户信息
        [UIApplication sharedApplication].delegate.window.rootViewController = [HYFirstLoginViewController firstLoginViewController];
    }
    
    
}

/**
 *  hud
 */
+ (void)showWaitingMsg:(NSString *)msg
{
    if ([SVProgressHUD isVisible] == NO) {
        [self initProgressHUD];
    }
    [SVProgressHUD showWithStatus:msg];
}

+ (void)clearWaitingMsg
{
    [SVProgressHUD dismiss];
}

+ (void)clearWaitingMsgWithDelay:(float)delay
{
    [SVProgressHUD dismissWithDelay:delay];
}

+ (void)alertWithSuccessMsg:(NSString *)msg
{
    if ([SVProgressHUD isVisible] == NO) {
        [self initProgressHUD];
    }
    [SVProgressHUD showSuccessWithStatus:msg];
}

+ (void)alertWithErrorMsg:(NSString *)msg
{
    if ([SVProgressHUD isVisible] == NO) {
        [SVProgressHUD dismiss];
    }
    [SVProgressHUD showErrorWithStatus:msg];
}

+ (void)alertWithTitle:(NSString *)title
{
    if ([SVProgressHUD isVisible] == YES) {
        [HYUtils clearWaitingMsg]; // 隐藏
    }
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alertView show];
}

+ (void)alertWithNormalMsg:(NSString *)msg
{
    if ([SVProgressHUD isVisible] == NO) {
        [self initProgressHUD];
    }
    [SVProgressHUD showInfoWithStatus:msg];
}

+ (void)initProgressHUD
{
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleCustom];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD setDefaultAnimationType:SVProgressHUDAnimationTypeNative];
    [SVProgressHUD setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.6]];
    [SVProgressHUD setForegroundColor:[UIColor whiteColor]];
 
}
/**
 *  颜色
 */
+ (NSString *)stringFromColor:(UIColor*)aColor
{
    if (!aColor)
    {
        return nil;
    }
    CGFloat r , g, b, a;
    [aColor getRed:&r green:&g blue:&b alpha:&a];
    int rI = r*255;
    int gI = g*255;
    int bI = b*255;
    int aI = a*255;
    long colorInt = aI<<24|rI<<16|gI<<8|bI;
    NSString* str = [NSString stringWithFormat:@"%ld",colorInt];
    return str;
}

+ (UIColor *)colorFromString:(NSString*)aString
{
    if(!aString){
        return nil;
    }
    long long value = [aString longLongValue];
    int a = (int)(value>>24 & 0xFF);
    int r = (int)(value>>16 & 0xFF);
    int g = (int)(value>>8 & 0xFF);
    int b = (int)(value & 0xFF);
    UIColor* color = COLOR(r, g, b, a*1.0/255);
    return color;
}

@end
