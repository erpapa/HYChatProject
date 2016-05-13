//
//  HYDatabaseHandler+SingleChat.h
//  HYChatProject
//
//  Created by erpapa on 16/5/11.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYDatabaseHandler.h"

@class HYChatMessage;
@interface HYDatabaseHandler(SingleChat)

- (BOOL)addChatMessage:(HYChatMessage *)chatMessage;
- (BOOL)updateChatMessage:(HYChatMessage *)chatMessage;
- (BOOL)deleteChatMessage:(HYChatMessage *)chatMessage;
- (BOOL)recentChatMessages:(NSMutableArray *)chatMessages fromChatJID:(XMPPJID *)chatJid; // 最近20条聊天记录
- (BOOL)moreChatMessages:(NSMutableArray *)chatMessages fromChatJID:(XMPPJID *)chatJid beforeTime:(NSTimeInterval)time; // 更早的聊天记录(20条)

@end

@interface FMDatabase(SingleChat)
- (void)createSingleChatTable;
- (BOOL)addChatMessage:(HYChatMessage *)chatMessage;
- (BOOL)updateChatMessage:(HYChatMessage *)chatMessage;
- (BOOL)deleteChatMessage:(HYChatMessage *)chatMessage;
- (BOOL)recentChatMessages:(NSMutableArray *)chatMessages fromChatJID:(XMPPJID *)chatJid; // 最近20条聊天记录
- (BOOL)moreChatMessages:(NSMutableArray *)chatMessages fromChatJID:(XMPPJID *)chatJid beforeTime:(NSTimeInterval)time; // 更早的聊天记录(20条)
@end