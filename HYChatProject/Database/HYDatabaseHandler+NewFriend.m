//
//  HYDatabaseHandler+NewFriend.m
//  HYChatProject
//
//  Created by erpapa on 16/5/11.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYDatabaseHandler+HY.h"
#import "HYLoginInfo.h"
#import "HYRequestModel.h"

@implementation HYDatabaseHandler(NewFriend)

- (BOOL)addFriend:(HYRequestModel *)friendModel
{
    __block BOOL result = YES;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db addFriend:friendModel];
    }];
    
    return result;
}
- (BOOL)deleteFriend:(HYRequestModel *)friendModel
{
    __block BOOL result = YES;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db deleteFriend:friendModel];
    }];
    return result;
}
- (BOOL)updateFriend:(HYRequestModel *)friendModel
{
    __block BOOL result = YES;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db updateFriend:friendModel];
    }];
    return result;
}

- (BOOL)allNewFriends:(NSMutableArray *)friends
{
    __block BOOL result = YES;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db allNewFriends:friends];
    }];
    return result;
}

- (BOOL)allRequestFriends:(NSMutableArray *)friends
{
    __block BOOL result = YES;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db allRequestFriends:friends];
    }];
    return result;
}
@end

@implementation FMDatabase(NewFriend)

- (void)createNewFriendTable
{
    [self executeUpdate:@"CREATE TABLE IF NOT EXISTS T_CHAT_NEWFRIEND (id integer primary key autoincrement,myJid text,friendBare text,friendResource text,roomJid text,body text,time double,requestType int,option int)"];
}

- (BOOL)addFriend:(HYRequestModel *)friendModel
{
    HYLoginInfo *loginInfo = [HYLoginInfo sharedInstance];
    
    BOOL fond = NO;
    NSString *querySql;
    if (friendModel.requestType == 1) { // 好友申请(option=0，没有拒绝也没有接受)
        querySql = [NSString stringWithFormat:@"SELECT * FROM T_CHAT_NEWFRIEND WHERE myJid='%@' AND friendBare='%@' AND requestType>0 AND option=0",[loginInfo.jid full],friendModel.jid.bare];
    } else if (friendModel.requestType == 2) { //群邀请
        querySql = [NSString stringWithFormat:@"SELECT * FROM T_CHAT_NEWFRIEND WHERE myJid='%@' AND friendBare='%@' AND requestType>0 AND roomJid='%@' AND option=0",[loginInfo.jid full],friendModel.jid.bare,friendModel.roomJid];
    }
    if (querySql) {
        FMResultSet *rs = [self executeQuery:querySql];
        if(rs == nil) {
            HYLog(@"%@ fail,%@",querySql,[[self lastError] localizedDescription]);
            return NO;
        }
        if ([rs next]) { // 没有找到
            fond = YES;
        }
        [rs close];
        if (fond == YES) { // 找到了。直接返回
            return YES;
        }
    }
    
    NSString *sql = [NSString stringWithFormat:@"INSERT INTO T_CHAT_NEWFRIEND(myJid,friendBare,friendResource,roomJid,body,time,requestType,option) VALUES('%@','%@','%@','%@','%@','%lf','%d','%d')",loginInfo.jid.full,friendModel.jid.bare,friendModel.jid.resource,friendModel.roomJid.bare,friendModel.body,friendModel.time,friendModel.requestType,friendModel.option];
    if(![self executeUpdate:sql]) {
        HYLog(@"%@ fail,%@",sql,[[self lastError] localizedDescription]);
        return NO;
    }
    return YES;
}

- (BOOL)deleteFriend:(HYRequestModel *)friendModel
{
    HYLoginInfo *loginInfo = [HYLoginInfo sharedInstance];
    NSString *sql;
    if (friendModel.requestType == 1) {
        sql = [NSString stringWithFormat:@"DELETE FROM T_CHAT_NEWFRIEND WHERE myJid='%@' AND friendBare='%@'",loginInfo.jid.full, friendModel.jid.bare];
    } else if (friendModel.requestType == 2) {
        sql = [NSString stringWithFormat:@"DELETE FROM T_CHAT_NEWFRIEND WHERE myJid='%@' AND friendBare='%@' AND roomJid='%@'",loginInfo.jid.full, friendModel.jid.bare, friendModel.roomJid.bare];
    }
    if(![self executeUpdate:sql])
    {
        HYLog(@"%@ fail,%@",sql,[[self lastError] localizedDescription]);
        return NO;
    }
    return YES;
}

- (BOOL)updateFriend:(HYRequestModel *)friendModel
{
    HYLoginInfo *loginInfo = [HYLoginInfo sharedInstance];
    NSString *sql;
    if (friendModel.requestType == 1) {
        sql = [NSString stringWithFormat:@"UPDATE T_CHAT_NEWFRIEND SET requestType=%d,option=%d WHERE myJid='%@' AND friendBare='%@' AND requestType=1",friendModel.requestType,friendModel.option,loginInfo.jid.full,friendModel.jid.bare];
    } else if (friendModel.requestType == 2) {
        sql = [NSString stringWithFormat:@"UPDATE T_CHAT_NEWFRIEND SET requestType=%d,option=%d WHERE myJid='%@' AND friendBare='%@' AND roomJid='%@' AND requestType=2",friendModel.requestType,friendModel.option,loginInfo.jid.full,friendModel.jid.bare,friendModel.roomJid.bare];
    }
    if(![self executeUpdate:sql])
    {
        HYLog(@"%@ fail,%@",sql,[[self lastError] localizedDescription]);
        return NO;
    }
    return YES;
}

- (BOOL)allNewFriends:(NSMutableArray *)friends
{
    HYLoginInfo *loginInfo = [HYLoginInfo sharedInstance];
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM T_CHAT_NEWFRIEND WHERE myJid='%@' AND requestType=0 order by time desc",[loginInfo.jid full]];
    FMResultSet *rs = [self executeQuery:sql];
    if(rs == nil)
    {
        HYLog(@"%@ fail,%@",sql,[[self lastError] localizedDescription]);
        return NO;
    }
    
    [friends removeAllObjects];
    while ([rs next])
    {
        HYRequestModel *model = [[HYRequestModel alloc] init];
        [self friendModel:model fromResultSet:rs];
        [friends addObject:model]; // 添加到models
    }
    
    [rs close];
    return YES;
}

- (BOOL)allRequestFriends:(NSMutableArray *)friends
{
    HYLoginInfo *loginInfo = [HYLoginInfo sharedInstance];
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM T_CHAT_NEWFRIEND WHERE myJid='%@' AND requestType>0 order by time desc",[loginInfo.jid full]];
    FMResultSet *rs = [self executeQuery:sql];
    if(rs == nil)
    {
        HYLog(@"%@ fail,%@",sql,[[self lastError] localizedDescription]);
        return NO;
    }
    
    [friends removeAllObjects];
    while ([rs next])
    {
        HYRequestModel *model = [[HYRequestModel alloc] init];
        [self friendModel:model fromResultSet:rs];
        [friends addObject:model]; // 添加到models
    }
    
    [rs close];
    return YES;
}

- (void)friendModel:(HYRequestModel *)friendModel fromResultSet:(FMResultSet *)rs
{
    NSString *friendBare = [rs stringForColumn:@"friendBare"];
    NSString *friendResource = [rs stringForColumn:@"friendResource"];
    XMPPJID *friendJid = [XMPPJID jidWithString:friendBare resource:friendResource];
    NSString *roomBare = [rs stringForColumn:@"roomJid"];
    XMPPJID *roomJid = [XMPPJID jidWithString:roomBare];
    NSString *body = [rs stringForColumn:@"body"];
    NSTimeInterval time = [rs doubleForColumn:@"time"];
    int requestType = [rs intForColumn:@"requestType"];
    int option = [rs intForColumn:@"option"];
    
    [friendModel setJid:friendJid];
    [friendModel setRoomJid:roomJid];
    [friendModel setBody:body];
    [friendModel setTime:time];
    [friendModel setRequestType:requestType];
    [friendModel setOption:option];
}




@end