//
//  HYFriendRequestViewCell.m
//  HYChatProject
//
//  Created by erpapa on 16/5/13.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYFriendRequestViewCell.h"
#import "HYRequestModel.h"
#import "HYXMPPManager.h"
#import "HYUtils.h"

@interface HYFriendRequestViewCell()

@property (nonatomic, strong) UIImageView *headView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIButton *acceptButton;
@property (nonatomic, strong) UIButton *rejectButton;
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
    CGFloat buttonW = 48;
    CGFloat buttonH = 26;
    CGFloat buttonX = kScreenW - buttonW - 6;
    CGFloat buttonY = (kFriendRequestViewCellHeight - buttonH) * 0.5;
    self.acceptButton = [[UIButton alloc] initWithFrame:CGRectMake(buttonX, buttonY, buttonW, buttonH)];
    [self.acceptButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithRed:90/255.0 green:200/255.0 blue:255/255.0 alpha:1.0]] forState:UIControlStateNormal];
    [self.acceptButton setTitle:@"接受" forState:UIControlStateNormal];
    self.acceptButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.acceptButton addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    self.acceptButton.layer.cornerRadius = 2;
    self.acceptButton.layer.masksToBounds = YES;
    [self.contentView addSubview:self.acceptButton];
    
    // 3.拒绝
    self.rejectButton = [[UIButton alloc] initWithFrame:CGRectMake(buttonX - buttonW - 6, buttonY, buttonW, buttonH)];
    [self.rejectButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]] forState:UIControlStateNormal];
    [self.rejectButton setTitle:@"拒绝" forState:UIControlStateNormal];
    self.rejectButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.rejectButton addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    self.rejectButton.layer.cornerRadius = 2;
    self.rejectButton.layer.masksToBounds = YES;
    [self.contentView addSubview:self.rejectButton];
    
    // 4.昵称
    CGFloat nameLabelX = CGRectGetMaxX(self.headView.frame) + 4;
    CGFloat nameLabelY = headViewY;
    CGFloat nameLabelW = CGRectGetMinX(self.rejectButton.frame) - nameLabelX;
    CGFloat nameLabelH = headViewW * 0.5;
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(nameLabelX, nameLabelY, nameLabelW, nameLabelH)];
    self.nameLabel.textColor = [UIColor blackColor];
    self.nameLabel.font = [UIFont systemFontOfSize:16];
    [self.contentView addSubview:self.nameLabel];
    
    // 5.时间
    CGFloat timeLabelX = nameLabelX;
    CGFloat timeLabelY = CGRectGetMaxY(self.nameLabel.frame);
    CGFloat timeLabelW = nameLabelW;
    CGFloat timeLabelH = nameLabelH;
    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(timeLabelX, timeLabelY, timeLabelW, timeLabelH)];
    self.timeLabel.textColor = [UIColor lightGrayColor];
    self.timeLabel.font = [UIFont systemFontOfSize:14];
    [self.contentView addSubview:self.timeLabel];
    
    // 6.分割线
    self.line = [[UIView alloc] initWithFrame:CGRectMake(nameLabelX, kFriendRequestViewCellHeight - 1, kScreenW - nameLabelX, 1)];
    self.line.backgroundColor = [UIColor colorWithRed:239/255.0 green:239/255.0 blue:244/255.0 alpha:1.0f];
    [self.contentView addSubview:self.line];
}

- (void)setFriendModel:(HYRequestModel *)friendModel
{
    _friendModel = friendModel;
    if (friendModel.option == 0) {
        self.rejectButton.hidden = NO;
        [self.rejectButton setTitle:@"拒绝" forState:UIControlStateNormal];
        self.acceptButton.enabled = YES;
        [self.acceptButton setTitle:@"接受" forState:UIControlStateNormal];
        self.timeLabel.frame = CGRectMake(self.timeLabel.frame.origin.x, self.timeLabel.frame.origin.y, CGRectGetMinX(self.rejectButton.frame) - self.timeLabel.frame.origin.x, self.timeLabel.frame.size.height);
    } else if (friendModel.option == 1) {
        self.rejectButton.hidden = YES;
        self.acceptButton.enabled = NO;
        [self.acceptButton setTitle:@"已接受" forState:UIControlStateNormal];
        [self.acceptButton setBackgroundImage:[UIImage imageWithColor:[UIColor lightGrayColor]] forState:UIControlStateNormal];
        self.timeLabel.frame = CGRectMake(self.timeLabel.frame.origin.x, self.timeLabel.frame.origin.y, CGRectGetMinX(self.acceptButton.frame) - self.timeLabel.frame.origin.x, self.timeLabel.frame.size.height);
    } else if (friendModel.option == 2) {
        self.rejectButton.hidden = YES;
        self.acceptButton.enabled = NO;
        [self.acceptButton setTitle:@"已拒绝" forState:UIControlStateNormal];
        [self.acceptButton setBackgroundImage:[UIImage imageWithColor:[UIColor lightGrayColor]] forState:UIControlStateNormal];
        self.timeLabel.frame = CGRectMake(self.timeLabel.frame.origin.x, self.timeLabel.frame.origin.y, CGRectGetMinX(self.acceptButton.frame) - self.timeLabel.frame.origin.x, self.timeLabel.frame.size.height);
    }
    self.nameLabel.text = [NSString stringWithFormat:@"%@ ",friendModel.jid.user];
    self.timeLabel.text = [NSString stringWithFormat:@"%@ [%@]", friendModel.body,[HYUtils timeStringSince1970:friendModel.time]];
    __weak typeof(self) weakSelf = self;
    [[HYXMPPManager sharedInstance] getAvatarFromJID:friendModel.jid avatarBlock:^(NSData *avatar) {
        if (avatar.length) {
            weakSelf.headView.image = [UIImage imageWithData:avatar];
        }
    }];
}

- (void)buttonClick:(UIButton *)sender
{
    if (self.acceptButton == sender) {
        self.friendModel.option = 1; // 1.同意
    } else if (self.rejectButton == sender) {
        self.friendModel.option = 2; // 2.拒绝
    }
    
    if ([self.delegate respondsToSelector:@selector(friendRequestClick:)]) {
        [self.delegate friendRequestClick:self];
    }
}

@end
