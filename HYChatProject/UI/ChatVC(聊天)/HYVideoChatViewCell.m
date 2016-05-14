//
//  HYVideoChatViewCell.m
//  HYChatProject
//
//  Created by erpapa on 16/4/28.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYVideoChatViewCell.h"
#import "HYVideoDecoder.h"
#import "YYWebImage.h"

@interface HYVideoChatViewCell()
@property (nonatomic, strong) UIImageView *videoView;

@end

@implementation HYVideoChatViewCell

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
    // 视频
    self.videoView = [[UIImageView alloc] init];
    self.videoView.layer.cornerRadius = 4;
    self.videoView.layer.masksToBounds = YES;
    self.videoView.contentMode = UIViewContentModeScaleAspectFill;
    self.videoView.backgroundColor = [UIColor colorWithRed:211/255.0 green:211/255.0 blue:211/255.0 alpha:1.0f];
    [self.contentBgView addSubview:self.videoView];
    
    //tap
    UITapGestureRecognizer *tapR = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapOnSelf)];
    tapR.numberOfTapsRequired = 1;
    [self.contentBgView addGestureRecognizer:tapR];
}

- (void)setMessageFrame:(HYChatMessageFrame *)messageFrame
{
    [super setMessageFrame:messageFrame];
    HYChatMessage *message = messageFrame.chatMessage;
    self.videoView.frame = self.contentBgView.bounds;
    UIImage *normalImage = nil;
    if (message.isOutgoing) {
        normalImage =[[UIImage imageNamed:@"chat_send_nor"] resizableImageWithCapInsets:UIEdgeInsetsMake(25, 40, 30, 70) resizingMode:UIImageResizingModeStretch];
    } else {
        normalImage = [[UIImage imageNamed:@"chat_receive_nor"] resizableImageWithCapInsets:UIEdgeInsetsMake(25, 40, 30, 70) resizingMode:UIImageResizingModeStretch];
    }
    [self makeMaskView:self.videoView withImage:normalImage]; // 设置mask，遮盖
    [self.videoView yy_setImageWithURL:[NSURL URLWithString:message.videoModel.videoThumbImageUrl] options:YYWebImageOptionProgressive];
    
    if (message.videoModel.videoLocalPath) { // 本地文件存在
        [self decodeVideo]; // 解码
    }
}

- (void)makeMaskView:(UIView *)view withImage:(UIImage *)image
{
    UIImageView *imageViewMask = [[UIImageView alloc] initWithImage:image];
    imageViewMask.frame = CGRectInset(view.frame, 0.0f, 0.0f);
    view.layer.mask = imageViewMask.layer;
}

- (void)tapOnSelf
{
    if ([self.delegate respondsToSelector:@selector(chatViewCellClickVideo:)]) {
        [self.delegate chatViewCellClickVideo:self];
    }
}

- (void)decodeVideo
{
    if (self.messageFrame.chatMessage.videoModel.videoDecoder == nil) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.messageFrame.chatMessage.videoModel.videoDecoder = [[HYVideoDecoder alloc] initWithFile:self.messageFrame.chatMessage.videoModel.videoLocalPath];
            __weak typeof(self) weakSelf = self;
            [weakSelf.messageFrame.chatMessage.videoModel.videoDecoder decode:^(BOOL finished) {
                if (finished) {
                    [weakSelf videoDecodeFinished:weakSelf.messageFrame.chatMessage.videoModel.videoDecoder];
                }
            }];
        });
    } else {
        [self videoDecodeFinished:self.messageFrame.chatMessage.videoModel.videoDecoder];
    }
}

- (void)videoDecodeFinished:(HYVideoDecoder *)videoDecoder
{
    //解码完成 刷新界面
    if (videoDecoder.animation != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.videoView.layer removeAnimationForKey:@"contents"];
            [self.videoView.layer addAnimation:videoDecoder.animation forKey:nil];
        });
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
    UIMenuItem *item2;
    if (self.messageFrame.chatMessage.sendStatus == HYChatSendMessageStatusFaild) {
        item2 = [[UIMenuItem alloc] initWithTitle:@"重发" action:@selector(reSendMessage:)];
    } else {
        item2 = [[UIMenuItem alloc] initWithTitle:@"转发" action:@selector(forwardMessage:)];
    }
    [popMenu setMenuItems:@[item1,item2]];
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

- (void)forwardMessage:(UIMenuItem *)item
{
    if ([self.delegate respondsToSelector:@selector(chatViewCellForward:)]) {
        [self.delegate chatViewCellForward:self];
    }
}


- (void)reSendMessage:(UIMenuItem *)item
{
    if ([self.delegate respondsToSelector:@selector(chatViewCellReSend:)]) {
        [self.delegate chatViewCellReSend:self];
    }
}
@end
