//
//  HYActionSheetViewController.h
//  colorv
//
//  Created by erpapa on 16/3/30.
//  Copyright © 2016年 apple. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void(^HYActionBlock)(void);

@interface HYActionSheetController : UIViewController
- (instancetype)initWithTitle:(NSString *)title;
- (void)addActionTitle:(NSString *)title withBlock:(HYActionBlock)block;
- (void)addActionTitle:(NSString *)title andColor:(UIColor *)titleColor withBlock:(HYActionBlock)block;
@end
