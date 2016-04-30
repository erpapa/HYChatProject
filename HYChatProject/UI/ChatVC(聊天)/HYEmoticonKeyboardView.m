//
//  HYEmoticonInputView.m
//  HYChatProject
//
//  Created by erpapa on 16/4/30.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYEmoticonKeyboardView.h"

@implementation HYEmoticonKeyboardView
static HYEmoticonKeyboardView *instance;

+ (instancetype)sharedView
{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

@end
