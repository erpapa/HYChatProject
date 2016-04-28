//
//  HYTabBarController.m
//  HYChatProject
//
//  Created by erpapa on 16/3/20.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYTabBarController.h"
#import "HYBaseNavigationController.h"
#import "HYRecentChatViewController.h"
#import "HYContactsViewController.h"
#import "HYSettingViewController.h"

@interface HYTabBarController ()

@end

@implementation HYTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    // 添加子控制器
    [self setupChildViewControllers];
}

- (void)setupChildViewControllers
{
    // 设置子控制器
    HYRecentChatViewController *recentVC = [[HYRecentChatViewController alloc] init];
    recentVC.title = @"最近";
    HYContactsViewController *contactsVC = [[HYContactsViewController alloc] init];
    contactsVC.title = @"联系人";
    HYSettingViewController *settingVC = [[HYSettingViewController alloc] init];
    settingVC.title = @"设置";
    
    HYBaseNavigationController *navigationController0 = [[HYBaseNavigationController alloc] initWithRootViewController:recentVC];
    HYBaseNavigationController *navigationController1 = [[HYBaseNavigationController alloc] initWithRootViewController:contactsVC];
    HYBaseNavigationController *navigationController2 = [[HYBaseNavigationController alloc] initWithRootViewController:settingVC];
    self.tabBar.translucent = NO;// 子控制器的视图不会被UITabBarController的控制栏遮挡
//    self.tabBar.tintColor = [UIColor orangeColor];// 选中状态下的文字颜色
    self.viewControllers = @[navigationController0, navigationController1, navigationController2];
    NSArray *titles = @[recentVC.title, contactsVC.title, settingVC.title];
    [self.tabBar.items enumerateObjectsUsingBlock:^(UITabBarItem *item, NSUInteger idx, BOOL *stop) {
        [item setTitle:titles[idx]];
//        [item setImage:[UIImage imageNamed:images[idx]]];
//        UIImage *selectedImage = [UIImage imageNamed:[images[idx] stringByAppendingString:@"_selected"]];
//        [item setSelectedImage:[selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
