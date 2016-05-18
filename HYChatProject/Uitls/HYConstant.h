//
//  HYConstant.h
//  HYChatProject
//
//  Created by erpapa on 16/4/24.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const HYChatDidReceiveMessage;   // 接收消息
extern NSString* const HYChatWithSomebody;        // 进入聊天页面
extern NSString* const HYChatJoinOrCreateGroup;   // 加入或者创建聊天室
extern NSString* const HYChatDidReceiveSingleMessage;   // 接收消息
extern NSString* const HYChatDidReceiveGroupMessage;   // 接收消息
extern NSString* const HYChatStartPlayAudio;      // 开始播放音频
extern NSString* const HYChatStopPlayAudio;       // 停止播放音频
extern NSString* const HYChatShieldNotifaction;   // 屏蔽通知
extern NSString* const HYChatNotShowBody;         // 不预览消息
extern NSString* const HYChatSaveWhenTakePhoto;   // 保存拍照

@interface HYConstant : NSObject

@end
