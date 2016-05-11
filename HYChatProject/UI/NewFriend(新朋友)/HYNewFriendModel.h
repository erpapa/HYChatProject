//
//  HYNewFriendModel.h
//  HYChatProject
//
//  Created by erpapa on 16/5/11.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HYNewFriendModel : NSObject
@property (nonatomic, strong) XMPPJID *jid;        // 好友/群组jid
@property (nonatomic, strong) NSString *body;      // 消息内容
@property (nonatomic, assign) NSTimeInterval time; // 时间 NSTimeIntervalSince1970
@end
