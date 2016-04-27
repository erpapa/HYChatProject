//
//  HYDatabaseHandler+User.h
//  HYChatProject
//
//  Created by erpapa on 16/4/24.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYDatabaseHandler.h"
@class HYUser;
@interface HYDatabaseHandler(User)

- (BOOL)addUser:(HYUser *)user;
- (BOOL)users:(NSMutableArray *)users;

@end

@interface FMDatabase(User)
- (void)createUserTable;
- (BOOL)addUser:(HYUser *)user;
- (BOOL)users:(NSMutableArray *)users;
- (BOOL)user:(HYUser *)user fromJid:(XMPPJID *)jid;
@end