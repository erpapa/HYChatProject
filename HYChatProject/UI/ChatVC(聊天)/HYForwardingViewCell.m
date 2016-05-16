//
//  HYForwardingViewCell.m
//  HYChatProject
//
//  Created by erpapa on 16/5/14.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYForwardingViewCell.h"
#import "HYContactsModel.h"
#import "HYXMPPManager.h"

@interface HYForwardingViewCell()

@property (nonatomic, strong) UIImageView *headView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIView *line;

@end

@implementation HYForwardingViewCell

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
    CGFloat headViewW = kForwardingViewCellHeight - headViewY * 2;
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
    
    // 4.分割线
    self.line = [[UIView alloc] initWithFrame:CGRectMake(nameLabelX, kForwardingViewCellHeight - 1, kScreenW - nameLabelX, 1)];
    self.line.backgroundColor = [UIColor colorWithRed:239/255.0 green:239/255.0 blue:244/255.0 alpha:1.0f];
    [self.contentView addSubview:self.line];
}

- (void)setChatModel:(HYContactsModel *)chatModel
{
    _chatModel = chatModel;
    self.headView.image = chatModel.isGroup ? [UIImage imageNamed:@"defaultGroupHead"] : [UIImage imageNamed:@"defaultHead"];
    self.nameLabel.text = chatModel.nickName;
    __weak typeof(self) weakSelf = self;
    [[HYXMPPManager sharedInstance] getAvatarFromJID:chatModel.jid avatarBlock:^(NSData *avatar) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (avatar.length) {
            strongSelf.headView.image = [UIImage imageWithData:avatar];
        }
    }];
}

@end

@implementation HYForwardingHeaderView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        
        UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenW, kForwardingHeaderViewHeight)];
        bgView.backgroundColor = [UIColor colorWithRed:239/255.0 green:239/255.0 blue:239/255.0 alpha:1.0f];
        [self.contentView addSubview:bgView];
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, kScreenW - 20, kForwardingHeaderViewHeight)];
        self.titleLabel.font = [UIFont systemFontOfSize:14];
        self.titleLabel.textColor = [UIColor grayColor];
        [self.contentView addSubview:self.titleLabel];
    }
    return self;
}

@end


@implementation HYForwardingIconViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIView *selectedBGView = [[UIView alloc] init];
        selectedBGView.backgroundColor = [UIColor colorWithRed:223/255.0 green:223/255.0 blue:223/255.0 alpha:1.0f];
        self.selectedBackgroundView = selectedBGView;
        // 1.头像
        CGFloat margin = 4.0;
        CGFloat headViewW = CGRectGetHeight(self.bounds) - margin * 2;
        self.headView = [[UIImageView alloc] initWithFrame:CGRectMake(margin, margin, headViewW, headViewW)];
        self.headView.contentMode = UIViewContentModeScaleAspectFill;
        self.headView.layer.cornerRadius = headViewW * 0.5;
        self.headView.layer.masksToBounds = YES;
        [self.contentView addSubview:self.headView];
    }
    return self;
}

- (void)setChatModel:(HYContactsModel *)chatModel
{
    _chatModel = chatModel;
    self.headView.image = chatModel.isGroup ? [UIImage imageNamed:@"defaultGroupHead"] : [UIImage imageNamed:@"defaultHead"];
    __weak typeof(self) weakSelf = self;
    [[HYXMPPManager sharedInstance] getAvatarFromJID:chatModel.jid avatarBlock:^(NSData *avatar) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (avatar.length) {
            strongSelf.headView.image = [UIImage imageWithData:avatar];
        }
    }];
}

@end
