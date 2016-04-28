//
//  HYContactsHeaderView.m
//  HYChatProject
//
//  Created by erpapa on 16/4/27.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYContactsHeaderView.h"

@interface HYContactsHeaderView()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *bgView;

@end

@implementation HYContactsHeaderView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        [self initSubviews];
    }
    return self;
}

- (void)initSubviews
{
    self.bgView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, kScreenW, kContactsHeaderViewHeight)];
    self.bgView.backgroundColor = [UIColor colorWithRed:239/255.0 green:239/255.0 blue:244/255.0 alpha:1.0f];
    [self.contentView addSubview:self.bgView];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(8.0, 0.0, kScreenW - 16.0, kContactsHeaderViewHeight)];
    self.titleLabel.font = [UIFont systemFontOfSize:16];
    self.titleLabel.textColor = [UIColor grayColor];
    [self.contentView addSubview:self.titleLabel];
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    self.titleLabel.text = title;
}

@end
