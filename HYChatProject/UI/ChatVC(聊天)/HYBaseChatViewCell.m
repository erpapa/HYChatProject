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
#import "HYLoginInfo.h"

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
    [self.contentView addSubview:self.timeLabel];
    
    self.contentImageView = [[UIImageView alloc] init];
    [self.contentView addSubview:self.contentImageView];
    
    self.headView = [[UIImageView alloc] init];
    self.headView.image = [UIImage imageNamed:@"defaultHead"];
    self.headView.layer.cornerRadius = kHeadWidth * 0.5;
    self.headView.layer.masksToBounds = YES;
    [self.headView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(headViewClick:)]];
    
    
}

- (void)setMessageFrame:(HYChatMessageFrame *)messageFrame
{
    _messageFrame = messageFrame;
    HYChatMessage *message = messageFrame.chatMessage;
    self.timeLabel.text = message.timeString;
    XMPPJID *jid = nil;
    if (message.isOutgoing) {
        jid = [HYLoginInfo sharedInstance].jid;
        self.contentImageView.image = [UIImage resizedImageWithName:@"chat_send_nor"];
        self.contentImageView.highlightedImage = [UIImage resizedImageWithName:@"chat_send_press"];
    } else {
        jid = message.jid;
        self.contentImageView.image = [UIImage resizedImageWithName:@"chat_recive_nor"];
        self.contentImageView.highlightedImage = [UIImage resizedImageWithName:@"chat_recive_press"];
    }
    __weak typeof(self) weakSelf = self; // 获取头像
    [[HYXMPPManager sharedInstance] getvCardFromJID:jid vCardBlock:^(XMPPvCardTemp *vCardTemp) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (vCardTemp.photo) {
            UIImage *image = [UIImage imageWithData:vCardTemp.photo];
            strongSelf.headView.image = image;
        }
    }];
    
    
    // frame
    self.timeLabel.hidden = message.isHidenTime;
    self.timeLabel.frame = messageFrame.timeLabelFrame;
    self.headView.frame = messageFrame.headViewFrame;
    self.contentImageView.frame = messageFrame.contentImageViewFrame;
}

// 单击
- (void)headViewClick:(UITapGestureRecognizer *)sender
{
    
}

// 长按
- (void)showLongPressMenu:(UILongPressGestureRecognizer *)sender{
    self.contentImageView.highlighted = YES;
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

@end
