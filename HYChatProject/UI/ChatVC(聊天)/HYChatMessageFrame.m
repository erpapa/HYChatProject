//
//  HYChatModelUtils.m
//  HYChatProject
//
//  Created by erpapa on 16/4/28.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYChatMessageFrame.h"
#import "YYTextLayout.h"

@implementation HYChatMessageFrame

- (void)setChatMessage:(HYChatMessage *)chatMessage
{
    _chatMessage = chatMessage;
    // ######## 计算cell子控件的frame #############
    
    // 1.时间
    if (chatMessage.isHidenTime == NO) {
        _timeLabelFrame = CGRectMake(0, 0, kScreenW, kTimeHeight);
    }
    // 2.头像
    CGFloat headViewY = CGRectGetMaxY(_timeLabelFrame) + kMargin;
    CGRect rightIconRect = CGRectMake(kScreenW - kHeadWidth - kMargin, headViewY, kHeadWidth, kHeadWidth);
    CGRect leftIconRect = CGRectMake(kMargin, headViewY, kHeadWidth, kHeadWidth);
    _headViewFrame = chatMessage.isOutgoing ? rightIconRect : leftIconRect;
    
    // 3.文本
    CGSize textSize = chatMessage.textLayout.textBoundingSize;
    _textViewFrame = CGRectMake(kTextPanding, kTextPanding, textSize.width, textSize.height);
    
    // 4.照片
    
    // 5.声音
    
    // 6.视频
    
    // 7.背景
    CGRect rightContentRect,leftContentRect;
    switch (chatMessage.type) {
        case HYChatMessageTypeText:{
            CGFloat rightX = CGRectGetMinX(_headViewFrame) - kContentMargin - textSize.width;
            CGFloat leftX = CGRectGetMaxX(_headViewFrame) + kContentMargin;
            CGFloat contentY = CGRectGetMinY(_headViewFrame);
            CGFloat contentWidth = CGRectGetWidth(_textViewFrame) + kTextPanding * 2;
            CGFloat contentHeight = CGRectGetHeight(_textViewFrame) + kTextPanding * 2;
            rightContentRect = CGRectMake(rightX, contentY, contentWidth, contentHeight);
            leftContentRect = CGRectMake(leftX, contentY, contentWidth, contentHeight);
            _textCellHeight = CGRectGetMaxY(leftContentRect);
            break;
        }
        case HYChatMessageTypeImage:{
            
            break;
        }
        case HYChatMessageTypeVoice:{
            
            break;
        }
        case HYChatMessageTypeVideo:{
            
            break;
        }
            
        default:
            break;
    }
    _contentImageViewFrame = chatMessage.isOutgoing ? rightContentRect : leftContentRect;
}

@end
