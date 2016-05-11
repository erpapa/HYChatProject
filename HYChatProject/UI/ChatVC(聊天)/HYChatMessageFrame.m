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
#import "GJCFAudioModel.h"

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
    chatMessage.textLayout = [self textLayout]; // 生成排版结果
    CGSize textSize = chatMessage.textLayout.textBoundingSize;
    _textViewFrame = CGRectMake(kTextPandingLeft, kTextPandingTop, textSize.width, textSize.height);
    
    // 4.背景
    CGFloat contentWidth, contentHeight, contentY, contentRightX, contentLeftX;
    switch (chatMessage.type) {
        case HYChatMessageTypeText:{
            contentWidth = CGRectGetWidth(_textViewFrame) + kTextPandingLeft + kTextPandingRight;
            contentHeight = CGRectGetHeight(_textViewFrame) + kTextPandingTop + kTextPandingBottom;
            contentY = CGRectGetMinY(_headViewFrame);
            contentRightX = CGRectGetMinX(_headViewFrame) - kContentMargin - contentWidth;
            contentLeftX = CGRectGetMaxX(_headViewFrame) + kContentMargin;
            break;
        }
        case HYChatMessageTypeImage:{
            
            break;
        }
        case HYChatMessageTypeAudio:{
            contentWidth = [self getContentWidthByAudioDuration:chatMessage.audioModel.duration];
            contentHeight = CGRectGetHeight(_headViewFrame);
            contentY = CGRectGetMinY(_headViewFrame);
            contentRightX = CGRectGetMinX(_headViewFrame) - kContentMargin - contentWidth;
            contentLeftX = CGRectGetMaxX(_headViewFrame) + kContentMargin;
            break;
        }
        case HYChatMessageTypeVideo:{
            
            break;
        }
            
        default:
            break;
    }
    
    CGRect rightContentRect = CGRectMake(contentRightX, contentY, contentWidth, contentHeight);
    CGRect leftContentRect = CGRectMake(contentLeftX, contentY, contentWidth, contentHeight);
    _contentBgViewFrame = chatMessage.isOutgoing ? rightContentRect : leftContentRect;
    
    CGFloat indicatorWidth = kHeadWidth - kTextPandingTop * 2;
    CGRect rightIndicatorRect = CGRectMake(CGRectGetMinX(_contentBgViewFrame) - indicatorWidth, CGRectGetMaxY(_contentBgViewFrame) - indicatorWidth - kTextPandingTop, indicatorWidth, indicatorWidth);
    CGRect leftIndicatorRect = CGRectMake(CGRectGetMaxX(_contentBgViewFrame), CGRectGetMaxY(_contentBgViewFrame) - indicatorWidth - kTextPandingTop, indicatorWidth, indicatorWidth);
    _indicatorViewFrame = chatMessage.isOutgoing ? rightIndicatorRect : leftIndicatorRect;
    
    
    _cellHeight = CGRectGetMaxY(_contentBgViewFrame) + kContentMarginBottom;
}

- (YYTextLayout *)textLayout
{
    if (self.chatMessage.type != HYChatMessageTypeText || self.chatMessage.textMessage.length == 0) {
        return nil;
    }
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:self.chatMessage.textMessage];
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

- (CGFloat)getContentWidthByAudioDuration:(CGFloat)audioDuration
{
    if (audioDuration < 3) {
        return 132/2 - 6;
    }
    else if (audioDuration < 11)
    {
        return 132/2 - 6 + (audioDuration - 3) * (252/2 - 132/2 - 6)/13;
    }
    else if (audioDuration < 60)
    {
        return 132/2 - 6 + (8  + ((NSInteger)((audioDuration - 10)/10))) * (252/2 - 132/2 - 6)/(13);
    }
    return 252/2 - 6;
}

@end
