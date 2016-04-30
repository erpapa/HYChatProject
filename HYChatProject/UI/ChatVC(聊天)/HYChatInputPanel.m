//
//  HYChatInputPanel.m
//  HYChatProject
//
//  Created by erpapa on 16/4/29.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYChatInputPanel.h"
#import "HYInputKeyboardBar.h"
#import "HYEmoticonKeyboardView.h"
#import "HYExpandKeyboardView.h"

@interface HYChatInputPanel()
@property (nonatomic, strong) HYInputKeyboardBar *inputBar;
@property (nonatomic, strong) HYEmoticonKeyboardView *emoticonView;
@property (nonatomic, strong) HYExpandKeyboardView *expandView ;
@end

@implementation HYChatInputPanel

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupContentView];
    }
    return self;
}

- (void)setupContentView
{
    self.inputBar = [[HYInputKeyboardBar alloc] init];
    [self addSubview:self.inputBar];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.inputBar.frame = CGRectMake(0, 0, kInputBarWidth, kInputBarHeight);
    
}

@end
