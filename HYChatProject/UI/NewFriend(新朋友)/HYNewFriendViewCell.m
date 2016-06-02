//
//  HYNewFriendViewCell.m
//  HYChatProject
//
//  Created by erpapa on 16/5/13.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYNewFriendViewCell.h"
#import "HYRequestModel.h"
#import "UIView+SW.h"
#import "HYUtils.h"
#import "HYXMPPManager.h"
#import "HYUservCardViewController.h"

@interface HYNewFriendViewCell()
@property (nonatomic, strong) UIImageView *headView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIView *line;

@end

@implementation HYNewFriendViewCell

+ (instancetype)cellWithTableView:(UITableView *)tableView
{
    static NSString *ID = @"HYNewFriendViewCellIdentifier";
    HYNewFriendViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (cell == nil){
        cell = [[HYNewFriendViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
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
    CGFloat headViewW = kNewFriendViewCellHeight - headViewY * 2;
    // 1.头像
    self.headView = [[UIImageView alloc] initWithFrame:CGRectMake(headViewX, headViewY, headViewW, headViewW)];
    self.headView.image = [UIImage imageNamed:@"defaultHead"];
    self.headView.contentMode = UIViewContentModeScaleAspectFill;
    self.headView.layer.cornerRadius = headViewW * 0.5;
    self.headView.layer.masksToBounds = YES;
    self.headView.userInteractionEnabled = YES;
    [self.headView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(headViewClick:)]];
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
    
    // 3.日期
    CGFloat timeLabelW = 80;
    CGFloat timeLabelH = headViewW;
    CGFloat timeLabelX = kScreenW - timeLabelW - 10;
    CGFloat timeLabelY = headViewY;
    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(timeLabelX, timeLabelY, timeLabelW, timeLabelH)];
    self.timeLabel.textColor = [UIColor grayColor];
    self.timeLabel.font = [UIFont systemFontOfSize:13];
    self.timeLabel.textAlignment = NSTextAlignmentRight;
    [self.contentView addSubview:self.timeLabel];
    
    // 4.分割线
    self.line = [[UIView alloc] initWithFrame:CGRectMake(nameLabelX, kNewFriendViewCellHeight - 1, kScreenW - nameLabelX, 1)];
    self.line.backgroundColor = [UIColor colorWithRed:239/255.0 green:239/255.0 blue:244/255.0 alpha:1.0f];
    [self.contentView addSubview:self.line];
}

- (void)setFriendModel:(HYRequestModel *)friendModel
{
    _friendModel = friendModel;
    self.nameLabel.text = friendModel.jid.user;
    self.timeLabel.text = [HYUtils timeStringSince1970:friendModel.time];
    __weak typeof(self) weakSelf = self;
    [[HYXMPPManager sharedInstance] getAvatarFromJID:friendModel.jid avatarBlock:^(NSData *avatar) {
        if (avatar.length) {
            weakSelf.headView.image = [UIImage imageWithData:avatar];
        }
    }];
}

/**
 *  点击头像
 */
- (void)headViewClick:(UITapGestureRecognizer *)gesture
{
    UIViewController *vc = [self parentController];
    HYUservCardViewController *userInfoVC = [[HYUservCardViewController alloc] init];
    userInfoVC.userJid = self.friendModel.jid;
    [vc.navigationController pushViewController:userInfoVC animated:YES];
}

@end
