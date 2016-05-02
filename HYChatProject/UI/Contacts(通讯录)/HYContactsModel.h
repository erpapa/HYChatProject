//
//  HYContactsModel.h
//  HYChatProject
//
//  Created by erpapa on 16/4/22.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HYContactsModel : NSObject
@property (nonatomic, copy) XMPPJID *jid;
@property (nonatomic, copy) NSString *displayName;    // 好友名称
@property (nonatomic, copy) NSString *firstLetterStr; // 首字母字符串
@property (nonatomic, assign) NSInteger sectionNum; // 好友状态 0-[在线] 1-[忙碌] 2-[离线]
@property (nonatomic, assign) BOOL isGroup; // 是否是群组
@end
