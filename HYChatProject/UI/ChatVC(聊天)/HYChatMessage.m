//
//  HYChatMessage.m
//  HYChatProject
//
//  Created by erpapa on 16/4/28.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYChatMessageFrame.h"
#import "YYAnimatedImageView.h"
#import "YYText.h"
#import "YYImage.h"
#import "HYEmoticonTool.h"

@implementation HYChatMessage

- (instancetype)initWithJsonString:(NSString *)jsonString
{
    self = [super init];
    if (self) {
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        // NSJSONReadingOptions -> 不可变（NSArray/NSDictionary）
        // NSJSONReadingMutableContainers -> 可变（NSMutableArray/NSMutableDictionary）
        // NSJSONReadingAllowFragments：允许JSON字符串最外层既不是NSArray也不是NSDictionary，但必须是有效的JSON Fragment
        NSError *error = nil;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
        if (error) { // 如果解析失败
            self.type = HYChatMessageTypeText;
            self.body = jsonString;
            [self layoutText];
            return self;
        }
        HYChatMessageType type = [self typeFromString:dict[@"type"]]; // 默认返回HYChatMessageTypeText
        self.type = type;
        self.body = dict[@"body"];
        switch (type) {
            case HYChatMessageTypeText:{
                [self layoutText];
                break;
            }
            case HYChatMessageTypeImage:{
                self.width = [dict[@"width"] floatValue];
                self.height = [dict[@"height"] floatValue];
                self.size = [dict[@"size"] floatValue];
                break;
            }
            case HYChatMessageTypeVoice:{
                self.duraction = [dict[@"duraction"] floatValue];
                self.size = [dict[@"size"] floatValue];
                break;
            }
            case HYChatMessageTypeVideo:{
                self.duraction = [dict[@"duraction"] floatValue];
                self.size = [dict[@"size"] floatValue];
                break;
            }
            default:
                break;
        }
    }
    return self;
}

- (void)layoutText
{
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:self.body];
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
        YYImage *image = [YYImage imageWithData:data];//修改表情大小
        if (!image) continue;
        NSAttributedString *emoText = [NSAttributedString yy_attachmentStringWithEmojiImage:image fontSize:kTextFontSize];
        [text replaceCharactersInRange:range withAttributedString:emoText];
        emoClipLength += range.length - 1;
    }
    
    CGSize size = CGSizeMake(kScreenW - kHeadWidth * 2 - (kMargin + kContentMargin) * 2, CGFLOAT_MAX);
    self.textLayout = [YYTextLayout layoutWithContainerSize:size text:text];
}

- (NSString *)jsonString
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"type"] = [self stringFromType:self.type];
    dict[@"body"] = self.body;
    switch (self.type) {
        case HYChatMessageTypeText:{
            break;
        }
        case HYChatMessageTypeImage:{
            dict[@"width"] = [NSString stringWithFormat:@"%f",self.width];
            dict[@"height"] = [NSString stringWithFormat:@"%f",self.height];
            dict[@"size"] = [NSString stringWithFormat:@"%f",self.size];
            break;
        }
        case HYChatMessageTypeVoice:{
            dict[@"duraction"] = [NSString stringWithFormat:@"%f",self.duraction];
            dict[@"size"] = [NSString stringWithFormat:@"%f",self.size];
            break;
        }
        case HYChatMessageTypeVideo:{
            dict[@"duraction"] = [NSString stringWithFormat:@"%f",self.duraction];
            dict[@"size"] = [NSString stringWithFormat:@"%f",self.size];
            break;
        }
        default:
            break;
    }
    // NSJSONWritingPrettyPrinted 有换位符
    // 不设置就是一个纯粹的字符串，使用0
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (NSString *)stringFromType:(HYChatMessageType)type
{
    NSString *str = nil;
    switch (type) {
        case HYChatMessageTypeText:{
            str = @"text";
            break;
        }
        case HYChatMessageTypeImage:{
            str = @"image";
            break;
        }
        case HYChatMessageTypeVoice:{
            str = @"voice";
            break;
        }
        case HYChatMessageTypeVideo:{
            str = @"video";
            break;
        }
        default:{
            str = @"text";
            break;
        }
    }
    return str;
}

- (HYChatMessageType)typeFromString:(NSString *)string
{
    if ([string isEqualToString:@"image"]) {
        return HYChatMessageTypeImage;
    } else if ([string isEqualToString:@"voice"]) {
        return HYChatMessageTypeVoice;
    } else if ([string isEqualToString:@"video"]) {
        return HYChatMessageTypeVideo;
    }
    return HYChatMessageTypeText;
}
@end
