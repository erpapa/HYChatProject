//
//  HYContactsCustomViewCell.m
//  HYChatProject
//
//  Created by erpapa on 16/5/5.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYContactsCustomViewCell.h"

@implementation HYContactsCustomViewCell

+ (instancetype)cellWithTableView:(UITableView *)tableView
{
    static NSString *ID = @"HYGroupListViewCellIdentifier";
    HYContactsCustomViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (cell == nil){
        cell = [[HYContactsCustomViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
    }
    return cell;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupContentView];
        UIView *selectedBGView = [[UIView alloc] init];
        selectedBGView.backgroundColor = [UIColor colorWithRed:239/255.0 green:239/255.0 blue:244/255.0 alpha:1.0f];
        self.selectedBackgroundView = selectedBGView;
    }
    return self;
}

- (void)setupContentView
{
    CGFloat margin = 6.0; // 上下间隔
    CGFloat panding = 8.0; // 左右间隔
    CGFloat headViewX = panding;
    CGFloat headViewY = margin;
    CGFloat headViewW = kContactsViewCellHeight - headViewY * 2;
    // 1.头像
    self.headView = [[UIImageView alloc] initWithFrame:CGRectMake(headViewX, headViewY, headViewW, headViewW)];
    self.headView.contentMode = UIViewContentModeScaleAspectFill;
    self.headView.layer.cornerRadius = headViewW * 0.5;
    self.headView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.headView];
    
    // 2.昵称
    CGFloat nameLabelX = CGRectGetMaxX(self.headView.frame) + headViewX;
    CGFloat nameLabelY = headViewY;
    CGFloat nameLabelW = CGRectGetWidth(self.bounds) - nameLabelX * 2;
    CGFloat nameLabelH = headViewW;
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(nameLabelX, nameLabelY, nameLabelW, nameLabelH)];
    self.nameLabel.textColor = [UIColor blackColor];
    self.nameLabel.font = [UIFont systemFontOfSize:18];
    [self.contentView addSubview:self.nameLabel];
    
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, kContactsViewCellHeight - 1, CGRectGetWidth(self.bounds), 1)];
    line.backgroundColor = [UIColor colorWithRed:241/255.0 green:241/255.0 blue:241/255.0 alpha:1.0f];
    [self.contentView addSubview:line];
}

@end
