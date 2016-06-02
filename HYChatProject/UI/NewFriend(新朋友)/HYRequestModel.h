//
//  HYRequestModel.h
//  HYChatProject
//
//  Created by erpapa on 16/5/11.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HYRequestModel : NSObject
@property (nonatomic, strong) XMPPJID *jid;        // 好友/群组jid
@property (nonatomic, strong) XMPPJID *roomJid;    // 群组
@property (nonatomic, strong) NSString *reason;    // 邀请理由
@property (nonatomic, strong) NSString *body;      // 消息内容
@property (nonatomic, assign) NSTimeInterval time; // 时间 NSTimeIntervalSince1970
@property (nonatomic, assign) int requestType;     // 请求类型 0:已添加好友 1:好友请求 2:群邀请
@property (nonatomic, assign) int option;          // 操作类型 0:没有处理 1:同意 2:拒绝
@end
