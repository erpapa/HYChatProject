//
//  HYUser.h
//  HYChatProject
//
//  Created by erpapa on 16/4/24.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XMPPvCardTemp;
@interface HYUser : NSObject

@property (strong, nonatomic) XMPPJID *jid; // 用户jid
@property (strong, nonatomic) XMPPvCardTemp *vCard; // 用户名片
@end
