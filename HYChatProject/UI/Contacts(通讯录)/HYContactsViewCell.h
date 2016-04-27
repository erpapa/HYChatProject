//
//  HYContactsViewCell.h
//  HYChatProject
//
//  Created by erpapa on 16/4/22.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGSwipeTableCell.h"
#define kContactsViewCellHeight 54.0
@class HYContactsModel;
@interface HYContactsViewCell : MGSwipeTableCell
@property (nonatomic, strong) HYContactsModel *model;
+ (instancetype)cellWithTableView:(UITableView *)tableView;

@end
