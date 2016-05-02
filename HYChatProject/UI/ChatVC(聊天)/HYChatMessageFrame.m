//
//  HYChatModelUtils.m
//  HYChatProject
//
//  Created by erpapa on 16/4/28.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYChatMessageFrame.h"
#import "YYText.h"
#import "YYWebImage.h"
#import "HYEmoticonTool.h"

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
    _textLayout = [self layout]; // 生成排版结果
    CGSize textSize = _textLayout.textBoundingSize;
    _textViewFrame = CGRectMake(kTextPandingLeft, kTextPandingTop, textSize.width, textSize.height);
    
    // 4.背景
    CGRect rightContentRect,leftContentRect;
    switch (chatMessage.type) {
        case HYChatMessageTypeText:{
            CGFloat contentWidth = CGRectGetWidth(_textViewFrame) + kTextPandingLeft + kTextPandingRight;
            CGFloat contentHeight = CGRectGetHeight(_textViewFrame) + kTextPandingTop + kTextPandingBottom;
            CGFloat contentY = CGRectGetMinY(_headViewFrame);
            CGFloat rightX = CGRectGetMinX(_headViewFrame) - kContentMargin - contentWidth;
            CGFloat leftX = CGRectGetMaxX(_headViewFrame) + kContentMargin;
            
            rightContentRect = CGRectMake(rightX, contentY, contentWidth, contentHeight);
            leftContentRect = CGRectMake(leftX, contentY, contentWidth, contentHeight);
            
            break;
        }
        case HYChatMessageTypeImage:{
            
            break;
        }
        case HYChatMessageTypeAudio:{
            
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

- (YYTextLayout *)layout
{
    if (self.chatMessage.type != HYChatMessageTypeText || self.chatMessage.data.length == 0) {
        return nil;
    }
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:self.chatMessage.data];
    text.yy_font = [UIFont systemFontOfSize:kTextFontSize]; // 字体
    text.yy_color = self.chatMessage.isOutgoing ? kMyTextColor : kOtherTextColor; //字体颜色
    // 匹配 [表情]
    HYEmoticonTool *emoticonTool = [HYEmoticonTool sharedInstance];
    NSArray<NSTextCheckingResult *> *emoticonResults = [emoticonTool.emoticonRegex matchesInString:text.string options:kNilOptions range:NSMakeRange(0, text.length)];
    NSUInteger emoClipLength = 0;
    for (NSTextCheckingResult *emo in emoticonResults) {
        if (emo.range.location == NSNotFound && emo.range.length <= 1) continue;
        NSRange range = emo.range;
        range.location -= emoClipLength;
        if ([text yy_attribute:YYTextHighlightAttributeName atIndex:range.location]) continue;
        if ([text yy_attribute:YYTextAttachmentAttributeName atIndex:range.location]) continue;
        NSString *emoString = [text.string substringWithRange:range];
        NSString *imageKey = [emoticonTool.emoticonDict objectForKey:emoString];
        NSData *data = [NSData dataWithContentsOfFile:[emoticonTool gifPathForKey:imageKey]];
        YYImage *image = [YYImage imageWithData:data scale:2.0];//由于是@2x的图片，设置其scale为2.0
        if (!image) continue;
        NSAttributedString *emoText = nil;
        if (kFixedLineHeight) {
            emoText = [NSAttributedString yy_attachmentStringWithEmojiImage:image fontSize:kTextFontSize];
        } else {
            YYAnimatedImageView *imageView = [[YYAnimatedImageView alloc] initWithImage:image];
            emoText = [NSAttributedString yy_attachmentStringWithContent:imageView contentMode:UIViewContentModeCenter attachmentSize:imageView.bounds.size alignToFont:[UIFont systemFontOfSize:kTextFontSize] alignment:YYTextVerticalAlignmentCenter];
        }
        [text replaceCharactersInRange:range withAttributedString:emoText];
        emoClipLength += range.length - 1;
    }
    CGSize maxSize = CGSizeMake(kScreenW - (kHeadMargin + kHeadWidth + kTextPandingLeft) * 2, CGFLOAT_MAX); // label的maxSize
    // 设置固定行高
    if (kFixedLineHeight) {
        YYTextLinePositionSimpleModifier *modifier = [YYTextLinePositionSimpleModifier new];
        modifier.fixedLineHeight = kTextLineHeight; // 设置固定行高
        YYTextContainer *container = [YYTextContainer new]; // 容器
        container.size = maxSize;
        container.linePositionModifier = modifier;
        return [YYTextLayout layoutWithContainer:container text:text];
    }
    
    return [YYTextLayout layoutWithContainerSize:maxSize text:text];
}

@end
