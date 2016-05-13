//
//  HYInputViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/4/29.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYInputViewController.h"
#import "HYEmoticonKeyboardView.h"
#import "HYExpandKeyboardView.h"
#import "YYKeyboardManager.h"
#import "YYTextView.h"
#import "HYChatMessage.h"
#import "HYEmoticonTool.h"
#import "HYRecordProgressHUD.h"
#import "GJCFAudioModel.h"
#import "GJCFAudioFileUitil.h"
#import "GJCFEncodeAndDecode.h"
#import "GJCFAudioRecord.h"


#define kNormalButtonBottom 7
#define kTextViewMargin 6
#define kTextViewBottom 10
//输入框最小高度
#define kTextViewMinHeight (kInputBarHeight - kTextViewBottom * 2)
//输入框最大高度
#define kTextViewMaXHeight 64

typedef NS_ENUM(NSInteger, HYChatInputPanelStatus) {
    HYChatInputPanelStatusNone,     // 没有输入
    HYChatInputPanelStatusText,     // 文字输入
    HYChatInputPanelStatusAudio,    // 语音输入
    HYChatInputPanelStatusEmoticon, // 表情输入
    HYChatInputPanelStatusExpand    // 扩展
};

@interface HYInputViewController()<HYEmoticonKeyboardViewDelegate, HYExpandKeyboardViewDelegate, YYKeyboardObserver, YYTextViewDelegate, GJCFAudioRecordDelegate>

@property (nonatomic, strong) UIView *line;           // 顶部添加一条线
@property (nonatomic, strong) UIButton *audioButton;  // 语音
@property (nonatomic, strong) YYTextView *textView;   // 输入框
@property (nonatomic, strong) UIButton *expandButton; // 扩展
@property (nonatomic, strong) UIButton *emoButton;    // 表情
@property (nonatomic, strong) UIButton *pressButton;  // 语音长按button（同时充当输入框背景）
@property (nonatomic, strong) UIButton *otherButton;  // 用于显示输入键盘
@property (nonatomic, strong) HYEmoticonKeyboardView *emoticonView;
@property (nonatomic, strong) HYExpandKeyboardView *expandView;
@property (nonatomic, assign) HYChatInputPanelStatus panelStatus;
@property (nonatomic, assign) CGFloat textViewHeight;

/* 录音组件 */
@property (nonatomic, strong) GJCFAudioRecord *audioRecord;
@end

@implementation HYInputViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupContentView];
    self.textViewHeight = kTextViewMinHeight;
    self.panelStatus = HYChatInputPanelStatusNone;
    [[YYKeyboardManager defaultManager] addObserver:self];
    /* 初始化录音组件 */
    [self initAudioRecord];
}

- (void)setupContentView
{
    self.view.backgroundColor = [UIColor colorWithRed:249/255.0f green:249/255.0f blue:249/255.0f alpha:0.98f];
    // 0.线
    self.line = [[UIView alloc] init];
    self.line.backgroundColor = [UIColor colorWithRed:222/255.0f green:222/255.0f blue:222/255.0f alpha:1.0f];
    [self.view addSubview:self.line];
    
    // 1.语音
    self.audioButton = [[UIButton alloc] init];
    [self.audioButton addTarget:self action:@selector(audioButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.audioButton];
    
    // 2.pressButton
    self.pressButton = [[UIButton alloc] init];
    [self.pressButton setTitleColor:[UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0] forState:UIControlStateNormal];
    [self.pressButton setTitle:@"按住 说话" forState:UIControlStateNormal];
    self.pressButton.titleLabel.font = [UIFont systemFontOfSize:16];
    UIImage *normalImage = [[UIImage imageNamed:@"chat_bottom_textfield"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 5, 20, 10) resizingMode:UIImageResizingModeStretch];
    [self.pressButton setBackgroundImage:normalImage forState:UIControlStateNormal];
    [self.pressButton addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
    [self.pressButton addTarget:self action:@selector(dragInside:) forControlEvents:UIControlEventTouchDragInside];
    [self.pressButton addTarget:self action:@selector(dragOutside:) forControlEvents:UIControlEventTouchDragOutside];
    [self.pressButton addTarget:self action:@selector(touchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [self.pressButton addTarget:self action:@selector(touchOutside:) forControlEvents:UIControlEventTouchUpOutside];
    [self.view addSubview:self.pressButton];
    
    // 3.textView
    self.textView = [[YYTextView alloc] init];
    self.textView.delegate = self;
    self.textView.font = [UIFont systemFontOfSize:16];
    self.textView.backgroundColor = [UIColor whiteColor];
    self.textView.returnKeyType = UIReturnKeySend; // 发送
    self.textView.textParser = [HYEmoticonTool sharedInstance].emoticonParser;// 表情匹配
    
    self.textView.showsHorizontalScrollIndicator = NO;
    self.textView.showsVerticalScrollIndicator = NO;
    self.textView.layer.cornerRadius = 3;
    self.textView.layer.masksToBounds = YES;
    [self.view addSubview:self.textView];
    
    self.otherButton = [[UIButton alloc] initWithFrame:self.textView.frame];
    [self.otherButton addTarget:self action:@selector(switchKeyboard) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.otherButton];
    
    // 4.表情
    self.emoButton = [[UIButton alloc] init];
    [self.emoButton addTarget:self action:@selector(emoButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.emoButton];
    
    // 5.扩展功能
    self.expandButton = [[UIButton alloc] init];
    [self.expandButton addTarget:self action:@selector(expandButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.expandButton];
}

/**
 *  点击语音按钮
 */
- (void)audioButtonClick:(UIButton *)sender
{
    if (self.panelStatus == HYChatInputPanelStatusAudio) {
        self.panelStatus = HYChatInputPanelStatusText;
    } else {
        self.panelStatus = HYChatInputPanelStatusAudio;
        
    }
}

/**
 *  点击表情按钮
 */
- (void)emoButtonClick:(UIButton *)sender
{
    if (self.panelStatus == HYChatInputPanelStatusEmoticon) {
        self.panelStatus = HYChatInputPanelStatusText;
    } else {
        self.panelStatus = HYChatInputPanelStatusEmoticon;
    }
}

/**
 *  点击扩展按钮
 */
- (void)expandButtonClick:(UIButton *)sender
{
    if (self.panelStatus == HYChatInputPanelStatusExpand) {
        self.panelStatus = HYChatInputPanelStatusText;
    } else {
        self.panelStatus = HYChatInputPanelStatusExpand;
    }
}

#pragma mark - 录音管理
- (void)initAudioRecord
{
    self.audioRecord = [[GJCFAudioRecord alloc] init];
    self.audioRecord.delegate = self;
    self.audioRecord.limitRecordDuration = 60.0f; // 最大录音时长
    self.audioRecord.minEffectDuration = 1.0f; // 最小录音时长
}

- (void)audioRecord:(GJCFAudioRecord *)audioRecord finishRecord:(GJCFAudioModel *)resultAudio
{
    HYLog(@"录音成功:%@",resultAudio.description);
    [HYRecordProgressHUD dismissWithTitle:@"正在发送..."];
    /**
     *  录音文件转码
     */
    [GJCFAudioFileUitil setupAudioFileTempEncodeFilePath:resultAudio];
    
    if ([GJCFEncodeAndDecode convertAudioFileToAMR:resultAudio]) {
        
        HYLog(@"录音文件转码成功:%@",resultAudio);
        if (self.delegate && [self.delegate respondsToSelector:@selector(inputViewController:sendAudioModel:)]) {
            [self.delegate inputViewController:self sendAudioModel:resultAudio];
        }
    }
}

- (void)audioRecord:(GJCFAudioRecord *)audioRecord didFaildByMinRecordDuration:(NSTimeInterval)minDuration
{
    HYLog(@"小于最小录音时间，录音失败:%f",minDuration);
    [HYRecordProgressHUD dismissWithTitle:@"说话时间太短！"];
}

- (void)audioRecord:(GJCFAudioRecord *)audioRecord didOccusError:(NSError *)error
{
    HYLog(@"录音失败:%@",error);
    [HYRecordProgressHUD dismissWithTitle:@"录音失败！"];
}

- (void)audioRecord:(GJCFAudioRecord *)audioRecord limitDurationProgress:(CGFloat)progress
{
    HYLog(@"最大录音限制进度:%f",progress);
}

- (void)audioRecord:(GJCFAudioRecord *)audioRecord soundMeter:(CGFloat)soundMeter
{
    HYLog(@"录音音量:%f",soundMeter);
}

- (void)audioRecordDidCancel:(GJCFAudioRecord *)audioRecord
{
    HYLog(@"录音取消");
}

#pragma mark - 录音
/**
 *  按下button
 */
- (void)touchDown:(UIButton *)sender
{
    [self.pressButton setTitle:@"按住 说话" forState:UIControlStateNormal];
    [self.audioRecord startRecord];
    [HYRecordProgressHUD showWithTitle:@"手指上滑，取消发送"];
}
/**
 *  在button内部
 */
- (void)dragInside:(UIButton *)sender
{
    [self.pressButton setTitle:@"按住 说话" forState:UIControlStateNormal];
    [HYRecordProgressHUD changeSubTitle:@"手指上滑，取消发送"];
}
/**
 *  发送录音
 */
- (void)touchUpInside:(UIButton *)sender
{
    [self.pressButton setTitle:@"按住 说话" forState:UIControlStateNormal];
    [self.audioRecord finishRecord];
}


- (void)dragOutside:(UIButton *)sender
{
    [self.pressButton setTitle:@"松开 结束" forState:UIControlStateNormal];
    [HYRecordProgressHUD changeSubTitle:@"松开手指，取消发送"];
}

/**
 *  取消发送
 */
- (void)touchOutside:(UIButton *)sender
{
    [self.pressButton setTitle:@"按住 说话" forState:UIControlStateNormal];
    [HYRecordProgressHUD dismissWithTitle:@"取消发送..."];
    [self.audioRecord cancelRecord];
    
}

#pragma mark - textViewDelegate

- (BOOL)textView:(YYTextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *body= textView.text;
    if([text isEqualToString:@"\n"]){
        //如果没有要发送的内容返回空
        if(body.length == 0) return NO;
        if ([self.delegate respondsToSelector:@selector(inputViewController:sendText:)]) {
            [self.delegate inputViewController:self sendText:body];
        }
        self.textView.text=nil;
        return NO;
    }
    return YES;
}

#pragma mark - HYEmoticonKeyboardViewDelegate
/**
 *  选中表情
 */
- (void)emoticonKeyboardDidTapText:(NSString *)text
{
    if (text.length) {
        [self.textView replaceRange:_textView.selectedTextRange withText:text];
    }
}

/**
 *  删除
 */
- (void)emoticonKeyboardDidTapBackspace
{
    [self.textView deleteBackward];
}

/**
 *  发送
 */
- (void)emoticonKeyboardDidTapSendButton
{
    // 发送
    [self textView:self.textView shouldChangeTextInRange:NSMakeRange(self.textView.text.length, 0) replacementText:@"\n"];
}

#pragma mark - HYExpandKeyboardViewDelegate
/**
 *  点击扩展
 */
- (void)expandKeyboardView:(HYExpandKeyboardView *)expandKeyboardView clickWithType:(HYExpandType)type
{
    if ([self.delegate respondsToSelector:@selector(inputViewController:clickExpandType:)]) {
        [self.delegate inputViewController:self clickExpandType:type];
    }
}

/**
 *  根据输入文字多少，自动调整输入框的高度
 */
- (void)textViewDidChange:(YYTextView *)textView
{
    //计算输入框最小高度
    CGSize size = textView.textLayout.textBoundingSize;
    CGFloat contentHeight = MIN(kTextViewMaXHeight, MAX(kTextViewMinHeight, size.height));
    if (self.textViewHeight != contentHeight) {//如果当前高度需要调整，就调整，避免多做无用功
        self.textViewHeight = contentHeight ;//重新设置自己的高度
        [self updateSubviewFrame];
    }
}

#pragma mark - 键盘状态改变
- (void)keyboardChangedWithTransition:(YYKeyboardTransition)transition
{
    if (self.onlyMoveKeyboard) {
        CGRect newFrame = self.view.frame;
        if (transition.fromVisible == YES && transition.toVisible == YES) { // 改变
            newFrame.origin.y = CGRectGetMaxY(self.view.superview.frame) - CGRectGetHeight(self.view.frame) - transition.toFrame.size.height;
        } else if (transition.fromVisible == YES && transition.toVisible == NO){ // 弹下
            if (self.textView.inputView && self.panelStatus == HYChatInputPanelStatusText) { // 表情->text
                return;
            } else {
                newFrame.origin.y = CGRectGetMaxY(self.view.superview.frame) - CGRectGetHeight(self.view.frame);
            }
        } else if (transition.fromVisible == NO && transition.toVisible == YES){ // 弹起
            newFrame.origin.y = CGRectGetMaxY(self.view.superview.frame) - CGRectGetHeight(self.view.frame) - transition.toFrame.size.height;
        }else if (transition.fromVisible == NO && transition.toVisible == NO){// 隐藏
            return;
        }
        [UIView animateWithDuration:transition.animationDuration delay:0 options:transition.animationOption animations:^{
            self.view.frame = newFrame;
        } completion:^(BOOL finished) {
        }];
        
    } else {
        CGRect newFrame = self.view.superview.frame;
        if (transition.fromVisible == YES && transition.toVisible == YES) { // 改变
            newFrame.origin.y = -transition.toFrame.size.height;
        } else if (transition.fromVisible == YES && transition.toVisible == NO){ // 弹下
            if (self.textView.inputView && self.panelStatus == HYChatInputPanelStatusText) { // 表情->text
                return;
            } else {
                newFrame.origin.y = 0;
            }
        } else if (transition.fromVisible == NO && transition.toVisible == YES){ // 弹起
            newFrame.origin.y = -transition.toFrame.size.height;
        }else if (transition.fromVisible == NO && transition.toVisible == NO){// 隐藏
            return;
        }
        [UIView animateWithDuration:transition.animationDuration delay:0 options:transition.animationOption animations:^{
            self.view.superview.frame = newFrame;
        } completion:^(BOOL finished) {
        }];
    }
    
}

#pragma mark - HYEmoticonKeyboardViewDeleagte
// 子控件布局
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self updateSubviewFrame];
}

// 调整frame
- (void)updateSubviewFrame
{
    CGFloat viewHeight = self.textViewHeight + kTextViewBottom * 2;
    self.view.frame = CGRectMake(self.view.frame.origin.x, CGRectGetMaxY(self.view.frame) - viewHeight, self.view.frame.size.width, self.textViewHeight + kTextViewBottom * 2);
    if ([self.delegate respondsToSelector:@selector(inputViewController:newHeight:)]) {
        [self.delegate inputViewController:self newHeight:CGRectGetHeight(self.view.frame)];
    } // delegate回掉
    
    self.line.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 1);
    CGFloat buttonHeight = kInputBarHeight - kNormalButtonBottom * 2;
    CGFloat buttonWidth = buttonHeight;
    CGFloat buttonY = CGRectGetHeight(self.view.frame) - kNormalButtonBottom - buttonHeight;
    self.audioButton.frame = CGRectMake(0, buttonY, buttonWidth, buttonHeight);
    self.expandButton.frame = CGRectMake(CGRectGetWidth(self.view.frame) - buttonWidth, buttonY, buttonWidth, buttonHeight);
    self.emoButton.frame = CGRectMake(CGRectGetMinX(self.expandButton.frame) - buttonWidth, buttonY, buttonWidth, buttonHeight);
    
    CGFloat textViewX = CGRectGetMaxX(self.audioButton.frame) + kTextViewMargin;
    CGFloat textViewY = kTextViewBottom;
    CGFloat textViewWidth = CGRectGetMinX(self.emoButton.frame) - kTextViewMargin - textViewX;
    CGFloat textViewHeight = self.textViewHeight;
    self.textView.frame = CGRectMake(textViewX, textViewY, textViewWidth, textViewHeight);
    self.pressButton.frame = CGRectMake(textViewX - 1, textViewY - 1, textViewWidth + 2, textViewHeight + 2);
    self.otherButton.frame = self.textView.frame;
}

#pragma mark - 覆盖父方法

- (BOOL)isFirstResponder
{
    return self.textView.isFirstResponder;
}

- (BOOL)resignFirstResponder
{
    self.panelStatus = HYChatInputPanelStatusNone;
    return YES;
}

- (BOOL)becomeFirstResponder
{
    self.panelStatus = HYChatInputPanelStatusText;
    return YES;
}

- (BOOL)canResignFirstResponder
{
    return [self.textView canResignFirstResponder];;
}

- (BOOL)canBecomeFirstResponder
{
    return [self.textView canBecomeFirstResponder];
}

- (void)switchKeyboard
{
    if (self.panelStatus != HYChatInputPanelStatusText) {
        self.panelStatus = HYChatInputPanelStatusText;
        self.otherButton.hidden = YES;
    }
}

#pragma mark - 懒加载
- (HYEmoticonKeyboardView *)emoticonView
{
    if (_emoticonView == nil) {
        _emoticonView = [[HYEmoticonKeyboardView alloc] init];
        _emoticonView.delegate = self;
        _emoticonView.frame = CGRectMake(0, 0, kScreenW, kPanelHeight);
    }
    return _emoticonView;
}

- (HYExpandKeyboardView *)expandView
{
    if (_expandView == nil) {
        _expandView = [[HYExpandKeyboardView alloc] init];
        _expandView.delegate = self;
        _expandView.frame = CGRectMake(0, 0, kScreenW, kPanelHeight);
    }
    return _expandView;
}

#pragma mark - 切换键盘状态

- (void)setPanelStatus:(HYChatInputPanelStatus)panelStatus
{
    _panelStatus = panelStatus;
    switch (panelStatus) {
        case HYChatInputPanelStatusNone:{
            [self.audioButton setImage:[UIImage imageNamed:@"chat_bottom_voice_nor"] forState:UIControlStateNormal];
            [self.audioButton setImage:[UIImage imageNamed:@"chat_bottom_voice_press"] forState:UIControlStateHighlighted];
            [self.emoButton setImage:[UIImage imageNamed:@"chat_bottom_smile_nor"] forState:UIControlStateNormal];
            [self.emoButton setImage:[UIImage imageNamed:@"chat_bottom_smile_press"] forState:UIControlStateHighlighted];
            [self.expandButton setImage:[UIImage imageNamed:@"chat_bottom_up_nor"] forState:UIControlStateNormal];
            [self.expandButton setImage:[UIImage imageNamed:@"chat_bottom_up_press"] forState:UIControlStateHighlighted];
            // 去掉键盘
            self.pressButton.enabled = NO;
            self.otherButton.hidden = YES;
            [self.textView resignFirstResponder];
            self.textView.inputView = nil;
            self.textView.hidden = NO;
            break;
        }
        case HYChatInputPanelStatusText:{
            [self.audioButton setImage:[UIImage imageNamed:@"chat_bottom_voice_nor"] forState:UIControlStateNormal];
            [self.audioButton setImage:[UIImage imageNamed:@"chat_bottom_voice_press"] forState:UIControlStateHighlighted];
            [self.emoButton setImage:[UIImage imageNamed:@"chat_bottom_smile_nor"] forState:UIControlStateNormal];
            [self.emoButton setImage:[UIImage imageNamed:@"chat_bottom_smile_press"] forState:UIControlStateHighlighted];
            [self.expandButton setImage:[UIImage imageNamed:@"chat_bottom_up_nor"] forState:UIControlStateNormal];
            [self.expandButton setImage:[UIImage imageNamed:@"chat_bottom_up_press"] forState:UIControlStateHighlighted];
            // 显示键盘
            self.pressButton.enabled = NO;
            self.otherButton.hidden = YES;
            self.textView.hidden = NO;
            if (self.textView.inputView) {
                [self.textView resignFirstResponder];
                self.textView.inputView = nil;
            }
            [self textViewDidChange:self.textView]; // 手动更新
            [self.textView becomeFirstResponder];
            break;
        }
            
        case HYChatInputPanelStatusAudio:{ // 语音
            [self.audioButton setImage:[UIImage imageNamed:@"chat_bottom_keyboard_nor"] forState:UIControlStateNormal];
            [self.audioButton setImage:[UIImage imageNamed:@"chat_bottom_keyboard_press"] forState:UIControlStateHighlighted];
            [self.emoButton setImage:[UIImage imageNamed:@"chat_bottom_smile_nor"] forState:UIControlStateNormal];
            [self.emoButton setImage:[UIImage imageNamed:@"chat_bottom_smile_press"] forState:UIControlStateHighlighted];
            [self.expandButton setImage:[UIImage imageNamed:@"chat_bottom_up_nor"] forState:UIControlStateNormal];
            [self.expandButton setImage:[UIImage imageNamed:@"chat_bottom_up_press"] forState:UIControlStateHighlighted];
            // 去掉键盘
            self.pressButton.enabled = YES;
            self.otherButton.hidden = YES;
            [self.textView resignFirstResponder];
            self.textView.inputView = nil;
            self.textView.hidden = YES; // 隐藏textView
            self.textViewHeight = kTextViewMinHeight;
            [self updateSubviewFrame]; // 更新子控件的位置
            break;
        }
        case HYChatInputPanelStatusEmoticon:{ // 表情
            [self.audioButton setImage:[UIImage imageNamed:@"chat_bottom_voice_nor"] forState:UIControlStateNormal];
            [self.audioButton setImage:[UIImage imageNamed:@"chat_bottom_voice_press"] forState:UIControlStateHighlighted];
            [self.emoButton setImage:[UIImage imageNamed:@"chat_bottom_keyboard_nor"] forState:UIControlStateNormal];
            [self.emoButton setImage:[UIImage imageNamed:@"chat_bottom_keyboard_press"] forState:UIControlStateHighlighted];
            [self.expandButton setImage:[UIImage imageNamed:@"chat_bottom_up_nor"] forState:UIControlStateNormal];
            [self.expandButton setImage:[UIImage imageNamed:@"chat_bottom_up_press"] forState:UIControlStateHighlighted];
            // 切换键盘
            self.pressButton.enabled = NO;
            self.otherButton.hidden = NO;
            self.textView.hidden = NO;
            [self.textView resignFirstResponder];
            self.textView.inputView = self.emoticonView;
            [self.textView becomeFirstResponder];
            break;
        }
        case HYChatInputPanelStatusExpand:{
            [self.audioButton setImage:[UIImage imageNamed:@"chat_bottom_voice_nor"] forState:UIControlStateNormal];
            [self.audioButton setImage:[UIImage imageNamed:@"chat_bottom_voice_press"] forState:UIControlStateHighlighted];
            [self.emoButton setImage:[UIImage imageNamed:@"chat_bottom_smile_nor"] forState:UIControlStateNormal];
            [self.emoButton setImage:[UIImage imageNamed:@"chat_bottom_smile_press"] forState:UIControlStateHighlighted];
            [self.expandButton setImage:[UIImage imageNamed:@"chat_bottom_up_nor"] forState:UIControlStateNormal];
            [self.expandButton setImage:[UIImage imageNamed:@"chat_bottom_up_press"] forState:UIControlStateHighlighted];
            // 切换键盘
            self.pressButton.enabled = NO;
            self.otherButton.hidden = NO;
            self.textView.hidden = NO;
            [self.textView resignFirstResponder];
            self.textView.inputView = self.expandView;
            [self.textView becomeFirstResponder];
            break;
        }
        default:
            break;
    }
}

- (void)dealloc
{
    [[YYKeyboardManager defaultManager] removeObserver:self];
    if (self.audioRecord.isRecording) {
        [self.audioRecord cancelRecord];
    }
    HYLog(@"%@-dealloc",self);
}

@end
