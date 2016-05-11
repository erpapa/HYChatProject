//
//  HYChatModelUtils.h
//  HYChatProject
//
//  Created by erpapa on 16/4/28.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HYChatMessage.h"

#define kTimeHeight 28.0f          // 时间高度
#define kHeadWidth 38.0f           // 头像宽度
#define kHeadMargin 10.0f          // 头像距离屏幕边缘的间隔
#define kContentMargin 5.0f        // 聊天背景框距离头像的间隔
#define kContentMarginTop 10.0f    // 聊天背景框间隔与时间label的间隔
#define kContentMarginBottom 16.0f // 聊天背景框底部间隔
#define kTextPandingTop 8.0f       // 上间距8.0
#define kTextPandingBottom 10.0f   // 下间距10.0
#define kTextPandingLeft 16.0f     // 左间距16.0
#define kTextPandingRight 16.0f    // 右间距16.0

#define kFixedLineHeight 1         // 是否固定行高，0:不固定，1:固定
#define kTextLineHeight 20.0f      // 文本固定行高
#define kTextFontSize 16           // 文本字体大小
#define kTimeFontZise 12           // 时间字体大小
#define kTimeLabelColor [UIColor lightGrayColor] // 日期颜色
#define kMyTextColor [UIColor whiteColor]        // 我发的消息
#define kOtherTextColor [UIColor blackColor]     // 对方发送的消息

@interface HYChatMessageFrame : NSObject
@property (nonatomic, strong) HYChatMessage *chatMessage;
@property (nonatomic, assign, readonly) CGRect timeLabelFrame;      // 时间
@property (nonatomic, assign, readonly) CGRect contentBgViewFrame;  // 聊天背景
@property (nonatomic, assign, readonly) CGRect indicatorViewFrame;  // 转圈
@property (nonatomic, assign, readonly) CGRect headViewFrame;       // 头像
@property (nonatomic, assign, readonly) CGRect textViewFrame;       // 文字
@property (nonatomic, assign, readonly) CGFloat cellHeight;         // cell高度

@end
