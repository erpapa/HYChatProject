//
//  HYSettingViewCell.m
//  HYChatProject
//
//  Created by erpapa on 16/4/27.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYSettingViewCell.h"

@implementation HYSettingViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UIView *selectedBGView = [[UIView alloc] init];
        selectedBGView.backgroundColor = [UIColor colorWithRed:245/255.0 green:245/255.0 blue:245/255.0 alpha:1.0f];
        self.selectedBackgroundView = selectedBGView;
        
        // 1.提示
        self.badgeView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.bounds) - 25, (kSettingViewCellHeight - 8) * 0.5, 8, 8)];
        self.badgeView.image = [UIImage circleImageWithColor:[UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f] size:CGSizeMake(16, 16)];
        self.badgeView.hidden = YES;
        [self.contentView addSubview:self.badgeView];
        
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.contentView bringSubviewToFront:self.badgeView];
}

@end
