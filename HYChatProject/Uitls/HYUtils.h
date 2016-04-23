//
//  HYUtils.h
//  HYChatProject
//
//  Created by erpapa on 16/4/20.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HYUtils : NSObject
/**
 *  切换控制器
 */
+ (void)initRootViewController;

/**
 *  hud
 */
+ (void)showWaitingMsg:(NSString *)msg;
+ (void)clearWaitingMsg;
+ (void)clearWaitingMsgWithDelay:(float)delay;
+ (void)alertWithTitle:(NSString *)title;
+ (void)alertWithNormalMsg:(NSString *)msg;
+ (void)alertWithSuccessMsg:(NSString *)msg;
+ (void)alertWithErrorMsg:(NSString *)msg;

/**
 *  颜色
 */
+ (NSString *)stringFromColor:(UIColor*)aColor;
+ (UIColor *)colorFromString:(NSString*)aString;

@end
