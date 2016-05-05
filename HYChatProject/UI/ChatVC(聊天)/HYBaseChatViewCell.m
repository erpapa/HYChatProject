//
//  HYChatViewCell.m
//  HYChatProject
//
//  Created by erpapa on 16/4/28.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYBaseChatViewCell.h"
#import "HYChatMessageFrame.h"
#import "HYXMPPManager.h"
#import "XMPPvCardTemp.h"

@implementation HYBaseChatViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectedBackgroundView = [UIView new];
        [self initSubviews];
    }
    return self;
}

- (void)initSubviews
{
    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    self.timeLabel.font = [UIFont systemFontOfSize:kTimeFontZise];
    self.timeLabel.textColor = kTimeLabelColor;
    [self.contentView addSubview:self.timeLabel];
    
    self.contentBgView = [[UIButton alloc] init];
    self.contentBgView.adjustsImageWhenHighlighted = NO;
    [self.contentBgView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showPopMenu:)]];
    [self.contentView addSubview:self.contentBgView];
    
    self.headView = [[UIImageView alloc] init];
    self.headView.image = [UIImage imageNamed:@"defaultHead"];
    self.headView.layer.cornerRadius = kHeadWidth * 0.5;
    self.headView.layer.masksToBounds = YES;
    self.headView.userInteractionEnabled = YES;
    [self.headView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(headViewClick:)]];
    [self.contentView addSubview:self.headView];
    
    // 通知
    [HYNotification addObserver:self selector:@selector(popMenuWillHide:) name:UIMenuControllerWillHideMenuNotification object:nil];
    
    
}

- (void)setMessageFrame:(HYChatMessageFrame *)messageFrame
{
    _messageFrame = messageFrame;
    HYChatMessage *message = messageFrame.chatMessage;
    self.timeLabel.text = message.timeString;
    XMPPJID *jid = nil;
    // UIEdgeInsetsMake(CGFloat top, CGFloat left, CGFloat bottom, CGFloat right) // 拉伸图片，参数是像素，同时要考虑@1x、@2x、@3x这几种情况
    if (message.isOutgoing) {
        UIImage *normalImage = [[UIImage imageNamed:@"chat_send_nor"] resizableImageWithCapInsets:UIEdgeInsetsMake(25, 40, 30, 70) resizingMode:UIImageResizingModeStretch];
        UIImage *selectedImage = [[UIImage imageNamed:@"chat_send_press"] resizableImageWithCapInsets:UIEdgeInsetsMake(25, 40, 30, 70) resizingMode:UIImageResizingModeStretch];
        [self.contentBgView setBackgroundImage:normalImage forState:UIControlStateNormal];
        [self.contentBgView setBackgroundImage:selectedImage forState:UIControlStateSelected];
    } else {
        UIImage *normalImage = [[UIImage imageNamed:@"chat_receive_nor"] resizableImageWithCapInsets:UIEdgeInsetsMake(25, 40, 30, 70) resizingMode:UIImageResizingModeStretch];
        UIImage *selectedImage = [[UIImage imageNamed:@"chat_receive_press"] resizableImageWithCapInsets:UIEdgeInsetsMake(25, 40, 30, 70) resizingMode:UIImageResizingModeStretch];
        [self.contentBgView setBackgroundImage:normalImage forState:UIControlStateNormal];
        [self.contentBgView setBackgroundImage:selectedImage forState:UIControlStateSelected];
    }
    __weak typeof(self) weakSelf = self; // 获取头像
    [[HYXMPPManager sharedInstance] getvCardFromJID:message.jid vCardBlock:^(XMPPvCardTemp *vCardTemp) {
        if (vCardTemp.photo) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.headView.image = [UIImage imageWithData:vCardTemp.photo];
        }
    }];
    
    // frame
    self.timeLabel.hidden = message.isHidenTime;
    self.timeLabel.frame = messageFrame.timeLabelFrame;
    self.headView.frame = messageFrame.headViewFrame;
    self.contentBgView.frame = messageFrame.contentBgViewFrame;
}

// 单击
- (void)headViewClick:(UITapGestureRecognizer *)sender
{
    if ([self.delegate respondsToSelector:@selector(chatViewCell:didClickHeaderWithJid:)]) {
        [self.delegate chatViewCell:self didClickHeaderWithJid:self.messageFrame.chatMessage.jid];
    }
}

// 长按
- (void)showPopMenu:(UILongPressGestureRecognizer *)sender{
    [self becomeFirstResponder];
    self.contentBgView.selected = YES;
}
// 复制消息
- (void)copyMesssage:(UIMenuItem *)item{
    
}
// 转发消息
- (void)forwardMessage:(UIMenuItem *)item
{
    
}
// 删除消息
- (void)deleteMessage:(UIMenuItem *)item
{
    
}
// 发送失败(重新发送)
- (void)reSendMessage:(UIMenuItem *)item
{
    
}
#pragma mark - 显示popMenu需要实现以下两个方法
- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(copyMesssage:) || action == @selector(deleteMessage:) || action == @selector(reSendMessage:) || action == @selector(forwardMessage:)) {
        return YES;
    }
    return [super canPerformAction:action withSender:sender];
}

/**
 *  接收通知
 */
- (void)popMenuWillHide:(NSNotification *)noti
{
    if (self.contentBgView.selected == YES) {
        self.contentBgView.selected = NO;
    }
}

@end
