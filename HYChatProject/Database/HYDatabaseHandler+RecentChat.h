//
//  HYDatabaseHandler+RecentChat.h
//  HYChatProject
//
//  Created by erpapa on 16/4/24.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYDatabaseHandler.h"
@class HYRecentChatModel;
@interface HYDatabaseHandler(RecentChat)
- (BOOL)updateRecentChatModel:(HYRecentChatModel *)recentChatModel; // 更新
- (BOOL)insertRecentChatModel:(HYRecentChatModel *)recentChatModel; // 插入
- (BOOL)deleteRecentChatModel:(HYRecentChatModel *)recentChatModel; // 删除记录
- (BOOL)recentChatModels:(NSMutableArray *)models; //返回最近聊天记录
- (BOOL)recentChatModel:(HYRecentChatModel *)recentChatModel fromJid:(XMPPJID *)jid; // 通过jid获取最近聊天记录

@end

@interface FMDatabase(RecentChat)
- (void)createRecentChatTable;
- (BOOL)updateRecentChatModel:(HYRecentChatModel *)recentChatModel;
- (BOOL)insertRecentChatModel:(HYRecentChatModel *)recentChatModel; // 插入
- (BOOL)recentChatModels:(NSMutableArray *)models;
- (BOOL)recentChatModel:(HYRecentChatModel *)recentChatModel fromJid:(XMPPJID *)jid;
- (BOOL)deleteRecentChatModel:(HYRecentChatModel *)recentChatModel;
@end