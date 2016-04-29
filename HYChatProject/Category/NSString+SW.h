//
//  NSString+SW.h
//  HYChatProject
//
//  Created by erpapa on 15/7/30.
//  Copyright (c) 2015年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

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
@end
