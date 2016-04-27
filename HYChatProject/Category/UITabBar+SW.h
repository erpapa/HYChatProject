//
//  UITabBar+SW.h
//  HYChatProject
//
//  Created by erpapa on 16/4/26.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITabBar(SW)
- (void)showBadgeAtItemIndex:(int)index; //显示小红点
- (void)hideBadgeAtItemIndex:(int)index; //隐藏小红点
@end
