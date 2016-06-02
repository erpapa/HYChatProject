//
//  HYDatabaseHandler+NewFriend.h
//  HYChatProject
//
//  Created by erpapa on 16/5/11.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYDatabaseHandler.h"
@class HYRequestModel;
@interface HYDatabaseHandler(NewFriend)
- (BOOL)addFriend:(HYRequestModel *)friendModel; // 插入
- (BOOL)deleteFriend:(HYRequestModel *)friendModel; // 删除记录
- (BOOL)updateFriend:(HYRequestModel *)friendModel; // 更新记录
- (BOOL)allNewFriends:(NSMutableArray *)friends; //返回所有添加的好友
- (BOOL)allRequestFriends:(NSMutableArray *)friends; //返回所有好友请求
@end

@interface FMDatabase(NewFriend)
- (void)createNewFriendTable;
- (BOOL)addFriend:(HYRequestModel *)friendModel; // 插入
- (BOOL)deleteFriend:(HYRequestModel *)friendModel; // 删除记录
- (BOOL)updateFriend:(HYRequestModel *)friendModel; // 更新记录
- (BOOL)allNewFriends:(NSMutableArray *)friends; //返回所有添加的好友
- (BOOL)allRequestFriends:(NSMutableArray *)friends; //返回所有好友请求
@end