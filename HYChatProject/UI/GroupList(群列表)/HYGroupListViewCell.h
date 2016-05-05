//
//  HYGroupListViewCell.h
//  HYChatProject
//
//  Created by erpapa on 16/5/5.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <UIKit/UIKit.h>
#define kGroupListViewCellHeight 54.0

@class HYContactsModel;
@interface HYGroupListViewCell : UITableViewCell
@property (nonatomic, strong) HYContactsModel *model;
+ (instancetype)cellWithTableView:(UITableView *)tableView;
@end
