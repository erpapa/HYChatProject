//
//  HYRecordProgressHUD.h
//  HYChatProject
//
//  Created by erpapa on 16/5/7.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HYRecordProgressHUD : UIView

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;

+ (void)showWithTitle:(NSString *)title;

+ (void)dismissWithTitle:(NSString *)title;

+ (void)changeSubTitle:(NSString *)title;

@end
