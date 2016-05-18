//
//  AppDelegate.m
//  HYChatProject
//
//  Created by erpapa on 16/3/20.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "AppDelegate.h"
#import "HYUtils.h"
#import "HYXMPPManager.h"
#import "AFNetworkReachabilityManager.h"
#import "HYSingleChatViewController.h"
#import "HYGroupChatViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    // 1.创建窗口
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    // 2.设置rootViewController
    [HYUtils initRootViewController];
    // 3.注册应用接收通知
    if ([[UIDevice currentDevice].systemVersion doubleValue] > 8.0){
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil];
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    }
    // 5.设置keyWindow并显示窗口
    [self.window makeKeyAndVisible];
    
    // 6.开始监听网络状态
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    return YES;
}

/**
 *  点击了本地通知
 */
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSLog(@"%@",notification.userInfo);
    NSDictionary *dict = notification.userInfo;
    NSString *chatJid = [dict objectForKey:@"chatJid"];
    XMPPJID *jid = [XMPPJID jidWithString:chatJid];
    BOOL isGroup = [[dict objectForKey:@"isGroup"] boolValue];
    // 进入对应的controller
    if (isGroup) {
        HYGroupChatViewController *singleChatVC = [[HYGroupChatViewController alloc] init];
        singleChatVC.roomJid = jid;
        singleChatVC.hidesBottomBarWhenPushed = YES;
        UIViewController *firstVC = [self.navController.viewControllers firstObject]; // 第一个
        [self.navController setViewControllers:@[firstVC,singleChatVC] animated:NO];
    } else {
        HYSingleChatViewController *singleChatVC = [[HYSingleChatViewController alloc] init];
        singleChatVC.chatJid = jid;
        singleChatVC.hidesBottomBarWhenPushed = YES;
        UIViewController *firstVC = [self.navController.viewControllers firstObject]; // 第一个
        [self.navController setViewControllers:@[firstVC,singleChatVC] animated:NO];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // 判断是否可以后台运行
//    UIDevice *device = [UIDevice currentDevice];
//    BOOL backgroundSupported = NO;
//    if ([device respondsToSelector:@selector(isMultitaskingSupported)]) {
//        backgroundSupported = YES;
//    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [HYXMPPManager sharedInstance].isBackGround = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    [HYXMPPManager sharedInstance].isBackGround = NO;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    
}

@end
