//
//  HYRecentContactsViewCell.m
//  HYChatProject
//
//  Created by erpapa on 16/4/22.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYRecentChatViewCell.h"
#import "HYRecentChatModel.h"
#import "HYXMPPManager.h"
#import "HYUtils.h"
#import "XMPPvCardTemp.h"
#import "YYText.h"
#import "UIView+SW.h"
#import "HYUservCardViewController.h"

#define kPanding 10

@interface HYRecentChatViewCell()
@property (nonatomic, strong) UIImageView *headView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) YYLabel *detailLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIButton *badgeButton;
@property (nonatomic, strong) UIView *line;
@end

@implementation HYRecentChatViewCell

+ (instancetype)cellWithTableView:(UITableView *)tableView
{
    static NSString *ID = @"HYRecentChatViewCellIdentifier";
    HYRecentChatViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (cell == nil){
        cell = [[HYRecentChatViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
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
    CGFloat headViewX = kPanding;
    CGFloat headViewY = margin;
    CGFloat headViewW = kRecentChatViewCellHeight - headViewY * 2;
    // 1.头像
    self.headView = [[UIImageView alloc] initWithFrame:CGRectMake(headViewX, headViewY, headViewW, headViewW)];
    self.headView.contentMode = UIViewContentModeScaleAspectFill;
    self.headView.layer.cornerRadius = headViewW * 0.5;
    self.headView.layer.masksToBounds = YES;
    self.headView.userInteractionEnabled = YES;
    [self.headView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(headViewClick:)]];
    [self.contentView addSubview:self.headView];
    
    // 2.日期
    CGFloat timeLabelW = 60;
    CGFloat timeLabelH = headViewW * 0.5;
    CGFloat timeLabelX = kScreenW - timeLabelW - kPanding;
    CGFloat timeLabelY = headViewY;
    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(timeLabelX, timeLabelY, timeLabelW, timeLabelH)];
    self.timeLabel.textColor = [UIColor grayColor];
    self.timeLabel.font = [UIFont systemFontOfSize:13];
    self.timeLabel.textAlignment = NSTextAlignmentRight;
    [self.contentView addSubview:self.timeLabel];
    
    // 2.昵称
    CGFloat nameLabelX = CGRectGetMaxX(self.headView.frame) + headViewX;
    CGFloat nameLabelY = headViewY;
    CGFloat nameLabelW = CGRectGetMinX(self.timeLabel.frame) - nameLabelX;
    CGFloat nameLabelH = timeLabelH;
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(nameLabelX, nameLabelY, nameLabelW, nameLabelH)];
    self.nameLabel.textColor = [UIColor blackColor];
    self.nameLabel.font = [UIFont systemFontOfSize:20];
    [self.contentView addSubview:self.nameLabel];
    
    // 3.消息内容
    CGFloat detailLabelX = nameLabelX;
    CGFloat detailLabelY = CGRectGetMaxY(self.nameLabel.frame);
    CGFloat detailLabelW = nameLabelW + 20;
    CGFloat detailLabelH = nameLabelH;
    self.detailLabel = [[YYLabel alloc] initWithFrame:CGRectMake(detailLabelX, detailLabelY, detailLabelW, detailLabelH)];
    self.detailLabel.numberOfLines = 1; // 显示一行
    self.detailLabel.textVerticalAlignment = YYTextVerticalAlignmentCenter; // 上下居中
    [self.contentView addSubview:self.detailLabel];
    
    // 4.未读数
    CGFloat badgeViewW = 18;
    CGFloat badgeViewH = badgeViewW;
    CGFloat badgeViewX = kScreenW - kPanding - badgeViewW;
    CGFloat badgeViewY = detailLabelY + (detailLabelH - badgeViewW) * 0.5;
    
    self.badgeButton = [[UIButton alloc] initWithFrame:CGRectMake(badgeViewX, badgeViewY, badgeViewW, badgeViewW)];
    [self.badgeButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f] size:CGSizeMake(badgeViewW * 2, badgeViewW * 2)] forState:UIControlStateNormal];
    self.badgeButton.titleLabel.font = [UIFont systemFontOfSize:13];
    self.badgeButton.layer.cornerRadius = badgeViewH * 0.5;
    self.badgeButton.layer.masksToBounds = YES;
    [self.contentView addSubview:self.badgeButton];
    
    // 5.分割线
    self.line = [[UIView alloc] initWithFrame:CGRectMake(nameLabelX, kRecentChatViewCellHeight - 1, kScreenW - nameLabelX, 1)];
    self.line.backgroundColor = [UIColor colorWithRed:239/255.0 green:239/255.0 blue:244/255.0 alpha:1.0f];
    [self.contentView addSubview:self.line];
}

- (void)setChatModel:(HYRecentChatModel *)chatModel
{
    _chatModel = chatModel;
    self.headView.image = chatModel.isGroup ? [UIImage imageNamed:@"defaultGroupHead"] : [UIImage imageNamed:@"defaultHead"];
    self.nameLabel.text = chatModel.jid.user;
    self.detailLabel.attributedText = chatModel.attText; // 赋值属性字符串
    self.timeLabel.text = [HYUtils timeStringSince1970:chatModel.time];
    // 未读消息数
    self.badgeButton.frame = [self frameWithUnreadCount:chatModel.unreadCount];
    NSString *badgeValue = [HYUtils stringFromUnreadCount:chatModel.unreadCount];
    self.badgeButton.hidden = badgeValue.length ? NO : YES;
    [self.badgeButton setTitle:badgeValue forState:UIControlStateNormal];
    __weak typeof(self) weakSelf = self;
    [[HYXMPPManager sharedInstance] getAvatarFromJID:chatModel.jid avatarBlock:^(NSData *avatar) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (avatar.length) {
            strongSelf.headView.image = [UIImage imageWithData:avatar];
        }
    }];
    
}
/**
 *  返回frame
 */
- (CGRect)frameWithUnreadCount:(int)unreadCount
{
    CGRect newFrame = self.badgeButton.frame;
    if (unreadCount < 10) {
        newFrame.size.width = 18;
        newFrame.origin.x = kScreenW - kPanding - 18;
    } else if (unreadCount < 100) {
        newFrame.size.width = 25;
        newFrame.origin.x = kScreenW - kPanding - 24;
    } else {
        newFrame.size.width = 30;
        newFrame.origin.x = kScreenW - kPanding - 30;
    }
    return newFrame;
}

/**
 *  点击头像
 */

- (void)headViewClick:(UITapGestureRecognizer *)gesture
{
    UIViewController *vc = [self parentController];
    HYUservCardViewController *vCardVC = [[HYUservCardViewController alloc] init];
    vCardVC.userJid = self.chatModel.jid;
    [vc.navigationController pushViewController:vCardVC animated:YES];
}

@end
