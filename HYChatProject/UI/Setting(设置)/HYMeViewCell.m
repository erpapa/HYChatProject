//
//  HYMeViewCell.m
//  HYChatProject
//
//  Created by erpapa on 16/4/27.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYMeViewCell.h"
#import "XMPPvCardTemp.h"
#import "HYLoginInfo.h"

@interface HYMeViewCell()
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UIImageView *QRView;

@end

@implementation HYMeViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initSubviews];
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator; // 箭头
        UIView *selectedBGView = [[UIView alloc] init];
        selectedBGView.backgroundColor = [UIColor colorWithRed:245/255.0 green:245/255.0 blue:245/255.0 alpha:1.0f];
        self.selectedBackgroundView = selectedBGView;
    }
    return self;
}

- (void)initSubviews
{
    CGFloat margin = 8.0;
    CGFloat panding = 12.0;
    CGFloat iconViewX = panding;
    CGFloat iconViewY = margin;
    CGFloat iconViewW = kMeViewCellHeight - iconViewY * 2;
    // 1.头像
    self.iconView = [[UIImageView alloc] initWithFrame:CGRectMake(iconViewX, iconViewY, iconViewW, iconViewW)];
    self.iconView.contentMode = UIViewContentModeScaleAspectFill;
    self.iconView.layer.cornerRadius = iconViewW * 0.5;
    self.iconView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.iconView];
    
    // 2.二维码
    CGFloat QRViewW = 36;
    CGFloat QRViewX = kScreenW - 40;
    CGFloat QRViewY = (kMeViewCellHeight - QRViewW) * 0.5;
    self.QRView = [[UIImageView alloc] initWithFrame:CGRectMake(QRViewX, QRViewY, QRViewW, QRViewW)];
    [self.contentView addSubview:self.QRView];
    
    // 3.昵称
    CGFloat nameLabelX = CGRectGetMaxX(self.iconView.frame) + iconViewX;
    CGFloat nameLabelY = iconViewY;
    CGFloat nameLabelW = CGRectGetMinX(self.QRView.frame) - nameLabelX;
    CGFloat nameLabelH = iconViewW * 0.5;
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(nameLabelX, nameLabelY, nameLabelW, nameLabelH)];
    self.nameLabel.textColor = [UIColor blackColor];
    self.nameLabel.font = [UIFont systemFontOfSize:20];
    [self.contentView addSubview:self.nameLabel];
    
    // 4.帐号
    CGFloat detailLabelX = nameLabelX;
    CGFloat detailLabelY = CGRectGetMaxY(self.nameLabel.frame);
    CGFloat detailLabelW = nameLabelW + 20;
    CGFloat detailLabelH = nameLabelH;
    self.detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(detailLabelX, detailLabelY, detailLabelW, detailLabelH)];
    self.detailLabel.textColor = [UIColor grayColor];
    self.detailLabel.font = [UIFont systemFontOfSize:14];
    [self.contentView addSubview:self.detailLabel];

}

- (void)setVCard:(XMPPvCardTemp *)vCard
{
    _vCard = vCard;
    self.iconView.image = [UIImage imageWithData:vCard.photo];
    NSString *user = [HYLoginInfo sharedInstance].user;
    self.nameLabel.text = vCard.nickname.length ? vCard.nickname : user;
    self.detailLabel.text = [NSString stringWithFormat:@"帐号: %@",user];
}

@end
