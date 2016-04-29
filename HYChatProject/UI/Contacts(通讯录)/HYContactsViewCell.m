//
//  HYContactsViewCell.m
//  HYChatProject
//
//  Created by erpapa on 16/4/22.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYContactsViewCell.h"
#import "HYContactsModel.h"
#import "HYXMPPManager.h"
#import "XMPPvCardTemp.h"
#import "HYUtils.h"

@interface HYContactsViewCell()
@property (nonatomic, strong) UIImageView *headView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UIImageView *netView;
@property (nonatomic, strong) UIView *line;

@end

@implementation HYContactsViewCell

+ (instancetype)cellWithTableView:(UITableView *)tableView
{
    static NSString *ID = @"HYContactsViewCellIdentifier";
    HYContactsViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (cell == nil){
        cell = [[HYContactsViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
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
    CGFloat headViewW = kContactsViewCellHeight - headViewY * 2;
    // 1.头像
    self.headView = [[UIImageView alloc] initWithFrame:CGRectMake(headViewX, headViewY, headViewW, headViewW)];
    self.headView.image = [UIImage imageNamed:@"defaultHead"];
    self.headView.contentMode = UIViewContentModeScaleAspectFill;
    self.headView.layer.cornerRadius = headViewW * 0.5;
    self.headView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.headView];
    
    // 2.网络状况
    CGFloat netViewlH = headViewW * 0.5;
    CGFloat netViewX = kScreenW - netViewlH - margin;
    CGFloat netViewY = headViewY;
    self.netView = [[UIImageView alloc] initWithFrame:CGRectMake(netViewX, netViewY, netViewlH, netViewlH)];
    [self.contentView addSubview:self.netView];
    
    // 3.昵称
    CGFloat nameLabelX = CGRectGetMaxX(self.headView.frame) + headViewX;
    CGFloat nameLabelY = headViewY;
    CGFloat nameLabelW = CGRectGetMinX(self.netView.frame) - nameLabelX;
    CGFloat nameLabelH = netViewlH;
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(nameLabelX, nameLabelY, nameLabelW, nameLabelH)];
    self.nameLabel.textColor = [UIColor blackColor];
    self.nameLabel.font = [UIFont systemFontOfSize:18];
    [self.contentView addSubview:self.nameLabel];
    
    // 4.[状态] 签名
    CGFloat detailLabelX = nameLabelX;
    CGFloat detailLabelY = CGRectGetMaxY(self.nameLabel.frame);
    CGFloat detailLabelW = nameLabelW + 20;
    CGFloat detailLabelH = nameLabelH;
    self.detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(detailLabelX, detailLabelY, detailLabelW, detailLabelH)];
    self.detailLabel.textColor = [UIColor grayColor];
    self.detailLabel.font = [UIFont systemFontOfSize:14];
    [self.contentView addSubview:self.detailLabel];
    
    // 5.分割线
    self.line = [[UIView alloc] initWithFrame:CGRectMake(nameLabelX, kContactsViewCellHeight - 1, kScreenW - nameLabelX, 1)];
    self.line.backgroundColor = [UIColor colorWithRed:239/255.0 green:239/255.0 blue:244/255.0 alpha:1.0f];
    [self.contentView addSubview:self.line];
}

- (void)setModel:(HYContactsModel *)model
{
    _model = model;
    self.nameLabel.text = model.jid.user;
    NSString *sectionNum = [HYUtils stringFromSectionNum:model.sectionNum];
    self.detailLabel.text = [NSString stringWithFormat:@"%@ %@",sectionNum, model.signature];
    __weak typeof(self) weakSelf = self;
    [[HYXMPPManager sharedInstance] getvCardFromJID:model.jid vCardBlock:^(XMPPvCardTemp *vCardTemp) {
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
