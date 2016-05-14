//
//  HYFriendRequestViewCell.m
//  HYChatProject
//
//  Created by erpapa on 16/5/13.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYFriendRequestViewCell.h"
#import "HYNewFriendModel.h"
#import "HYXMPPManager.h"
#import "HYUtils.h"

@interface HYFriendRequestViewCell()

@property (nonatomic, strong) UIImageView *headView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UIButton *acceptButton;
@property (nonatomic, strong) UIView *line;

@end

@implementation HYFriendRequestViewCell

+ (instancetype)cellWithTableView:(UITableView *)tableView
{
    static NSString *ID = @"HYFriendRequestViewCellIdentifier";
    HYFriendRequestViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (cell == nil){
        cell = [[HYFriendRequestViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
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
    CGFloat headViewW = kFriendRequestViewCellHeight - headViewY * 2;
    // 1.头像
    self.headView = [[UIImageView alloc] initWithFrame:CGRectMake(headViewX, headViewY, headViewW, headViewW)];
    self.headView.image = [UIImage imageNamed:@"defaultHead"];
    self.headView.contentMode = UIViewContentModeScaleAspectFill;
    self.headView.layer.cornerRadius = headViewW * 0.5;
    self.headView.layer.masksToBounds = YES;
    self.headView.userInteractionEnabled = YES;
    [self.contentView addSubview:self.headView];
    
    // 2.接受
    CGFloat buttonW = 80;
    CGFloat buttonH = 32;
    CGFloat buttonX = kScreenW - buttonW - 12;
    CGFloat buttonY = headViewY;
    self.acceptButton = [[UIButton alloc] initWithFrame:CGRectMake(buttonX, buttonY, buttonW, buttonH)];
    self.acceptButton.backgroundColor = [UIColor colorWithRed:57/255.0 green:164/255.0 blue:50/255.0 alpha:1.0];
    [self.acceptButton setTitle:@"接受" forState:UIControlStateNormal];
    [self.acceptButton addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    self.acceptButton.layer.cornerRadius = 4;
    self.acceptButton.layer.masksToBounds = YES;
    [self.contentView addSubview:self.acceptButton];
    
    // 3.昵称
    CGFloat nameLabelX = CGRectGetMaxX(self.headView.frame) + headViewX;
    CGFloat nameLabelY = headViewY;
    CGFloat nameLabelW = CGRectGetMinX(self.acceptButton.frame) - nameLabelX;
    CGFloat nameLabelH = headViewW * 0.5;
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(nameLabelX, nameLabelY, nameLabelW, nameLabelH)];
    self.nameLabel.textColor = [UIColor blackColor];
    self.nameLabel.font = [UIFont systemFontOfSize:20];
    [self.contentView addSubview:self.nameLabel];
    
    // 4.消息内容
    CGFloat detailLabelX = nameLabelX;
    CGFloat detailLabelY = CGRectGetMaxY(self.nameLabel.frame);
    CGFloat detailLabelW = nameLabelW;
    CGFloat detailLabelH = nameLabelH;
    self.detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(detailLabelX, detailLabelY, detailLabelW, detailLabelH)];
    self.detailLabel.textColor = [UIColor lightGrayColor];
    self.detailLabel.font = [UIFont systemFontOfSize:14];
    [self.contentView addSubview:self.detailLabel];
    
    // 5.分割线
    self.line = [[UIView alloc] initWithFrame:CGRectMake(nameLabelX, kFriendRequestViewCellHeight - 1, kScreenW - nameLabelX, 1)];
    self.line.backgroundColor = [UIColor colorWithRed:239/255.0 green:239/255.0 blue:244/255.0 alpha:1.0f];
    [self.contentView addSubview:self.line];
}

- (void)setFriendModel:(HYNewFriendModel *)friendModel
{
    _friendModel = friendModel;
    self.nameLabel.text = friendModel.jid.user;
    self.detailLabel.text = [NSString stringWithFormat:@"%@  %@",friendModel.body, [HYUtils timeStringSince1970:friendModel.time]];
    __weak typeof(self) weakSelf = self;
    [[HYXMPPManager sharedInstance] getAvatarFromJID:friendModel.jid avatarBlock:^(NSData *avatar) {
        if (avatar.length) {
            weakSelf.headView.image = [UIImage imageWithData:avatar];
        }
    }];
}

- (void)buttonClick:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(friendRequestAccept:)]) {
        [self.delegate friendRequestAccept:self];
    }
}

@end
