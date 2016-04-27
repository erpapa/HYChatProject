//
//  HYBaseMessage.h
//  HYChatProject
//
//  Created by erpapa on 16/4/25.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HYBaseMessage : NSObject
@property (strong, nonatomic) XMPPJID *jid;

@property (copy, nonatomic) NSString *body; // 消息内容
@property (assign, nonatomic) NSTimeInterval time; // 时间timeIntervalSince1970
@end
