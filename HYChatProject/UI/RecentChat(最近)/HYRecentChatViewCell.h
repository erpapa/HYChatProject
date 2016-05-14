//
//  HYRecentContactsViewCell.h
//  HYChatProject
//
//  Created by erpapa on 16/4/22.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGSwipeTableCell.h"

#define kRecentChatViewCellHeight 66.0

@class HYRecentChatModel;
@interface HYRecentChatViewCell : MGSwipeTableCell

@property (nonatomic, strong) HYRecentChatModel *chatModel;
+ (instancetype)cellWithTableView:(UITableView *)tableView;

@end
