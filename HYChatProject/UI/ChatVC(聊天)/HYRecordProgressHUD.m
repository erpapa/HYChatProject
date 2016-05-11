//
//  HYRecordProgressHUD.m
//  HYChatProject
//
//  Created by erpapa on 16/5/7.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYRecordProgressHUD.h"

@interface HYRecordProgressHUD()

@property (nonatomic, strong) UIImageView *edgeImageView;
@property (nonatomic, strong) UILabel *centerLabel;
@property (nonatomic, assign) NSInteger angle;
@property (nonatomic, strong) NSTimer *myTimer;
@end

@implementation HYRecordProgressHUD

+ (instancetype)sharedView {
    static dispatch_once_t once;
    static HYRecordProgressHUD *sharedView;
    dispatch_once(&once, ^ {
        sharedView = [[HYRecordProgressHUD alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        sharedView.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.4];
    });
    return sharedView;
}

+ (void)showWithTitle:(NSString *)title{
    HYRecordProgressHUD *hud = [HYRecordProgressHUD sharedView];
    [hud showWithTitle:title];
    [[UIApplication sharedApplication].keyWindow addSubview:hud];
}

- (void)showWithTitle:(NSString *)title{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.centerLabel){
            self.centerLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 150, 40)];
            self.centerLabel.backgroundColor = [UIColor clearColor];
            self.centerLabel.center = CGPointMake([[UIScreen mainScreen] bounds].size.width/2,[[UIScreen mainScreen] bounds].size.height/2);
            self.centerLabel.text = @"60";
            self.centerLabel.textAlignment = NSTextAlignmentCenter;
            self.centerLabel.font = [UIFont systemFontOfSize:30];
            self.centerLabel.textColor = [UIColor yellowColor];
            [self addSubview:self.centerLabel];
        }
        
        if (!self.subTitleLabel){
            self.subTitleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 150, 20)];
            self.subTitleLabel.backgroundColor = [UIColor clearColor];
            self.subTitleLabel.center = CGPointMake([[UIScreen mainScreen] bounds].size.width/2,[[UIScreen mainScreen] bounds].size.height/2 + 30);
            self.subTitleLabel.text = title;
            self.subTitleLabel.textAlignment = NSTextAlignmentCenter;
            self.subTitleLabel.font = [UIFont boldSystemFontOfSize:14];
            self.subTitleLabel.textColor = [UIColor whiteColor];
            [self addSubview:self.subTitleLabel];
        }
        if (!self.titleLabel){
            self.titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 150, 20)];
            self.titleLabel.backgroundColor = [UIColor clearColor];
            self.titleLabel.center = CGPointMake([[UIScreen mainScreen] bounds].size.width/2,[[UIScreen mainScreen] bounds].size.height/2 - 30);
            self.titleLabel.text = @"Time Limit";
            self.titleLabel.textAlignment = NSTextAlignmentCenter;
            self.titleLabel.font = [UIFont boldSystemFontOfSize:18];
            self.titleLabel.textColor = [UIColor whiteColor];
            [self addSubview:self.titleLabel];
        }
        if (!self.edgeImageView){
            self.edgeImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"Chat_record_circle"]];
            self.edgeImageView.frame = CGRectMake(0, 0, 154, 154);
            self.edgeImageView.center = self.centerLabel.center;
            [self addSubview:self.edgeImageView];
        }
        
        if (self.myTimer){
            [self.myTimer invalidate];
            self.myTimer = nil;
        }
        self.myTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(startAnimation) userInfo:nil repeats:YES];
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
        animations:^{
            self.alpha = 1;
        } completion:^(BOOL finished){ }];
        [self setNeedsDisplay];
    });
}
- (void)startAnimation
{
    self.angle -= 3;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.09];
    UIView.AnimationRepeatAutoreverses = YES;
    self.edgeImageView.transform = CGAffineTransformMakeRotation(self.angle * (M_PI / 180.0f));
    float second = [self.centerLabel.text floatValue];
    if (second <= 10.0f) {
        self.centerLabel.textColor = [UIColor redColor];
    }else{
        self.centerLabel.textColor = [UIColor yellowColor];
    }
    self.centerLabel.text = [NSString stringWithFormat:@"%.1f",second-0.1];
    [UIView commitAnimations];
}

+ (void)changeSubTitle:(NSString *)title
{
    [[HYRecordProgressHUD sharedView] setState:title];
}

- (void)setState:(NSString *)str
{
    self.subTitleLabel.text = str;
}

+ (void)dismissWithTitle:(NSString *)title
{
    [[HYRecordProgressHUD sharedView] dismiss:title];
}

- (void)dismiss:(NSString *)title
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.superview) return ;
        [self.myTimer invalidate];
        self.myTimer = nil;
        self.subTitleLabel.text = nil;
        self.titleLabel.text = nil;
        self.centerLabel.text = title;
        self.centerLabel.textColor = [UIColor whiteColor];
        self.centerLabel.font = [UIFont systemFontOfSize:18];
        [UIView animateWithDuration:1.2 delay:0 options:UIViewAnimationCurveEaseIn | UIViewAnimationOptionAllowUserInteraction animations:^{
            self.alpha = 0;
        } completion:^(BOOL finished){
            if(finished) {
                [self.centerLabel removeFromSuperview];
                [self.titleLabel removeFromSuperview];
                [self.edgeImageView removeFromSuperview];
                [self.subTitleLabel removeFromSuperview];
                [self removeFromSuperview];
                self.subTitleLabel = nil;
                self.titleLabel = nil;
                self.edgeImageView = nil;
                self.centerLabel = nil;
            }
        }];
    });
}

@end
