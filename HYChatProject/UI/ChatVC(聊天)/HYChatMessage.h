//
//  HYChatMessage.h
//  HYChatProject
//
//  Created by erpapa on 16/4/28.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  发送消息状态
 */
typedef NS_ENUM(NSUInteger, HYChatSendMessageStatus) {
    
    HYChatSendMessageStatusSuccess = 0,     // 发送成功
    HYChatSendMessageStatusFaild = 1,       // 发送失败
    HYChatSendMessageStatusSending = 2      // 发送中
    
};

typedef NS_ENUM(NSUInteger, HYChatReceiveMessageStatus) {
    HYChatReceiveMessageStatusSuccess = 0,   // 接收成功
    HYChatReceiveMessageStatusFaild = 1,     // 接收失败
    HYChatReceiveMessageStatusReceiving = 2  // 接收中
};

/**
 *  消息类型
 */
typedef NS_ENUM(NSInteger, HYChatMessageType) {
    HYChatMessageTypeText,  // 文字text
    HYChatMessageTypeImage, // 图片image
    HYChatMessageTypeAudio, // 声音Audio
    HYChatMessageTypeVideo // 视频video
};

@class YYTextLayout,HYAudioModel,HYVideoModel;
@interface HYChatMessage : NSObject
@property (nonatomic, assign) HYChatMessageType type;    // 消息类型
@property (nonatomic, strong) XMPPJID *jid;              // 聊天对象jid
@property (nonatomic, strong) NSString *messageID;       // 消息id
@property (nonatomic, strong) NSString *body;            // 原始消息

#pragma mark -  纯文本消息
@property (nonatomic, strong) NSString *textMessage;      // 文本内容
@property (nonatomic, strong) YYTextLayout *textLayout;   // 文字排版结果(在HYChatMessageFrame生成)

#pragma mark - 图片消息
@property (nonatomic, strong) NSString *imageUrl;         // 图片url(发送消息需要在本地图片另存为一份)
@property (nonatomic, assign) float imageWidth;           // 高度
@property (nonatomic, assign) float imageHeight;          // 宽度

#pragma mark - 语音消息
@property (nonatomic, strong) HYAudioModel *audioModel; // 音频model
@property (nonatomic, assign) BOOL isPlayingAudio;        // 正在播放
@property (nonatomic, assign) BOOL isRead;                // 是否播放过

#pragma mark - 视频、文件消息
@property (nonatomic, strong) HYVideoModel *videoModel;   // 视频model
@property (nonatomic, assign) BOOL isPlayingVideo;        // 是否正在播放video

@property (nonatomic, assign) HYChatSendMessageStatus sendStatus;          // 发送状态
@property (nonatomic, assign) HYChatReceiveMessageStatus receiveStatus;    // 接收状态
@property (nonatomic, assign) BOOL isOutgoing;            // 发出/接收
@property (nonatomic, assign) BOOL isHidenTime;           // 隐藏时间
@property (nonatomic, assign) BOOL isGroup;               // 是否群组消息
@property (nonatomic, assign) NSTimeInterval time;        // 时间 NSTimeIntervalSince1970
@property (nonatomic, strong) NSString *timeString;       // 时间字符串

- (instancetype)initWithJsonString:(NSString *)jsonString;
- (NSString *)jsonString; // 将模型转jsonString
@end

@class HYVideoDecoder;
@interface HYVideoModel : NSObject
@property (nonatomic, strong) HYVideoDecoder *videoDecoder; // 解码
@property (nonatomic, strong) NSString *videoThumbImageUrl; // video封面链接
@property (nonatomic, strong) NSString *videoUrl;         // video链接
@property (nonatomic, strong) NSString *videoLocalPath;   // video本地文件路径
@property (nonatomic, assign) float videoSize;            // 文件大小

@end
