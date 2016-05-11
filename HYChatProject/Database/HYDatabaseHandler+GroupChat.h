//
//  HYDatabaseHandler+GroupChat.h
//  HYChatProject
//
//  Created by erpapa on 16/5/11.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYDatabaseHandler.h"

@class HYChatMessage;
@interface HYDatabaseHandler(GroupChat)
- (BOOL)addGroupChatMessage:(HYChatMessage *)chatMessage;
- (BOOL)deleteGroupChatMessage:(HYChatMessage *)chatMessage;
- (BOOL)recentGroupChatMessages:(NSMutableArray *)chatMessages fromRoomJID:(XMPPJID *)roomJid; // 最近20条聊天记录
- (BOOL)moreGroupChatMessages:(NSMutableArray *)chatMessages fromRoomJID:(XMPPJID *)roomJid beforeTime:(NSTimeInterval)time; // 更早的聊天记录(20条)
@end

@interface FMDatabase(GroupChat)
- (void)createGroupChatTable;
- (BOOL)addGroupChatMessage:(HYChatMessage *)chatMessage;
- (BOOL)deleteGroupChatMessage:(HYChatMessage *)chatMessage;
- (BOOL)recentGroupChatMessages:(NSMutableArray *)chatMessages fromRoomJID:(XMPPJID *)roomJid; // 最近20条聊天记录
- (BOOL)moreGroupChatMessages:(NSMutableArray *)chatMessages fromRoomJID:(XMPPJID *)roomJid beforeTime:(NSTimeInterval)time; // 更早的聊天记录(20条)

@end
