//
//  HYDatabaseHandler+SingleChat.m
//  HYChatProject
//
//  Created by erpapa on 16/5/11.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYDatabaseHandler+HY.h"
#import "HYLoginInfo.h"
#import "HYChatMessage.h"

@implementation HYDatabaseHandler(SingleChat)

- (BOOL)addChatMessage:(HYChatMessage *)chatMessage
{
    __block BOOL result = YES;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db addChatMessage:chatMessage];
    }];
    
    return result;
}

- (BOOL)updateChatMessage:(HYChatMessage *)chatMessage
{
    __block BOOL result = YES;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db updateChatMessage:chatMessage];
    }];
    
    return result;
}

- (BOOL)deleteChatMessage:(HYChatMessage *)chatMessage
{
    __block BOOL result = YES;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db deleteChatMessage:chatMessage];
    }];
    
    return result;
}
// 最近20条聊天记录
- (BOOL)recentChatMessages:(NSMutableArray *)chatMessages fromChatJID:(XMPPJID *)chatJid
{
    __block BOOL result = YES;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db recentChatMessages:chatMessages fromChatJID:chatJid];
    }];
    
    return result;
}
// 更早的聊天记录(20条)
- (BOOL)moreChatMessages:(NSMutableArray *)chatMessages fromChatJID:(XMPPJID *)chatJid beforeTime:(NSTimeInterval)time
{
    __block BOOL result = YES;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db moreChatMessages:chatMessages fromChatJID:chatJid beforeTime:time];
    }];
    
    return result;
}

@end

@implementation FMDatabase(SingleChat)

- (void)createSingleChatTable
{
    [self executeUpdate:@"CREATE TABLE IF NOT EXISTS T_CHAT_SINGLECHAT (msgid text primary key,myJid text,chatBare text,chatResource text,body text,time double,isOutgoing int,isRead int, sendStatus int,receiveStatus int,isGroup int)"];
}

- (BOOL)addChatMessage:(HYChatMessage *)chatMessage
{
    HYLoginInfo *loginInfo = [HYLoginInfo sharedInstance];
    HYChatSendMessageStatus sendStatus = chatMessage.sendStatus;
    if (sendStatus == HYChatSendMessageStatusSending) {
        sendStatus = HYChatSendMessageStatusFaild;
    }
    HYChatReceiveMessageStatus receiveStatus = chatMessage.receiveStatus;
    if (receiveStatus == HYChatReceiveMessageStatusReceiving) {
        receiveStatus = HYChatReceiveMessageStatusFaild;
    }
    NSString* sql = [NSString stringWithFormat:@"INSERT OR REPLACE INTO T_CHAT_SINGLECHAT(msgid,myJid,chatBare,chatResource,body,time,isOutgoing,isRead,sendStatus,receiveStatus,isGroup) VALUES('%@','%@','%@','%@','%@','%lf','%d','%d','%d','%d','%d')",chatMessage.messageID,loginInfo.jid.full,chatMessage.jid.bare,chatMessage.jid.resource,[chatMessage jsonString],chatMessage.time,chatMessage.isOutgoing,chatMessage.isRead,sendStatus,receiveStatus,chatMessage.isGroup];
    
    if(![self executeUpdate:sql])
    {
        HYLog(@"%@ fail,%@",sql,[[self lastError] localizedDescription]);
        return NO;
    }
    return YES;
    
}

- (BOOL)updateChatMessage:(HYChatMessage *)chatMessage
{
    HYLoginInfo *loginInfo = [HYLoginInfo sharedInstance];
    HYChatSendMessageStatus sendStatus = chatMessage.sendStatus;
    if (sendStatus == HYChatSendMessageStatusSending) {
        sendStatus = HYChatSendMessageStatusFaild;
    }
    HYChatReceiveMessageStatus receiveStatus = chatMessage.receiveStatus;
    if (receiveStatus == HYChatReceiveMessageStatusReceiving) {
        receiveStatus = HYChatReceiveMessageStatusFaild;
    }
    NSString *sql = [NSString stringWithFormat:@"UPDATE T_CHAT_SINGLECHAT SET isRead=%d,sendStatus=%d,receiveStatus=%d WHERE msgid='%@' AND myJid='%@' AND chatBare='%@'",chatMessage.isRead,sendStatus,receiveStatus,chatMessage.messageID,loginInfo.jid.full,chatMessage.jid.bare];
    if(![self executeUpdate:sql])
    {
        HYLog(@"%@ fail,%@",sql,[[self lastError] localizedDescription]);
        return NO;
    }
    return YES;
}

- (BOOL)deleteChatMessage:(HYChatMessage *)chatMessage
{
    HYLoginInfo *loginInfo = [HYLoginInfo sharedInstance];
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM T_CHAT_SINGLECHAT WHERE msgid='%@' AND myJid='%@' AND chatBare='%@'", chatMessage.messageID, [loginInfo.jid full],[chatMessage.jid bare]];
    if(![self executeUpdate:sql])
    {
        HYLog(@"%@ fail,%@",sql,[[self lastError] localizedDescription]);
        return NO;
    }
    return YES;
    
}
// 最近20条聊天记录
- (BOOL)recentChatMessages:(NSMutableArray *)chatMessages fromChatJID:(XMPPJID *)chatJid
{
    HYLoginInfo *loginInfo = [HYLoginInfo sharedInstance];
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM T_CHAT_SINGLECHAT WHERE myJid='%@' AND chatBare='%@' order by time desc limit 0,20",[loginInfo.jid full], [chatJid bare]]; // desc 降序
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
        [self chatMessages:message fromResultSet:rs];
        [tempArrray addObject:message]; // 添加到models
    }
    [rs close];
    // 升序排序
    [chatMessages removeAllObjects];
    [chatMessages addObjectsFromArray:[[tempArrray reverseObjectEnumerator] allObjects]];// 将数组反转并添加
    return YES;
}
// 更早的聊天记录(20条)
- (BOOL)moreChatMessages:(NSMutableArray *)chatMessages fromChatJID:(XMPPJID *)chatJid beforeTime:(NSTimeInterval)time
{
    HYLoginInfo *loginInfo = [HYLoginInfo sharedInstance];
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM T_CHAT_SINGLECHAT WHERE myJid='%@' AND chatBare='%@' AND time < %lf order by time desc limit 0,20",[loginInfo.jid full], [chatJid bare], time];
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
        [self chatMessages:message fromResultSet:rs];
        [tempArrray addObject:message]; // 添加到models
    }
    [rs close];
    [chatMessages removeAllObjects];
    [chatMessages addObjectsFromArray:[[tempArrray reverseObjectEnumerator] allObjects]];// 将数组反转并添加
    return YES;
}

- (void)chatMessages:(HYChatMessage *)message fromResultSet:(FMResultSet *)rs
{
    NSString *messageID = [rs stringForColumn:@"msgid"];
    NSString *chatBare = [rs stringForColumn:@"chatBare"];
    NSString *resource = [rs stringForColumn:@"chatResource"];
    XMPPJID *chatJid = [XMPPJID jidWithString:chatBare resource:resource];
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