//
//  HYNewFriendViewCell.h
//  HYChatProject
//
//  Created by erpapa on 16/5/13.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <UIKit/UIKit.h>
#define kNewFriendViewCellHeight 54.0

@class HYRequestModel;
@interface HYNewFriendViewCell : UITableViewCell
@property (nonatomic, strong) HYRequestModel *friendModel;
+ (instancetype)cellWithTableView:(UITableView *)tableView;
@end
