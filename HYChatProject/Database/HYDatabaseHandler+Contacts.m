//
//  HYDatabaseHandler+Contacts.m
//  HYChatProject
//
//  Created by erpapa on 16/4/25.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYDatabaseHandler+HY.h"
#import "HYUser.h"
#import "HYRoom.h"

@implementation HYDatabaseHandler(Contacts)

- (BOOL)addUser:(HYUser *)user{
    __block BOOL result = YES;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db addUser:user];
    }];
    
    return result;
}
- (BOOL)deleteUser:(HYUser *)user{
    __block BOOL result = YES;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db deleteUser:user];
    }];
    
    return result;
}
- (BOOL)allUsers:(NSMutableArray *)users{
    __block BOOL result = YES;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db allUsers:users];
    }];
    
    return result;
}

@end

@implementation FMDatabase(Contacts)

- (void)createContactsTable
{
    // 创建好友表
    [self executeUpdate:@"CREATE TABLE IF NOT EXISTS T_CHAT_USERS (id integer primary key autoincrement,myJid text,chatBare text,chatResource text)"];
    // 创建房间表
    [self executeUpdate:@"CREATE TABLE IF NOT EXISTS T_CHAT_ROOMS (id integer primary key autoincrement,myJid text,chatBare text)"];
    
}

//- (BOOL)addUser:(HYUser *)user{
//    
//}
//- (BOOL)deleteUser:(HYUser *)user{
//    
//}
//- (BOOL)allUsers:(NSMutableArray *)users{
//    
//}

@end