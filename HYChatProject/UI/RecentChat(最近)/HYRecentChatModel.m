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

@implementation HYRecentChatModel

- (void)setBody:(NSString *)body
{
    _body = [body copy];
    [self setupLayout];
}

- (void)setupLayout
{
    NSData *jsonData = [self.body dataUsingEncoding:NSUTF8StringEncoding];
    // NSJSONReadingOptions -> 不可变（NSArray/NSDictionary）
    // NSJSONReadingMutableContainers -> 可变（NSMutableArray/NSMutableDictionary）
    // NSJSONReadingAllowFragments：允许JSON字符串最外层既不是NSArray也不是NSDictionary，但必须是有效的JSON Fragment
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
    if (error) { // 如果解析失败
        _attText = [self attributedString:self.body];
        return;
    }
    HYChatMessageType type = [self typeFromString:dict[@"type"]]; // 默认返回HYChatMessageTypeText
    NSString *bodyString = nil;
    switch (type) {
        case HYChatMessageTypeText:{
            bodyString = dict[@"data"];
            break;
        }
        case HYChatMessageTypeImage:{
            bodyString = @"[图片]";
            break;
        }
        case HYChatMessageTypeAudio:{
            bodyString = @"[语音]";
            break;
        }
        case HYChatMessageTypeVideo:{
            bodyString = @"[视频]";
            break;
        }
        default:
            break;
    }
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

- (HYChatMessageType)typeFromString:(NSString *)string
{
    if ([string isEqualToString:@"image"]) {
        return HYChatMessageTypeImage;
    } else if ([string isEqualToString:@"audio"]) {
        return HYChatMessageTypeAudio;
    } else if ([string isEqualToString:@"video"]) {
        return HYChatMessageTypeVideo;
    }
    return HYChatMessageTypeText;
}

@end
