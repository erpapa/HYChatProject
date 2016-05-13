//
//  HYChatMessage.m
//  HYChatProject
//
//  Created by erpapa on 16/4/28.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYChatMessage.h"
#import "GJCFAudioModel.h"
#import "HYLoginInfo.h"

@implementation HYChatMessage

- (instancetype)init
{
    self = [super init];
    if (self) {
        // 生成messageID
        NSString *timeString = [NSString stringWithFormat:@"%lf",[[NSDate date] timeIntervalSince1970]];
        _messageID = [timeString stringByReplacingOccurrencesOfString:@"." withString:@""];
        
    }
    return self;
}

- (instancetype)initWithJsonString:(NSString *)jsonString
{
    self = [self init];
    if (self) {
        self.body = jsonString;
    }
    return self;
}

- (void)setBody:(NSString *)body
{
    _body = body;
    NSData *jsonData = [body dataUsingEncoding:NSUTF8StringEncoding];
    // NSJSONReadingOptions -> 不可变（NSArray/NSDictionary）
    // NSJSONReadingMutableContainers -> 可变（NSMutableArray/NSMutableDictionary）
    // NSJSONReadingAllowFragments：允许JSON字符串最外层既不是NSArray也不是NSDictionary，但必须是有效的JSON Fragment
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
    if (error) { // 如果解析失败
        self.type = HYChatMessageTypeText;
        self.textMessage = body;
        return;
    }
    self.type = [self typeFromString:dict[@"type"]]; // 默认返回HYChatMessageTypeText
    switch (self.type) {
        case HYChatMessageTypeText:{
            self.textMessage = dict[@"data"];
            break;
        }
        case HYChatMessageTypeImage:{
            self.imageUrl = dict[@"imageUrl"];
            self.imageWidth = [dict[@"imageWidth"] floatValue];
            self.imageHeight = [dict[@"imageHeight"] floatValue];
            break;
        }
        case HYChatMessageTypeAudio:{
            self.audioModel = [[GJCFAudioModel alloc] init];
            self.audioModel.remotePath = dict[@"audioUrl"];
            self.audioModel.duration = [dict[@"audioDurction"] floatValue];
            break;
        }
        case HYChatMessageTypeVideo:{
            self.videoModel = [[HYVideoModel alloc] init];
            self.videoModel.videoThumbImageUrl = dict[@"videoThumbImageUrl"];
            self.videoModel.videoUrl = dict[@"videoUrl"];
            self.videoModel.videoSize = [dict[@"videoSize"] floatValue];
            break;
        }
        default:
            break;
    }
}

- (NSString *)jsonString
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"type"] = [self stringFromType:self.type];
    switch (self.type) {
        case HYChatMessageTypeText:{
            dict[@"data"] = self.textMessage;
            break;
        }
        case HYChatMessageTypeImage:{
            dict[@"imageUrl"] = [NSString stringWithFormat:@"%@",self.imageUrl];
            dict[@"imageWidth"] = [NSString stringWithFormat:@"%f",self.imageWidth];
            dict[@"imageHeight"] = [NSString stringWithFormat:@"%f",self.imageHeight];
            break;
        }
        case HYChatMessageTypeAudio:{
            dict[@"audioUrl"] = [NSString stringWithFormat:@"%@",self.audioModel.remotePath];
            dict[@"audioDurction"] = [NSString stringWithFormat:@"%.1f",self.audioModel.duration];
            break;
        }
        case HYChatMessageTypeVideo:{
            dict[@"videoThumbImageUrl"] = [NSString stringWithFormat:@"%@",self.videoModel.videoThumbImageUrl];
            dict[@"videoUrl"] = [NSString stringWithFormat:@"%@",self.videoModel.videoUrl];
            dict[@"videoSize"] = [NSString stringWithFormat:@"%.1f",self.videoModel.videoSize];
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


@implementation HYVideoModel

- (NSString *)videoLocalPath
{
    if (self.videoUrl.length) {
        NSString *document = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *localFilePath = [NSString stringWithFormat:@"%@/videoCache/%@",document,[self.videoUrl lastPathComponent]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:localFilePath]) { // 如果文件已经下载完成
            return localFilePath;
        } else {
            return nil;
        }
    }
    return nil;
}

@end
