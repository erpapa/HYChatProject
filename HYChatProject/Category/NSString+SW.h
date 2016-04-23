//
//  NSString+SW.h
//  HYChatProject
//
//  Created by erpapa on 15/7/30.
//  Copyright (c) 2015年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#define kDomain @"erpapa.cn" // 域名
#define kResource @"iPhone" //resource 标识用户登录的客户端 iphone android
@class XMPPJID;
@interface NSString (SW)
/**
 *  计算字符串Size
 */
- (CGSize)sizeWithFont:(UIFont *)font;
- (CGSize)sizeWithFont:(UIFont *)font maxSize:(CGSize)maxSize;

/**
 *  日期
 */
- (NSString *)timeStringForExpress;
- (NSString *)timeStringForExpress1;

/**
 *  返回jid
 */
- (XMPPJID *)JID;
@end
