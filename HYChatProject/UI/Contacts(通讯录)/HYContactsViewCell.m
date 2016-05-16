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
#import "UIView+SW.h"
#import "HYUservCardViewController.h"


@interface HYContactsViewCell()
@property (nonatomic, strong) UIImageView *headView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIImageView *statusView;
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
    
    // 3.[状态]
    CGFloat statusViewW = 6;
    CGFloat statusViewX = CGRectGetMaxX(self.headView.frame) - statusViewW;
    CGFloat statusViewY = CGRectGetMaxY(self.headView.frame) - statusViewW;
    self.statusView = [[UIImageView alloc] initWithFrame:CGRectMake(statusViewX, statusViewY, statusViewW, statusViewW)];
    self.statusView.image = [UIImage circleImageWithColor:[UIColor colorWithRed:239/255.0 green:239/255.0 blue:244/255.0 alpha:1.0f] size:CGSizeMake(12, 12)];
    [self.contentView addSubview:self.statusView];
    
    
    // 4.分割线
    self.line = [[UIView alloc] initWithFrame:CGRectMake(nameLabelX, kContactsViewCellHeight - 1, kScreenW - nameLabelX, 1)];
    self.line.backgroundColor = [UIColor colorWithRed:239/255.0 green:239/255.0 blue:244/255.0 alpha:1.0f];
    [self.contentView addSubview:self.line];
}

- (void)setModel:(HYContactsModel *)model
{
    _model = model;
    self.nameLabel.text = model.nickName;
    self.statusView.image = [self imageFromSectionNum:model.sectionNum];
    __weak typeof(self) weakSelf = self;
    [[HYXMPPManager sharedInstance] getAvatarFromJID:model.jid avatarBlock:^(NSData *avatar) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (avatar.length) {
            strongSelf.headView.image = [UIImage imageWithData:avatar];
        }
    }];
}

- (UIImage *)imageFromSectionNum:(NSInteger)sectionNum
{
    UIImage *image = nil;
    switch (sectionNum) {
        case 0:{
            image = [UIImage circleImageWithColor:[UIColor colorWithRed:41/255.0 green:196/255.0 blue:50/255.0 alpha:1.0f] size:CGSizeMake(12, 12)];
            break;
        }
        case 1:{
            image = [UIImage circleImageWithColor:[UIColor colorWithRed:254/255.0 green:186/255.0 blue:20/255.0 alpha:1.0f] size:CGSizeMake(12, 12)];
            break;
        }
        case 2:{
            image = [UIImage circleImageWithColor:[UIColor colorWithRed:176/255.0 green:176/255.0 blue:176/255.0 alpha:1.0f] size:CGSizeMake(12, 12)];
            break;
        }
            
        default:
            break;
    }
    return image;
}


/**
 *  点击头像
 */

- (void)headViewClick:(UITapGestureRecognizer *)gesture
{
    UIViewController *vc = [self parentController];
    HYUservCardViewController *vCardVC = [[HYUservCardViewController alloc] init];
    vCardVC.userJid = self.model.jid;
    [vc.navigationController pushViewController:vCardVC animated:YES];
}

@end
