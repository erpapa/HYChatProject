//
//  HYRecentChatModel.h
//  HYChatProject
//
//  Created by erpapa on 16/4/22.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HYRecentChatModel : NSObject
@property (nonatomic, strong) XMPPJID *jid; // 好友/群组jid
@property (nonatomic, copy) NSString *body; // 消息内容
@property (nonatomic, assign) NSTimeInterval time; // 时间 NSTimeIntervalSince1970
@property (nonatomic, assign) BOOL isGroup; // 是否是群组
@property (nonatomic, assign) int unreadCount; // 未读消息数
@end
