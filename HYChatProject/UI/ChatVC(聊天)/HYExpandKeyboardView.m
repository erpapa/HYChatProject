//
//  HYExpandKeyboardView.m
//  HYChatProject
//
//  Created by erpapa on 16/4/30.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYExpandKeyboardView.h"

@implementation HYExpandKeyboardView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = COLOR(245, 245, 245, 1.0f);
        [self setupContentView];
    }
    return self;
}

- (void)setupContentView
{
    // 1.topLine
    UIView *topLine = [[UIView alloc] init];
    topLine.backgroundColor = [UIColor colorWithRed:222/255.0f green:222/255.0f blue:222/255.0f alpha:1.0f];
    topLine.frame = CGRectMake(0, 0, kScreenW, 1);
    [self addSubview:topLine];
    
    // 2.
    NSArray *imageArray = @[@"expand_icons_pic",@"expand_icons_camera",@"expand_icons_video",@"expand_icons_folder"];
    NSArray *titleArray = @[@"照片",@"拍照",@"视频",@"文件"];
    
    CGFloat margin = 22;
    CGFloat panding = 16;
    CGFloat buttonW = (kScreenW - panding * 2 - margin * 3) / 4;
    CGFloat buttonH = (kPanelHeight - panding * 2) * 0.5;
    for (NSInteger index = 0; index < 4; index++) {
        CGFloat buttonX = panding + (margin + buttonW) * index;
        HYExpandButton *button = [[HYExpandButton alloc] initWithFrame:CGRectMake(buttonX, panding, buttonW, buttonH)];
        button.tag = index;
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [button setTitle:titleArray[index] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:imageArray[index]] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
    }
    
}

- (void)buttonClick:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(expandKeyboardView:clickWithType:)]) {
        [self.delegate expandKeyboardView:self clickWithType:sender.tag];
    }
}

@end


@implementation HYExpandButton : UIButton

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.imageView.contentMode = UIViewContentModeCenter;
        self.imageView.layer.cornerRadius = 8;
        self.imageView.layer.masksToBounds = YES;
        self.titleLabel.font = [UIFont systemFontOfSize:14];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return self;
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
    CGFloat imageX = 0;
    CGFloat imageY = 0;
    CGFloat imageW = contentRect.size.width;
    CGFloat imageH = imageW;
    return CGRectMake(imageX, imageY, imageW, imageH);
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    CGFloat titleX = 0;
    CGFloat titleY = contentRect.size.width;
    CGFloat titleW = contentRect.size.width;
    CGFloat titleH = 28;
    return CGRectMake(titleX, titleY, titleW, titleH);
}

@end