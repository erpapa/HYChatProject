//
//  HYDatabaseHandler+User.m
//  HYChatProject
//
//  Created by erpapa on 16/4/24.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYDatabaseHandler+User.h"
#import "HYUser.h"

@implementation HYDatabaseHandler(User)

- (BOOL)addUser:(HYUser *)user
{
    __block BOOL result = YES;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db addUser:user];
    }];
    
    return result;
}
- (BOOL)users:(NSMutableArray *)users
{
    __block BOOL result = YES;
    __block NSMutableArray *myrecords = users;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db users:myrecords];
    }];
    
    return result;
}
@end

@implementation FMDatabase(User)

- (void)createUserTable
{
    //用户基本信息记录
    [self executeUpdate:@"CREATE TABLE IF NOT EXISTS T_CHAT_LOGINUSER (id integer primary key autoincrement,myJid text,vCard blob)"];
}
- (BOOL)addUser:(HYUser *)user
{
    NSData *vCardData = [NSKeyedArchiver archivedDataWithRootObject:user.vCard];
    NSString *sql = [NSString stringWithFormat:@"INSERT OR REPLACE INTO T_CHAT_LOGINUSER(myJid,vCard) VALUES('%@','%@')",[user.jid full],vCardData];
    if(![self executeUpdate:sql])
    {
        HYLog(@"%@ fail,%@",sql,[[self lastError] localizedDescription]);
        return NO;
    }
    return YES;
}
- (BOOL)users:(NSMutableArray *)users
{
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM T_CHAT_LOGINUSER"];
    FMResultSet *rs = [self executeQuery:sql];
    if(rs == nil)
    {
        HYLog(@"%@ fail,%@",sql,[[self lastError] localizedDescription]);
        return NO;
    }
    
    [users removeAllObjects];
    while ([rs next])
    {
        HYUser* user = [[HYUser alloc] init];
        [self user:user fromResultSet:rs];
        [users addObject:user]; // 添加到users中
    }
    
    [rs close];
    return YES;
}
- (BOOL)user:(HYUser *)user fromJid:(XMPPJID *)jid;
{
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM T_CHAT_LOGINUSER WHERE myJid='%@'",[jid full]];
    FMResultSet *rs = [self executeQuery:sql];
    if(rs == nil)
    {
        HYLog(@"%@ fail,%@",sql,[[self lastError] localizedDescription]);
        return NO;
    }
    
    while ([rs next])
    {
        [self user:user fromResultSet:rs];
        [rs close];
        return YES;
    }
    
    [rs close];
    return NO;
}
- (void)user:(HYUser *)user fromResultSet:(FMResultSet *)rs
{
    NSString *jidStr = [rs stringForColumn:@"myJid"];
    XMPPJID *jid = [XMPPJID jidWithString:jidStr];
    NSData *vCardData = [rs dataForColumn:@"vCard"];
    XMPPvCardTemp *vCard = [NSKeyedUnarchiver unarchiveObjectWithData:vCardData];
    
    [user setJid:jid];
    [user setVCard:vCard];
}
@end