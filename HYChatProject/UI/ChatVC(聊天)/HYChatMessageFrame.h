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

#define kTimeHeight 28.0f   // 时间高度
#define kHeadWidth 40.0f    // 头像宽度
#define kMargin 10.0f       // 头像距离屏幕边缘的间隔
#define kContentMargin 5.0f // 聊天背景框距离头像的间隔
#define kTextPanding 20.0f  // 内间距(10PI为透明背景，10PI为内容的间隔)

#define kTextFontSize 14    // 文本字体大小
#define kTimeFontZise 12    // 时间字体大小

@interface HYChatMessageFrame : NSObject
@property (nonatomic, strong) HYChatMessage *chatMessage;
@property (nonatomic, assign, readonly) CGRect timeLabelFrame;        // 时间
@property (nonatomic, assign, readonly) CGRect contentImageViewFrame; // 聊天背景
@property (nonatomic, assign, readonly) CGRect headViewFrame;         // 头像
@property (nonatomic, assign, readonly) CGRect textViewFrame;         // 文字
@property (nonatomic, assign, readonly) CGRect photoViewFrame;        // 照片
@property (nonatomic, assign, readonly) CGRect voiceViewFrame;        // 声音
@property (nonatomic, assign, readonly) CGRect voiceLabelFame;        // 声音长度
@property (nonatomic, assign, readonly) CGRect videoViewFame;         // 视频第一帧

@property (nonatomic, assign, readonly) CGFloat textCellHeight;       // 文本cell高度
@property (nonatomic, assign, readonly) CGFloat imageCellHeight;      // 图片cell高度
@property (nonatomic, assign, readonly) CGFloat voiceCellHeight;      // 声音cell高度
@property (nonatomic, assign, readonly) CGFloat videoCellHeight;      // 视频cell高度

@end
