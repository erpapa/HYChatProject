//
//  HYDatabaseHandler+Contacts.h
//  HYChatProject
//
//  Created by erpapa on 16/4/25.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYDatabaseHandler.h"
@class HYUser,HYRoom;
@interface HYDatabaseHandler(Contacts)
- (BOOL)addUser:(HYUser *)user; // 添加好友
- (BOOL)deleteUser:(HYUser *)user; // 删除好友
- (BOOL)allUsers:(NSMutableArray *)users; //返回所有的好友
- (BOOL)createRoom:(HYRoom *)room; // 创建聊天室
- (BOOL)jionRoom:(HYRoom *)room; // 加入聊天室
- (BOOL)leaveRoom:(HYRoom *)room; // 离开房间
- (BOOL)allRooms:(NSMutableArray *)rooms; // 所有房间
@end

@interface FMDatabase(Contacts)
- (void)createContactsTable;
- (BOOL)addUser:(HYUser *)user; // 添加好友
- (BOOL)deleteUser:(HYUser *)user; // 删除好友
- (BOOL)allUsers:(NSMutableArray *)users; //返回所有的好友
- (BOOL)createRoom:(HYRoom *)room; // 创建聊天室
- (BOOL)jionRoom:(HYRoom *)room; // 加入聊天室
- (BOOL)leaveRoom:(HYRoom *)room; // 离开房间
- (BOOL)allRooms:(NSMutableArray *)rooms; // 所有房间
@end