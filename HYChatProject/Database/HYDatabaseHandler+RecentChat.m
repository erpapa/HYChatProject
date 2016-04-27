//
//  HYDatabaseHandler+RecentChat.m
//  HYChatProject
//
//  Created by erpapa on 16/4/24.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYDatabaseHandler+RecentChat.h"
#import "HYLoginInfo.h"
#import "HYRecentChatModel.h"

@implementation HYDatabaseHandler(RecentChat)

- (BOOL)updateRecentChatModel:(HYRecentChatModel *)recentChatModel
{
    __block BOOL result = YES;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db updateRecentChatModel:recentChatModel];
    }];
    
    return result;
}
- (BOOL)insertRecentChatModel:(HYRecentChatModel *)recentChatModel
{
    __block BOOL result = YES;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db insertRecentChatModel:recentChatModel];
    }];
    
    return result;
}

- (BOOL)deleteRecentChatModel:(HYRecentChatModel *)recentChatModel
{
    __block BOOL result = YES;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db deleteRecentChatModel:recentChatModel];
    }];
    
    return result;
    
}

- (BOOL)recentChatModels:(NSMutableArray *)models
{
    __block BOOL result = YES;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db recentChatModels:models];
    }];
    
    return result;
}
- (BOOL)recentChatModel:(HYRecentChatModel *)recentChatModel fromJid:(XMPPJID *)jid
{
    __block BOOL result = YES;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db recentChatModel:recentChatModel fromJid:jid];
    }];
    
    return result;
}

@end

@implementation FMDatabase(RecentChat)

/**
 *  将jid的bare和resource分开储存
 *  时间timeIntervalSince1970，用秒计数，方便排序
 *  stpeter@jabber.org：表示服务器jabber.org上的用户stpeter。
 *  stpeter@jabber.org/iPhone：表示用户stpeter的地址，"iPhone"是绑定的地址。
 *  room@service：一个用来提供多用户聊天服务的特定的聊天室。这里“room“是聊天室的名字，”service“ 是多用户聊天服务的主机名。
 *  room@service/nick：加入了聊天室的用户nick的地址。这里 “room“ 是聊天室的名字， ”service“ 是多用户聊天服务的主机名，”nick“ 是用户在聊天室的昵称。
 */
- (void)createRecentChatTable
{
    [self executeUpdate:@"CREATE TABLE IF NOT EXISTS T_CHAT_RECENTCHAT (id integer primary key autoincrement,myJid text,chatBare text,chatResource text,body text,time double,isGroup int,unreadCount int)"];
}

- (BOOL)updateRecentChatModel:(HYRecentChatModel *)recentChatModel
{
    HYLoginInfo *loginInfo = [HYLoginInfo sharedInstance];
    NSString *sql = [NSString stringWithFormat:@"UPDATE T_CHAT_RECENTCHAT SET chatResource='%@',body='%@',time=%lf,isGroup=%d,unreadCount=%d WHERE myJid='%@' AND chatBare='%@'",recentChatModel.jid.resource,recentChatModel.body,recentChatModel.time,recentChatModel.isGroup,recentChatModel.unreadCount,[loginInfo.jid full],[recentChatModel.jid bare]];
    if(![self executeUpdate:sql])
    {
        HYLog(@"%@ fail,%@",sql,[[self lastError] localizedDescription]);
        return NO;
    }
    return YES;
}

- (BOOL)insertRecentChatModel:(HYRecentChatModel *)recentChatModel
{
    HYLoginInfo *loginInfo = [HYLoginInfo sharedInstance];
    NSString *sql = [NSString stringWithFormat:@"INSERT INTO T_CHAT_RECENTCHAT(myJid,chatBare,chatResource,body,time,isGroup,unreadCount) VALUES('%@','%@','%@','%@','%lf','%d','%d')",[loginInfo.jid full],[recentChatModel.jid bare],recentChatModel.jid.resource,recentChatModel.body,recentChatModel.time,recentChatModel.isGroup,recentChatModel.unreadCount];
    if(![self executeUpdate:sql])
    {
        HYLog(@"%@ fail,%@",sql,[[self lastError] localizedDescription]);
        return NO;
    }
    return YES;
}


- (BOOL)deleteRecentChatModel:(HYRecentChatModel *)recentChatModel
{
    HYLoginInfo *loginInfo = [HYLoginInfo sharedInstance];
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM T_CHAT_RECENTCHAT WHERE myJid='%@' AND chatBare='%@'",[loginInfo.jid full],[recentChatModel.jid bare]];
    if(![self executeUpdate:sql])
    {
        HYLog(@"%@ fail,%@",sql,[[self lastError] localizedDescription]);
        return NO;
    }
    return YES;
}

- (BOOL)recentChatModels:(NSMutableArray *)models
{
    HYLoginInfo *loginInfo = [HYLoginInfo sharedInstance];
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM T_CHAT_RECENTCHAT WHERE myJid='%@' order by time desc",[loginInfo.jid full]];
    FMResultSet *rs = [self executeQuery:sql];
    if(rs == nil)
    {
        HYLog(@"%@ fail,%@",sql,[[self lastError] localizedDescription]);
        return NO;
    }
    
    [models removeAllObjects];
    while ([rs next])
    {
        HYRecentChatModel *model = [[HYRecentChatModel alloc] init];
        [self recentChatModel:model fromResultSet:rs];
        [models addObject:model]; // 添加到models
    }
    
    [rs close];
    return YES;
}

- (BOOL)recentChatModel:(HYRecentChatModel *)recentChatModel fromJid:(XMPPJID *)jid
{
    HYLoginInfo *loginInfo = [HYLoginInfo sharedInstance];
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM T_CHAT_RECENTCHAT WHERE myJid='%@' AND chatBare='%@'",[loginInfo.jid full], [jid bare]];
    FMResultSet *rs = [self executeQuery:sql];
    if(rs == nil)
    {
        HYLog(@"%@ fail,%@",sql,[[self lastError] localizedDescription]);
        return NO;
    }
    
    while ([rs next])
    {
        [self recentChatModel:recentChatModel fromResultSet:rs];
        [rs close];
        return YES;
    }
    
    [rs close];
    return NO;
}

- (void)recentChatModel:(HYRecentChatModel *)model fromResultSet:(FMResultSet *)rs
{
    NSString *chatBare = [rs stringForColumn:@"chatBare"];
    NSString *resource = [rs stringForColumn:@"chatResource"];
    XMPPJID *chatJid = [XMPPJID jidWithString:chatBare resource:resource];
    NSString *body = [rs stringForColumn:@"body"];
    NSTimeInterval time = [rs doubleForColumn:@"time"];
    BOOL isGroup = [rs boolForColumn:@"isGroup"];
    NSInteger unreadCount = [rs intForColumn:@"unreadCount"];
    
    [model setJid:chatJid];
    [model setBody:body];
    [model setTime:time];
    [model setIsGroup:isGroup];
    [model setUnreadCount:unreadCount];
}

@end