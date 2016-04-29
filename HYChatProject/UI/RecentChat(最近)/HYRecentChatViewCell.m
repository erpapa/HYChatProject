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

@interface HYRecentChatViewCell()
@property (nonatomic, strong) UIImageView *headView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIImageView *badgeView;
@property (nonatomic, strong) UILabel *badgeLabel;
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
    CGFloat panding = 10.0; // 左右间隔
    CGFloat headViewX = panding;
    CGFloat headViewY = margin;
    CGFloat headViewW = kRecentChatViewCellHeight - headViewY * 2;
    // 1.头像
    self.headView = [[UIImageView alloc] initWithFrame:CGRectMake(headViewX, headViewY, headViewW, headViewW)];
    self.headView.image = [UIImage imageNamed:@"defaultHead"];
    self.headView.contentMode = UIViewContentModeScaleAspectFill;
    self.headView.layer.cornerRadius = headViewW * 0.5;
    self.headView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.headView];
    
    // 2.日期
    CGFloat timeLabelW = 60;
    CGFloat timeLabelH = headViewW * 0.5;
    CGFloat timeLabelX = kScreenW - timeLabelW - panding;
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
    self.detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(detailLabelX, detailLabelY, detailLabelW, detailLabelH)];
    self.detailLabel.textColor = [UIColor grayColor];
    self.detailLabel.font = [UIFont systemFontOfSize:14];
    [self.contentView addSubview:self.detailLabel];
    
    // 4.未读数
    CGFloat badgeViewW = 20;
    CGFloat badgeViewX = kScreenW - badgeViewW - panding;
    CGFloat badgeViewY = detailLabelY + (detailLabelH - badgeViewW) * 0.5;
    
    self.badgeView = [[UIImageView alloc] initWithFrame:CGRectMake(badgeViewX, badgeViewY, badgeViewW, badgeViewW)];
    self.badgeView.image = [UIImage imageWithColor:[UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f] size:CGSizeMake(badgeViewW * 2, badgeViewW * 2)];
    self.badgeView.layer.cornerRadius = badgeViewW * 0.5;
    self.badgeView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.badgeView];
    
    self.badgeLabel= [[UILabel alloc] initWithFrame:self.badgeView.bounds];
    self.badgeLabel.textColor = [UIColor whiteColor];
    self.badgeLabel.font = [UIFont systemFontOfSize:14];
    self.badgeLabel.textAlignment = NSTextAlignmentCenter;
    [self.badgeView addSubview:self.badgeLabel];
    
    // 5.分割线
    self.line = [[UIView alloc] initWithFrame:CGRectMake(nameLabelX, kRecentChatViewCellHeight - 1, kScreenW - nameLabelX, 1)];
    self.line.backgroundColor = [UIColor colorWithRed:239/255.0 green:239/255.0 blue:244/255.0 alpha:1.0f];
    [self.contentView addSubview:self.line];
}

- (void)setChatModel:(HYRecentChatModel *)chatModel
{
    _chatModel = chatModel;
    self.nameLabel.text = chatModel.jid.user;
    self.detailLabel.text = chatModel.body;
    self.timeLabel.text = [HYUtils timeStringSince1970:chatModel.time];
    NSString *badgeValue = [HYUtils stringFromUnreadCount:chatModel.unreadCount];
    self.badgeView.hidden = badgeValue.length ? NO : YES;
    self.badgeLabel.text = badgeValue;
    __weak typeof(self) weakSelf = self;
    [[HYXMPPManager sharedInstance] getvCardFromJID:chatModel.jid vCardBlock:^(XMPPvCardTemp *vCardTemp) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (vCardTemp.photo) {
            strongSelf.headView.image = [UIImage imageWithData:vCardTemp.photo];
        }
        if (vCardTemp.nickname.length) {
            strongSelf.nameLabel.text = vCardTemp.nickname;
        }
    }];
    
}

@end
