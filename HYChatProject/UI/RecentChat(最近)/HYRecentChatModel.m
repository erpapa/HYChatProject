//
//  HYRecentChatModel.m
//  HYChatProject
//
//  Created by erpapa on 16/4/22.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYRecentChatModel.h"
#import "HYChatMessage.h"
#import "HYEmoticonTool.h"
#import "YYImage.h"
#import "YYText.h"
#import "HYUtils.h"

@implementation HYRecentChatModel

- (void)setBody:(NSString *)body
{
    _body = [body copy];
    NSString *bodyString = [HYUtils bodyFromJsonString:_body];
    _attText = [self attributedString:bodyString];
}

- (NSAttributedString *)attributedString:(NSString *)string
{
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@",string]];
    text.yy_font = [UIFont systemFontOfSize:14]; // 字体
    text.yy_color = [UIColor lightGrayColor];
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
        NSAttributedString *emoText = [NSAttributedString yy_attachmentStringWithEmojiImage:image fontSize:14];
        [text replaceCharactersInRange:range withAttributedString:emoText];
        emoClipLength += range.length - 1;
    }
    return text;
}

@end
