//
//  HYVideoViewCell.m
//  HYChatProject
//
//  Created by erpapa on 16/5/16.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYVideoViewCell.h"

@implementation HYVideoViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.thumImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.thumImageView.backgroundColor = [UIColor colorWithRed:234/255.0 green:234/255.0 blue:234/255.0 alpha:1.0];
        [self.contentView addSubview:self.thumImageView];
        self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.bounds) - 28, CGRectGetWidth(self.bounds), 28)];
        self.timeLabel.textColor = [UIColor blackColor];
        self.timeLabel.font = [UIFont systemFontOfSize:14];
        self.timeLabel.backgroundColor = [UIColor colorWithRed:241/255.0 green:241/255.0 blue:241/255.0 alpha:1.0f];
        [self.contentView addSubview:self.timeLabel];
    }
    return self;
}

@end
