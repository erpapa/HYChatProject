//
//  HYInputBar.m
//  HYChatProject
//
//  Created by erpapa on 16/4/30.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYInputKeyboardBar.h"
#import "YYText.h"

@interface HYInputKeyboardBar()
@property (nonatomic, strong) YYTextView *textView;   // 输入框
@property (nonatomic, strong) UIButton *voiceButton;  // 语音
@property (nonatomic, strong) UIButton *emoButton;    // 表情
@property (nonatomic, strong) UIButton *expandButton; // 扩展
@property (nonatomic, strong) UIButton *pressButton;  // 语音长按button（同时充当输入框背景）

@end


@implementation HYInputKeyboardBar

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
    // 1.语音
    self.voiceButton = [[UIButton alloc] init];
    [self.voiceButton setImage:[UIImage imageNamed:@"chat_bottom_voice_nor"] forState:UIControlStateNormal];
    [self.voiceButton setImage:[UIImage imageNamed:@"chat_bottom_voice_press"] forState:UIControlStateHighlighted];
    [self.voiceButton addTarget:self action:@selector(voiceButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.voiceButton];
    
    // 2.pressButton
    self.pressButton = [[UIButton alloc] init];
    UIImage *normalImage = [[UIImage imageNamed:@"chat_bottom_textfield"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 50, 20, 120) resizingMode:UIImageResizingModeStretch];
    [self.pressButton setBackgroundImage:normalImage forState:UIControlStateNormal];
    [self.pressButton addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
    [self.pressButton addTarget:self action:@selector(touchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [self.pressButton addTarget:self action:@selector(touchOutside:) forControlEvents:UIControlEventTouchUpOutside];
    [self addSubview:self.pressButton];
    
    // 3.textView
    self.textView = [[YYTextView alloc] init];
    [self addSubview:self.textView];
    
    // 4.表情
    self.emoButton = [[UIButton alloc] init];
    [self.emoButton setImage:[UIImage imageNamed:@"chat_bottom_smile_nor"] forState:UIControlStateNormal];
    [self.emoButton setImage:[UIImage imageNamed:@"chat_bottom_smile_press"] forState:UIControlStateHighlighted];
    [self.emoButton addTarget:self action:@selector(emoButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.emoButton];
    
    // 5.扩展功能
    self.expandButton = [[UIButton alloc] init];
    [self.expandButton setImage:[UIImage imageNamed:@"chat_bottom_up_nor"] forState:UIControlStateNormal];
    [self.expandButton setImage:[UIImage imageNamed:@"chat_bottom_up_press"] forState:UIControlStateHighlighted];
    [self.expandButton addTarget:self action:@selector(expandButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.expandButton];
}

/**
 *  点击语音按钮
 */
- (void)voiceButtonClick:(UIButton *)sender
{
    
}

/**
 *  点击表情按钮
 */
- (void)emoButtonClick:(UIButton *)sender
{
    
}

/**
 *  点击扩展按钮
 */
- (void)expandButtonClick:(UIButton *)sender
{
    
}

#pragma mark - 录音
/**
 *  按下button
 */
- (void)touchDown:(UIButton *)sender
{
//    [self.imageView startAnimating];
//    self.second = 0.0f;
//    self.timer = [NSTimer timerWithTimeInterval:0.1f target:self selector:@selector(addSecond) userInfo:nil repeats:YES];
//    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
//    [self startRecorder];
}
/**
 *  在button内部移开
 */
- (void)touchUpInside:(UIButton *)sender
{
//    [self.imageView stopAnimating];
//    [self.timer invalidate];
//    self.timer = nil;
//    if (self.second < 2.5f) {
//        [self stopRecorderAndDelete:YES];
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"说话时间太短" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
//        [alertView show];
//    } else {
//        [self stopRecorderAndDelete:NO];
//    }
}
/**
 *  在button外部移开
 */
- (void)touchOutside:(UIButton *)sender
{
//    [self.imageView stopAnimating];
//    [self.timer invalidate];
//    self.timer = nil;
//    [self stopRecorderAndDelete:YES];
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"已取消录音" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
//    [alertView show];
}
@end
