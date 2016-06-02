//
//  HYMyvCardViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/5/1.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYQRCodeViewController.h"
#import "HYUtils.h"
#import "XMPPvCardTemp.h"
#import "HYXMPPManager.h"

@interface HYQRCodeViewController ()

@property (strong, nonatomic) UIImageView *codeView;
@property (nonatomic, strong) UIView *footerView;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *detailLabel;

@end

@implementation HYQRCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"二维码";
    self.view.backgroundColor = [UIColor colorWithRed:241/255.0 green:241/255.0 blue:241/255.0 alpha:1.0f];
    
    CGFloat codeViewX = 35;
    CGFloat codeViewWidth = CGRectGetWidth(self.view.frame) - codeViewX * 2;
    CGFloat codeViewHeight = codeViewWidth * 1.1;
    self.codeView = [[UIImageView alloc] initWithFrame:CGRectMake(codeViewX, 96, codeViewWidth, codeViewHeight)];
    self.codeView.contentMode = UIViewContentModeCenter;
    self.codeView.backgroundColor = [UIColor colorWithRed:222/250.0 green:222/250.0 blue:222/250.0 alpha:1.0f];
    [self.view addSubview:self.codeView];
    
    CGFloat footerViewHeight = 54;
    self.footerView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.codeView.frame), CGRectGetMaxY(self.codeView.frame), codeViewWidth, footerViewHeight)];
    self.footerView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.footerView];
    
    // 头像
    CGFloat iconViewX = 8;
    CGFloat iconViewY = 5;
    CGFloat iconViewHeight = footerViewHeight - iconViewY * 2;
    self.iconView = [[UIImageView alloc] initWithFrame:CGRectMake(iconViewX, iconViewY, iconViewHeight, iconViewHeight)];
    [self.footerView addSubview:self.iconView];
    
    CGFloat labelX = CGRectGetMaxX(self.iconView.frame) + iconViewX;
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelX, CGRectGetMinY(self.iconView.frame), CGRectGetWidth(self.footerView.frame) - labelX, 22)];
    [self.footerView addSubview:self.nameLabel];
    
    self.detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelX, CGRectGetMaxY(self.nameLabel.frame), CGRectGetWidth(self.footerView.frame) - labelX, 22)];
    self.detailLabel.text = @"扫一扫二维码，加我好友。";
    self.detailLabel.font = [UIFont systemFontOfSize:14];
    self.detailLabel.textColor = [UIColor grayColor];
    [self.footerView addSubview:self.detailLabel];
    
    
    __weak typeof(self) weakSelf = self;
    [[HYXMPPManager sharedInstance] getvCardFromJID:self.jid vCardBlock:^(XMPPvCardTemp *vCardTemp) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        UIImage *iconImage = [UIImage imageWithData:vCardTemp.photo];
        UIImage *circleImage = [iconImage circleImage];
        strongSelf.iconView.image = circleImage;
        strongSelf.nameLabel.text = vCardTemp.nickname.length ? vCardTemp.nickname : strongSelf.jid.user;
        
        // 生成二维码
        UIImage *codeImage = [UIImage createQRCodeWithString:self.jid.bare size:CGSizeMake(codeViewWidth - 20, codeViewWidth - 20)];
        UIImage *image0 = [codeImage changeColorWithRed:0.0 green:0.0 blue:0.0];
        // 添加头像上去
        UIImage *image1 = [image0 addIconImage:circleImage withScale:0.2];
        strongSelf.codeView.image = image1;
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
