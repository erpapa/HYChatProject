//
//  HYChatMessage.m
//  HYChatProject
//
//  Created by erpapa on 16/4/28.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYChatMessage.h"

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
            self.data = jsonString;
            return self;
        }
        HYChatMessageType type = [self typeFromString:dict[@"type"]]; // 默认返回HYChatMessageTypeText
        self.type = type;
        self.data = dict[@"data"];
        switch (type) {
            case HYChatMessageTypeText:{
                break;
            }
            case HYChatMessageTypeImage:{
                self.width = [dict[@"width"] floatValue];
                self.height = [dict[@"height"] floatValue];
                self.size = [dict[@"size"] floatValue];
                break;
            }
            case HYChatMessageTypeAudio:{
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

- (NSString *)jsonString
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"type"] = [self stringFromType:self.type];
    dict[@"data"] = self.data;
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
        case HYChatMessageTypeAudio:{
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
        case HYChatMessageTypeAudio:{
            str = @"audio";
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
    } else if ([string isEqualToString:@"audio"]) {
        return HYChatMessageTypeAudio;
    } else if ([string isEqualToString:@"video"]) {
        return HYChatMessageTypeVideo;
    }
    return HYChatMessageTypeText;
}
@end
