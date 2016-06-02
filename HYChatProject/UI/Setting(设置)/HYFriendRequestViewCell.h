//
//  HYFriendRequestViewCell.h
//  HYChatProject
//
//  Created by erpapa on 16/5/13.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <UIKit/UIKit.h>
#define kFriendRequestViewCellHeight 54.0

@class HYFriendRequestViewCell,HYRequestModel;
@protocol HYFriendRequestViewCellDelegate <NSObject>
@optional
- (void)friendRequestClick:(HYFriendRequestViewCell *)friendRequestViewCell;

@end

@interface HYFriendRequestViewCell : UITableViewCell
@property (nonatomic, weak) id<HYFriendRequestViewCellDelegate> delegate;
@property (nonatomic, strong) HYRequestModel *friendModel;
+ (instancetype)cellWithTableView:(UITableView *)tableView;
@end
