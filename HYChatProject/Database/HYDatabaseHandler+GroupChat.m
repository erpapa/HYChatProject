//
//  HYDatabaseHandler+GroupChat.m
//  HYChatProject
//
//  Created by erpapa on 16/5/11.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYDatabaseHandler+HY.h"
#import "HYLoginInfo.h"
#import "HYChatMessage.h"

@implementation HYDatabaseHandler(GroupChat)
- (BOOL)addGroupChatMessage:(HYChatMessage *)chatMessage
{
    __block BOOL result = YES;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db addGroupChatMessage:chatMessage];
    }];
    
    return result;
}
- (BOOL)deleteGroupChatMessage:(HYChatMessage *)chatMessage
{
    __block BOOL result = YES;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db deleteGroupChatMessage:chatMessage];
    }];
    
    return result;
}
- (BOOL)recentGroupChatMessages:(NSMutableArray *)chatMessages fromRoomJID:(XMPPJID *)roomJid
{
    __block BOOL result = YES;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db recentGroupChatMessages:chatMessages fromRoomJID:roomJid];
    }];
    
    return result;
}
- (BOOL)moreGroupChatMessages:(NSMutableArray *)chatMessages fromRoomJID:(XMPPJID *)roomJid beforeTime:(NSTimeInterval)time
{
    __block BOOL result = YES;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db moreGroupChatMessages:chatMessages fromRoomJID:roomJid beforeTime:time];
    }];
    
    return result;
}

@end

@implementation FMDatabase(GroupChat)

- (void)createGroupChatTable
{
    [self executeUpdate:@"CREATE TABLE IF NOT EXISTS T_CHAT_GROUPCHAT (msgid text primary key,myJid text,room text,occupant text,body text,time double,isOutgoing int,isRead int,sendStatus int,receiveStatus int,isGroup int)"];
}

- (BOOL)addGroupChatMessage:(HYChatMessage *)chatMessage
{
    HYLoginInfo *loginInfo = [HYLoginInfo sharedInstance];
    NSString* sql = [NSString stringWithFormat:@"INSERT OR REPLACE INTO T_CHAT_GROUPCHAT(msgid,myJid,room,occupant,body,time,isOutgoing,isRead,sendStatus,receiveStatus,isGroup) VALUES('%@','%@','%@','%@','%@','%lf','%d','%d','%d','%d','%d')",chatMessage.messageID,loginInfo.jid.full,chatMessage.jid.bare,chatMessage.jid.resource,[chatMessage jsonString],chatMessage.time,chatMessage.isOutgoing,chatMessage.isRead,chatMessage.sendStatus,chatMessage.receiveStatus,chatMessage.isGroup];
    
    if(![self executeUpdate:sql])
    {
        HYLog(@"%@ fail,%@",sql,[[self lastError] localizedDescription]);
        return NO;
    }
    return YES;
}
- (BOOL)deleteGroupChatMessage:(HYChatMessage *)chatMessage
{
    HYLoginInfo *loginInfo = [HYLoginInfo sharedInstance];
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM T_CHAT_GROUPCHAT WHERE myJid='%@' AND chatBare='%@'",[loginInfo.jid full],[chatMessage.jid bare]];
    if(![self executeUpdate:sql])
    {
        HYLog(@"%@ fail,%@",sql,[[self lastError] localizedDescription]);
        return NO;
    }
    return YES;
}
- (BOOL)recentGroupChatMessages:(NSMutableArray *)chatMessages fromRoomJID:(XMPPJID *)roomJid
{
    HYLoginInfo *loginInfo = [HYLoginInfo sharedInstance];
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM T_CHAT_GROUPCHAT WHERE myJid='%@' AND room='%@' order by time desc limit 0,20",[loginInfo.jid full],[roomJid bare]]; // desc 降序
    FMResultSet *rs = [self executeQuery:sql];
    if(rs == nil)
    {
        HYLog(@"%@ fail,%@",sql,[[self lastError] localizedDescription]);
        return NO;
    }
    NSMutableArray *tempArrray = [NSMutableArray array];
    while ([rs next])
    {
        HYChatMessage *message = [[HYChatMessage alloc] init];
        [self groupChatMessages:message fromResultSet:rs];
        [tempArrray addObject:message]; // 添加到models
    }
    [rs close];
    // 升序排序
    [chatMessages removeAllObjects];
    [chatMessages addObjectsFromArray:[[tempArrray reverseObjectEnumerator] allObjects]];// 将数组反转并添加
    return YES;
}
- (BOOL)moreGroupChatMessages:(NSMutableArray *)chatMessages fromRoomJID:(XMPPJID *)roomJid beforeTime:(NSTimeInterval)time
{
    HYLoginInfo *loginInfo = [HYLoginInfo sharedInstance];
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM T_CHAT_GROUPCHAT WHERE myJid='%@' AND room='%@' AND time < %lf order by time desc limit 0,20",[loginInfo.jid full], [roomJid bare], time];
    FMResultSet *rs = [self executeQuery:sql];
    if(rs == nil)
    {
        HYLog(@"%@ fail,%@",sql,[[self lastError] localizedDescription]);
        return NO;
    }
    
    
    NSMutableArray *tempArrray = [NSMutableArray array];
    while ([rs next])
    {
        HYChatMessage *message = [[HYChatMessage alloc] init];
        [self groupChatMessages:message fromResultSet:rs];
        [tempArrray addObject:message]; // 添加到models
    }
    [rs close];
    [chatMessages removeAllObjects];
    [chatMessages addObjectsFromArray:[[tempArrray reverseObjectEnumerator] allObjects]];// 将数组反转并添加
    return YES;
}

- (void)groupChatMessages:(HYChatMessage *)message fromResultSet:(FMResultSet *)rs
{
    NSString *messageID = [rs stringForColumn:@"msgid"];
    NSString *room = [rs stringForColumn:@"room"];
    NSString *occupant = [rs stringForColumn:@"occupant"];
    XMPPJID *chatJid = [XMPPJID jidWithString:room resource:occupant];
    NSString *body = [rs stringForColumn:@"body"];
    NSTimeInterval time = [rs doubleForColumn:@"time"];
    BOOL isRead = [rs intForColumn:@"isRead"];
    BOOL isOutgoing = [rs intForColumn:@"isOutgoing"];
    int sendStatus = [rs intForColumn:@"sendStatus"];
    int receiveStatus = [rs intForColumn:@"receiveStatus"];
    BOOL isGroup = [rs intForColumn:@"isGroup"];
    
    [message setBody:body];
    [message setMessageID:messageID];
    [message setJid:chatJid];
    [message setTime:time];
    [message setIsRead:isRead];
    [message setIsOutgoing:isOutgoing];
    [message setSendStatus:sendStatus];
    [message setReceiveStatus:receiveStatus];
    [message setIsGroup:isGroup];
}

@end
