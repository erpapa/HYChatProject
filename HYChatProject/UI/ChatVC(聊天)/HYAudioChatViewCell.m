//
//  HYVoiceChatViewCell.m
//  HYChatProject
//
//  Created by erpapa on 16/4/28.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYAudioChatViewCell.h"
#import "HYAudioModel.h"

@interface HYAudioChatViewCell()
@property (nonatomic, strong) UIImageView *audioPlayIndicatorView;
@property (nonatomic, strong) UILabel *audioTimeLabel;
@property (nonatomic, strong) UIImageView *isAudioPlayTagView;
@end

@implementation HYAudioChatViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupContentView];
    }
    return self;
}

- (void)setupContentView
{
    // 播放音频动画
    self.audioPlayIndicatorView = [[UIImageView alloc] init];
    [self.audioPlayIndicatorView setAnimationDuration:1.0f];
    [self.contentBgView addSubview:self.audioPlayIndicatorView];
    
    // 音频时长
    self.audioTimeLabel = [[UILabel alloc] init];
    self.audioTimeLabel.textColor = [UIColor whiteColor];
    self.audioTimeLabel.font = [UIFont systemFontOfSize:14];
    self.audioTimeLabel.backgroundColor = [UIColor clearColor];
    [self.contentBgView addSubview:self.audioTimeLabel];
    
    // 标记未读
    UIImage *tagImage = [UIImage circleImageWithColor:[UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]  size:CGSizeMake(16, 16)];
    self.isAudioPlayTagView = [[UIImageView alloc] initWithImage:tagImage];
    self.isAudioPlayTagView.hidden = YES;
    [self.contentBgView addSubview:self.isAudioPlayTagView];
    
    //tap
    UITapGestureRecognizer *tapR = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapOnSelf)];
    tapR.numberOfTapsRequired = 1;
    [self.contentBgView addGestureRecognizer:tapR];
}

- (void)setMessageFrame:(HYChatMessageFrame *)messageFrame
{
    [super setMessageFrame:messageFrame];
    HYChatMessage *message = messageFrame.chatMessage;
    self.audioTimeLabel.text = [NSString stringWithFormat:@"%.1f''",message.audioModel.duration];
    self.audioPlayIndicatorView.animationRepeatCount = (int)(message.audioModel.duration + 0.85);
    
    CGFloat panding = 8;
    CGFloat audioPlayWidth = CGRectGetHeight(self.contentBgView.frame) - panding * 2;
    CGFloat timeLabelHeight = CGRectGetHeight(self.contentBgView.frame);
    if (message.isOutgoing) { // 发送
        self.audioPlayIndicatorView.image = [UIImage imageNamed:@"voice_send_icon_3"];
        self.audioPlayIndicatorView.frame = CGRectMake(CGRectGetWidth(self.contentBgView.frame) - audioPlayWidth - panding, panding, audioPlayWidth, audioPlayWidth);
        self.audioTimeLabel.frame = CGRectMake(CGRectGetMinX(self.audioPlayIndicatorView.frame) - 60 - panding, 0, 60, timeLabelHeight);
        self.isAudioPlayTagView.frame = CGRectMake(0, CGRectGetHeight(self.contentBgView.frame) - 8, 8, 8);
        self.audioTimeLabel.textAlignment = NSTextAlignmentRight;
    } else {
        self.audioPlayIndicatorView.image = [UIImage imageNamed:@"voice_receive_icon_3"];
        self.audioPlayIndicatorView.frame = CGRectMake(panding, panding, audioPlayWidth, audioPlayWidth);
        self.audioTimeLabel.frame = CGRectMake(CGRectGetMaxX(self.audioPlayIndicatorView.frame) + panding , 0, 60, timeLabelHeight);
        self.isAudioPlayTagView.frame = CGRectMake(CGRectGetWidth(self.contentBgView.frame) - 8, CGRectGetHeight(self.contentBgView.frame) - 8, 8, 8);
        self.audioTimeLabel.textAlignment = NSTextAlignmentLeft;
    }
    self.isAudioPlayTagView.hidden = message.isRead;
    if (message.isPlayingAudio) { // 是否正在播放
        [self playAudioAction];
    } else {
        [self finishPlayAudioAction];
    }
    
}

/**
 *  显示播放动画
 */
- (void)playAudioAction
{
    if (self.messageFrame.chatMessage.isOutgoing) {
        self.audioPlayIndicatorView.animationImages = @[[UIImage imageNamed:@"voice_send_icon_1"], [UIImage imageNamed:@"voice_send_icon_2"], [UIImage imageNamed:@"voice_send_icon_3"]];
        if (!self.audioPlayIndicatorView.isAnimating) {
            [self.audioPlayIndicatorView startAnimating];
        }
    } else {
        self.isAudioPlayTagView.hidden = YES; // 标记为已读
        self.audioPlayIndicatorView.animationImages = @[[UIImage imageNamed:@"voice_receive_icon_1"], [UIImage imageNamed:@"voice_receive_icon_2"], [UIImage imageNamed:@"voice_receive_icon_3"]];
        if (!self.audioPlayIndicatorView.isAnimating) {
            [self.audioPlayIndicatorView startAnimating];
        }
    }
}

/**
 *  停止播放动画
 */
- (void)finishPlayAudioAction
{
    if (self.audioPlayIndicatorView.isAnimating) {
        [self.audioPlayIndicatorView stopAnimating];
    }
    self.audioPlayIndicatorView.animationImages = nil;
    if (self.messageFrame.chatMessage.isOutgoing) {
        self.audioPlayIndicatorView.image = [UIImage imageNamed:@"voice_send_icon_3"];
    } else {
        self.audioPlayIndicatorView.image = [UIImage imageNamed:@"voice_receive_icon_3"];
    }
}

- (void)tapOnSelf
{
    // 在controller里边播放声音
    if ([self.delegate respondsToSelector:@selector(chatViewCellClickAudio:)]) {
        [self.delegate chatViewCellClickAudio:self];
    }
}

#pragma mark - 继承方法

- (void)showPopMenu:(UILongPressGestureRecognizer *)sender
{
    [super showPopMenu:sender];
    UIMenuController *popMenu = [UIMenuController sharedMenuController];
    if (popMenu.isMenuVisible) {
        return;
    }
    UIMenuItem *item1 = [[UIMenuItem alloc] initWithTitle:@"删除" action:@selector(deleteMessage:)];
    UIMenuItem *item2 = [[UIMenuItem alloc] initWithTitle:@"重发" action:@selector(reSendMessage:)];
    NSArray *menuItems = @[item1];
    if (self.messageFrame.chatMessage.sendStatus == HYChatSendMessageStatusFaild) {
        menuItems = @[item1,item2];
    }
    [popMenu setMenuItems:menuItems];
    [popMenu setArrowDirection:UIMenuControllerArrowDown];
    
    [popMenu setTargetRect:self.contentBgView.frame inView:self];
    [popMenu setMenuVisible:YES animated:YES];
}

- (void)deleteMessage:(UIMenuItem *)item
{
    if ([self.delegate respondsToSelector:@selector(chatViewCellDelete:)]) {
        [self.delegate chatViewCellDelete:self];
    }
}

- (void)reSendMessage:(UIMenuItem *)item
{
    if ([self.delegate respondsToSelector:@selector(chatViewCellReSend:)]) {
        [self.delegate chatViewCellReSend:self];
    }
}

@end
