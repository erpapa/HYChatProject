//
//  HYRecentChatModel.h
//  HYChatProject
//
//  Created by erpapa on 16/4/22.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "XMPPJID.h"

@interface HYRecentChatModel : NSObject
@property (strong, nonatomic) NSData *icon; // 头像
@property (strong, nonatomic) NSString *jid; // 好友/群组jid
@property (copy, nonatomic) NSString *message; // 消息内容
@property (copy, nonatomic) NSString *timeString; // 时间
@property (assign, nonatomic) BOOL isGroup; // 是否是群组
@property (assign, nonatomic) NSInteger unreadCount; // 未读消息数
@end
