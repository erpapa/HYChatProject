//
//  HYContactsCustomViewCell.h
//  HYChatProject
//
//  Created by erpapa on 16/5/5.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HYContactsViewCell.h"

@interface HYContactsCustomViewCell : UITableViewCell
@property (nonatomic, strong) UIImageView *headView;
@property (nonatomic, strong) UILabel *nameLabel;
+ (instancetype)cellWithTableView:(UITableView *)tableView;
@end
