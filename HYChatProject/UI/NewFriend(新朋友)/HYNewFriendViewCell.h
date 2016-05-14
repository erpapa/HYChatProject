//
//  HYNewFriendViewCell.h
//  HYChatProject
//
//  Created by erpapa on 16/5/13.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <UIKit/UIKit.h>
#define kNewFriendViewCellHeight 54.0

@class HYNewFriendModel;
@interface HYNewFriendViewCell : UITableViewCell
@property (nonatomic, strong) HYNewFriendModel *friendModel;
+ (instancetype)cellWithTableView:(UITableView *)tableView;
@end
