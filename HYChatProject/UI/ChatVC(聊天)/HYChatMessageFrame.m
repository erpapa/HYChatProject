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
    CGFloat headViewY = CGRectGetMaxY(_timeLabelFrame) + kContentMarginTop;
    CGRect rightIconRect = CGRectMake(kScreenW - kHeadWidth - kHeadMargin, headViewY, kHeadWidth, kHeadWidth);
    CGRect leftIconRect = CGRectMake(kHeadMargin, headViewY, kHeadWidth, kHeadWidth);
    _headViewFrame = chatMessage.isOutgoing ? rightIconRect : leftIconRect;
    
    // 3.文本
    CGSize textSize = chatMessage.textLayout.textBoundingSize;
    _textViewFrame = CGRectMake(kTextPandingLeft, kTextPandingTop, textSize.width, textSize.height);
    
    // 4.背景
    CGRect rightContentRect,leftContentRect;
    switch (chatMessage.type) {
        case HYChatMessageTypeText:{
            CGFloat rightX = CGRectGetMinX(_headViewFrame) - kContentMargin - textSize.width;
            CGFloat leftX = CGRectGetMaxX(_headViewFrame) + kContentMargin;
            CGFloat contentY = CGRectGetMinY(_headViewFrame);
            CGFloat contentWidth = CGRectGetWidth(_textViewFrame) + kTextPandingLeft + kTextPandingRight;
            CGFloat contentHeight = CGRectGetHeight(_textViewFrame) + kTextPandingTop + kTextPandingBottom;
            rightContentRect = CGRectMake(rightX, contentY, contentWidth, contentHeight);
            leftContentRect = CGRectMake(leftX, contentY, contentWidth, contentHeight);
            
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
    _contentBgViewFrame = chatMessage.isOutgoing ? rightContentRect : leftContentRect;
    _cellHeight = CGRectGetMaxY(_contentBgViewFrame) + kContentMarginBottom;
}

@end
